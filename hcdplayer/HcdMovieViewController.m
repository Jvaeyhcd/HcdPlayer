//
//  HcdMovieViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2019/1/15.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "HcdMovieViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>
#import "NSString+Hcd.h"
#import "HcdMovieDecoder.h"
#import "HcdAudioManager.h"
#import "HcdMovieGLView.h"
#import "HcdLogger.h"
#import "AppDelegate.h"
#import "HcdPlayerDraggingProgressView.h"

#define kLeastMoveDistance 15.0

NSString * const HcdMovieParameterMinBufferedDuration = @"HcdMovieParameterMinBufferedDuration";
NSString * const HcdMovieParameterMaxBufferedDuration = @"HcdMovieParameterMaxBufferedDuration";
NSString * const HcdMovieParameterDisableDeinterlacing = @"HcdMovieParameterDisableDeinterlacing";

////////////////////////////////////////////////////////////////////////////////

static NSString * formatTimeInterval(CGFloat seconds, BOOL isLeft)
{
    seconds = MAX(0, seconds);
    
    NSInteger s = seconds;
    NSInteger m = s / 60;
    NSInteger h = m / 60;
    
    s = s % 60;
    m = m % 60;
    
    NSMutableString *format = [(isLeft && seconds >= 0.5 ? @"-" : @"") mutableCopy];
    if (h != 0) {
        [format appendFormat:@"%ld:%0.2ld", (long)h, (long)m];
    } else {
        [format appendFormat:@"%ld", (long)m];
    }
    [format appendFormat:@":%0.2ld", (long)s];
    
    return format;
}

////////////////////////////////////////////////////////////////////////////////

enum {
    
    HcdMovieInfoSectionGeneral,
    HcdMovieInfoSectionVideo,
    HcdMovieInfoSectionAudio,
    HcdMovieInfoSectionSubtitles,
    HcdMovieInfoSectionMetadata,
    HcdMovieInfoSectionCount,
};

enum {
    
    HcdMovieInfoGeneralFormat,
    HcdMovieInfoGeneralBitrate,
    HcdMovieInfoGeneralCount,
};

typedef enum : NSUInteger {
    HCDPlayerControlTypeNone,
    HCDPlayerControlTypeProgress,
    HCDPlayerControlTypeVoice,
    HCDPlayerControlTypeLight,
} HCDPlayerControlType;

////////////////////////////////////////////////////////////////////////////////

static NSMutableDictionary * gHistory;

#define LOCAL_MIN_BUFFERED_DURATION   0.2
#define LOCAL_MAX_BUFFERED_DURATION   0.4
#define NETWORK_MIN_BUFFERED_DURATION 2.0
#define NETWORK_MAX_BUFFERED_DURATION 4.0

@interface HcdMovieViewController () {
    
    HcdMovieDecoder      *_decoder;
    dispatch_queue_t    _dispatchQueue;
    NSMutableArray      *_videoFrames;
    NSMutableArray      *_audioFrames;
    NSMutableArray      *_subtitles;
    NSData              *_currentAudioFrame;
    NSUInteger          _currentAudioFramePos;
    CGFloat             _moviePosition;
    BOOL                _disableUpdateHUD;
    NSTimeInterval      _tickCorrectionTime;
    NSTimeInterval      _tickCorrectionPosition;
    NSUInteger          _tickCounter;
    BOOL                _fullscreen;
    BOOL                _fitMode;
    BOOL                _infoMode;
    BOOL                _restoreIdleTimer;
    BOOL                _interrupted;
    
    HcdMovieGLView      *_glView;
    UIImageView         *_imageView;
    
    UIBarButtonItem     *_playBtn;
    UIBarButtonItem     *_pauseBtn;
    UIBarButtonItem     *_rewindBtn;
    UIBarButtonItem     *_fforwardBtn;
    UIBarButtonItem     *_spaceItem;
    UIBarButtonItem     *_fixedSpaceItem;
    
    UITapGestureRecognizer *_tapGestureRecognizer;
    UITapGestureRecognizer *_doubleTapGestureRecognizer;
    UIPanGestureRecognizer *_panGestureRecognizer;
    
#ifdef DEBUG
    UILabel             *_messageLabel;
    NSTimeInterval      _debugStartTime;
    NSUInteger          _debugAudioStatus;
    NSDate              *_debugAudioStatusTS;
#endif
    
    CGFloat             _bufferedDuration;
    CGFloat             _minBufferedDuration;
    CGFloat             _maxBufferedDuration;
    BOOL                _buffered;
    
    BOOL                _savedIdleTimer;
    
    NSDictionary        *_parameters;
    
    CGFloat             _tabbarSafeBottomMargin;
    CGFloat             _statusBarHeight;
    
    //用来判断手势是否移动过
    BOOL _hasMoved;
    //判断是否已经判断出手势划的方向
    BOOL _controlJudge;
    //触摸开始触碰到的点
    CGPoint _touchBeginPoint;
    //记录触摸开始时的视频播放的时间
    float _touchBeginValue;
    //记录触摸开始亮度
    float _touchBeginLightValue;
    //记录触摸开始的音量
    float _touchBeginVoiceValue;
}

@property (readwrite) BOOL playing;
@property (readwrite) BOOL decoding;

@property (readwrite, assign) BOOL                  hiddenHUD;
@property (readwrite, strong) HcdArtworkFrame       *artworkFrame;
@property (nonatomic, strong) UIView                *topHUD;
@property (nonatomic, strong) UIToolbar             *topBar;
@property (nonatomic, strong) UIView                *bottomView;
@property (nonatomic, strong) UITableView           *tableView;
@property (nonatomic, strong) UISlider              *progressSlider;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

@property (nonatomic, strong) UIButton            *doneButton;
@property (nonatomic, strong) UILabel             *progressLabel;
@property (nonatomic, strong) UILabel             *leftLabel;
@property (nonatomic, strong) UIButton            *infoButton;
@property (nonatomic, strong) UILabel             *subtitlesLabel;
@property (nonatomic, strong) UIButton            *playButton;
@property (nonatomic, strong) UIButton            *pauseButton;
@property (nonatomic, strong) UIButton            *fullButton;
@property (nonatomic, strong) UIButton            *exitFullButton;
@property (nonatomic, strong) UIButton            *airPlayButton;
@property (nonatomic, strong) UIButton            *lockButton;
@property (nonatomic, strong) UIButton            *unlockButton;
@property (nonatomic, strong) UIButton            *replayButton;

@property (nonatomic, assign) HCDPlayerControlType controlType;       //当前手势是在控制进度、声音还是亮度
@property (nonatomic, strong) HcdPlayerDraggingProgressView *draggingProgressView;

@property (readwrite, assign) UIInterfaceOrientation currentOrientation;
@property (nonatomic, assign) BOOL           isFullScreen;
@property (nonatomic, assign) BOOL           canFullScreen;

@end

@implementation HcdMovieViewController

+ (void)initialize {
    if (!gHistory) {
        gHistory = [NSMutableDictionary dictionary];
    }
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

// 播放器控制器的初始化方法
+ (id) movieViewControllerWithContentPath: (NSString *) path
                               parameters: (NSDictionary *) parameters {
    // 音频管理类的初始化 单例
    id<HcdAudioManager> audioManager = [HcdAudioManager audioManager];
    [audioManager activateAudioSession];
    return [[HcdMovieViewController alloc] initWithContentPath: path parameters: parameters];
}

- (id) initWithContentPath: (NSString *) path
                parameters: (NSDictionary *) parameters {
    NSAssert(path.length > 0, @"empty path");
    
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [self initData];
        _moviePosition = 0;
        //        self.wantsFullScreenLayout = YES;
        
        _parameters = parameters;
        
        __weak HcdMovieViewController *weakSelf = self;
        
        // 解码器
        HcdMovieDecoder *decoder = [[HcdMovieDecoder alloc] init];
        
        decoder.interruptCallback = ^BOOL(){
            
            __strong HcdMovieViewController *strongSelf = weakSelf;
            return strongSelf ? [strongSelf interruptDecoder] : YES;
        };
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            // 打开文件
            NSError *error = nil;
            [decoder openFile:path error:&error];
            
            __strong HcdMovieViewController *strongSelf = weakSelf;
            if (strongSelf) {
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    
                    [strongSelf setMovieDecoder:decoder withError:error];
                });
            }
        });
    }
    return self;
}

- (void) dealloc {
    [self pause];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_dispatchQueue) {
        // Not needed as of ARC.
        //        dispatch_release(_dispatchQueue);
        _dispatchQueue = NULL;
    }
    LoggerStream(1, @"%@ dealloc", self);
}

- (void)loadView
{
    // LoggerStream(1, @"loadView");
    CGRect bounds = [[UIScreen mainScreen] bounds];
    
    self.view = [[UIView alloc] initWithFrame:bounds];
    self.view.backgroundColor = [UIColor blackColor];
    self.view.tintColor = [UIColor blackColor];
    
    [self.view addSubview:self.activityIndicatorView];
    
    CGFloat width = bounds.size.width;
    CGFloat height = bounds.size.height;
    
#ifdef DEBUG
    _messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(20,40,width-40,40)];
    _messageLabel.backgroundColor = [UIColor clearColor];
    _messageLabel.textColor = [UIColor redColor];
    _messageLabel.hidden = YES;
    _messageLabel.font = [UIFont systemFontOfSize:14];
    _messageLabel.numberOfLines = 2;
    _messageLabel.textAlignment = NSTextAlignmentCenter;
    _messageLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_messageLabel];
#endif
    
    CGFloat topH = 50;
    CGFloat botH = 50;
    
    self.bottomView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    
    [self.view addSubview:self.topHUD];
    [self.view addSubview:self.bottomView];
    
    // top hud
    //    [_doneButton setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
    
    [self.topHUD addSubview:self.doneButton];
    [self.topHUD addSubview:self.airPlayButton];
    
//    [self.bottomView addSubview:self.doneButton];
    [self.bottomView addSubview:self.playButton];
    [self.bottomView addSubview:self.progressLabel];
    [self.bottomView addSubview:self.progressSlider];
    [self.bottomView addSubview:self.leftLabel];
//    [self.bottomView addSubview:self.infoButton];
    [self.bottomView addSubview:self.fullButton];
    
    [self.view addSubview:self.draggingProgressView];
    [self.draggingProgressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        CGFloat width = 150;
        CGFloat height = width * 8 / 15;
        make.size.mas_offset(CGSizeMake(ceil(width), ceil(height)));
    }];
    
    // bottom hud
    
    _spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                               target:nil
                                                               action:nil];
    
    _fixedSpaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                    target:nil
                                                                    action:nil];
    _fixedSpaceItem.width = 30;
    
    _rewindBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
                                                               target:self
                                                               action:@selector(rewindDidTouch:)];
    
    _playBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                                             target:self
                                                             action:@selector(playDidTouch:)];
    _playBtn.width = 50;
    
    _pauseBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause
                                                              target:self
                                                              action:@selector(playDidTouch:)];
    _pauseBtn.width = 50;
    
    _fforwardBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward
                                                                 target:self
                                                                 action:@selector(forwardDidTouch:)];
    
    [self updateBottomToolView];
    
    if (_decoder) {
        
        [self setupPresentView];
        
    } else {
        
        self.progressLabel.hidden = YES;
        self.progressSlider.hidden = YES;
        self.leftLabel.hidden = YES;
        self.infoButton.hidden = YES;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    if (self.playing) {

        [self pause];
        [self freeBufferedFrames];
        
        if (_maxBufferedDuration > 0) {
            _minBufferedDuration = _maxBufferedDuration = 0;
            [self play];
            LoggerStream(0, @"didReceiveMemoryWarning, disable buffering and continue playing");
        } else {
            // force ffmpeg to free allocated memory
            [_decoder closeFile];
        }
    } else {
        [self freeBufferedFrames];
        [_decoder closeFile];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    ((AppDelegate *)[[UIApplication sharedApplication] delegate]).isAllowAutorotate = YES;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (_infoMode) {
        [self showInfoView:NO animated:NO];
    }
    
    _savedIdleTimer = [[UIApplication sharedApplication] isIdleTimerDisabled];
    
    [self showHUD: YES];
    
    if (_decoder) {
        [self restorePlay];
    } else {
        [_activityIndicatorView startAnimating];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:[UIApplication sharedApplication]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStatusBarOrientationChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void) viewWillDisappear:(BOOL)animated {
    ((AppDelegate *)[[UIApplication sharedApplication] delegate]).isAllowAutorotate = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
    
    [_activityIndicatorView stopAnimating];
    
    if (_decoder) {
        
        [self pause];
        
        if (_moviePosition == 0 || _decoder.isEOF)
            [gHistory removeObjectForKey:_decoder.path];
        else if (!_decoder.isNetwork)
            [gHistory setValue:[NSNumber numberWithFloat:_moviePosition]
                        forKey:_decoder.path];
    }
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:_savedIdleTimer];
    
    [_activityIndicatorView stopAnimating];
    _buffered = NO;
    _interrupted = YES;
    
    LoggerStream(1, @"viewWillDisappear %@", self);
}

- (void) applicationWillResignActive: (NSNotification *)notification {
    [self showHUD:YES];
    [self pause];
    
    LoggerStream(1, @"applicationWillResignActive");
}

#pragma mark - getter

- (UILabel *)progressLabel {
    if (!_progressLabel) {
        _progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 0, 46, 50)];
        _progressLabel.backgroundColor = [UIColor clearColor];
        _progressLabel.textColor = [UIColor whiteColor];
        _progressLabel.opaque = NO;
        _progressLabel.adjustsFontSizeToFitWidth = NO;
        _progressLabel.textAlignment = NSTextAlignmentRight;
        _progressLabel.text = @"00:00";
        _progressLabel.font = [UIFont systemFontOfSize:12];
    }
    return _progressLabel;
}

- (UILabel *)leftLabel {
    if (!_leftLabel) {
        _leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(kScreenWidth - 100 + 4, 0, 50, 50)];
        _leftLabel.backgroundColor = [UIColor clearColor];
        _leftLabel.textColor = [UIColor whiteColor];
        _leftLabel.opaque = NO;
        _leftLabel.adjustsFontSizeToFitWidth = NO;
        _leftLabel.textAlignment = NSTextAlignmentLeft;
        _leftLabel.text = @"00:00";
        _leftLabel.font = [UIFont systemFontOfSize:12];
        _leftLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    }
    return _leftLabel;
}

- (UIButton *)doneButton {
    if (!_doneButton) {
        _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _doneButton.frame = CGRectMake(0, _statusBarHeight, 50, 50);
        [_doneButton setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_close"] forState:UIControlStateNormal];
        _doneButton.backgroundColor = [UIColor clearColor];
        [_doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_doneButton addTarget:self action:@selector(doneDidTouch:)
              forControlEvents:UIControlEventTouchUpInside];
    }
    return _doneButton;
}

- (UIButton *)infoButton {
    if (!_infoButton) {
        _infoButton = [[UIButton alloc]init];
        [_infoButton setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_info_outline"] forState:UIControlStateNormal];
        _infoButton.frame = CGRectMake(kScreenWidth-50, _statusBarHeight, 50, 50);
        _infoButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [_infoButton addTarget:self action:@selector(infoDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _infoButton;
}

- (UIButton *)airPlayButton {
    if (!_airPlayButton) {
        _airPlayButton = [[UIButton alloc]init];
        [_airPlayButton setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_air_play"] forState:UIControlStateNormal];
        _airPlayButton.frame = CGRectMake(kScreenWidth-50, _statusBarHeight, 50, 50);
        _airPlayButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [_airPlayButton addTarget:self action:@selector(infoDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _airPlayButton;
}

- (UIButton *)playButton {
    if (!_playButton) {
        _playButton = [[UIButton alloc] init];
        _playButton.frame = CGRectMake(0, 0, 50, 50);
        [_playButton setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_play"] forState:UIControlStateNormal];
        [_playButton setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_play_hl"] forState:UIControlStateHighlighted];
        [_playButton addTarget:self action:@selector(playDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playButton;
}

- (UIButton *)pauseButton {
    if (!_pauseButton) {
        _pauseButton = [[UIButton alloc] init];
        _pauseButton.frame = CGRectMake(0, 0, 50, 50);
        [_pauseButton setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_pause"] forState:UIControlStateNormal];
        [_pauseButton setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_pause"] forState:UIControlStateHighlighted];
        [_pauseButton addTarget:self action:@selector(playDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _pauseButton;
}

- (UIButton *)fullButton {
    if (!_fullButton) {
        _fullButton = [[UIButton alloc] init];
        _fullButton.frame = CGRectMake(kScreenWidth - 50, 0, 50, 50);
        _fullButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [_fullButton setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_fullscreen"] forState:UIControlStateNormal];
        [_fullButton addTarget:self action:@selector(fullDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _fullButton;
}

- (UIButton *)exitFullButton {
    if (!_exitFullButton) {
        _exitFullButton = [[UIButton alloc] init];
        _exitFullButton.frame = CGRectMake(kScreenWidth - 50, 0, 50, 50);
        _exitFullButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [_exitFullButton setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_fullscreen_exit"] forState:UIControlStateNormal];
        [_exitFullButton addTarget:self action:@selector(exitFullDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _exitFullButton;
}

- (UIButton *)lockButton {
    if (!_lockButton) {
        _lockButton = [[UIButton alloc] init];
        _lockButton.frame = CGRectMake(kScreenWidth - 50, 0, 50, 50);
        _lockButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [_lockButton setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_lock"] forState:UIControlStateNormal];
        [_lockButton addTarget:self action:@selector(exitFullDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _lockButton;
}

- (UIButton *)unlockButton {
    if (!_unlockButton) {
        _unlockButton = [[UIButton alloc] init];
        _unlockButton.frame = CGRectMake(kScreenWidth - 50, 0, 50, 50);
        _unlockButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [_unlockButton setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_unlock"] forState:UIControlStateNormal];
        [_unlockButton addTarget:self action:@selector(exitFullDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _unlockButton;
}

- (UIButton *)replayButton {
    if (!_replayButton) {
        _replayButton = [[UIButton alloc] init];
        _replayButton.frame = CGRectMake((kScreenWidth - 60) / 2, (kScreenHeight - 60) / 2, 60, 60);
        [_replayButton setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_video_player_replay"] forState:UIControlStateNormal];
        [_replayButton setTitle:HcdLocalized(@"replay", nil) forState:UIControlStateNormal];
        _replayButton.titleLabel.font = [UIFont systemFontOfSize:14];
        
        CGSize imageSize = _replayButton.imageView.frame.size;
        CGSize titleSize = _replayButton.titleLabel.frame.size;
        
        _replayButton.titleEdgeInsets = UIEdgeInsetsMake(0, -imageSize.width, -imageSize.height - 5, 0);
        _replayButton.imageEdgeInsets = UIEdgeInsetsMake(-titleSize.height - 5, 0, 0, -titleSize.width);
        
        [_replayButton addTarget:self action:@selector(replayDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _replayButton;
}

- (UIView *)topHUD {
    if (!_topHUD) {
        _topHUD    = [[UIView alloc] initWithFrame:CGRectMake(0,0,0,0)];
        _topHUD.frame = CGRectMake(0, 0, kScreenWidth, _statusBarHeight + 50);
        _topHUD.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        _topHUD.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    return _topHUD;
}

- (UISlider *)progressSlider {
    if (!_progressSlider) {
        _progressSlider = [[UISlider alloc] init];
        _progressSlider.frame = CGRectMake(100, 0, kScreenWidth - 200, 50);
        _progressSlider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _progressSlider.minimumTrackTintColor = kMainColor;
        _progressSlider.maximumTrackTintColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
        _progressSlider.continuous = NO;
        _progressSlider.value = 0;
        [_progressSlider setThumbImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_progress"]
                              forState:UIControlStateNormal];
    }
    return _progressSlider;
}

- (UIView *)bottomView {
    if (!_bottomView) {
        CGFloat height = _tabbarSafeBottomMargin + 50;
        _bottomView = [[UIView alloc] init];
        _bottomView.frame = CGRectMake(0, kScreenHeight - height, kScreenWidth, height);
        _bottomView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    }
    return _bottomView;
}

- (UIActivityIndicatorView *)activityIndicatorView {
    if (!_activityIndicatorView) {
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
        _activityIndicatorView.center = self.view.center;
        _activityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    }
    return _activityIndicatorView;
}

@synthesize draggingProgressView = _draggingProgressView;
- (HcdPlayerDraggingProgressView *)draggingProgressView {
    if (!_draggingProgressView) {
        _draggingProgressView = [HcdPlayerDraggingProgressView new];
        _draggingProgressView.hidden = YES;
        _draggingProgressView.layer.cornerRadius = 8;
    }
    return _draggingProgressView;
}

#pragma mark - gesture recognizer

- (void) handleTap: (UITapGestureRecognizer *) sender
{
    if (sender.state == UIGestureRecognizerStateEnded) {
        
        if (sender == _tapGestureRecognizer) {
            
            [self showHUD: _hiddenHUD];
            
        } else if (sender == _doubleTapGestureRecognizer) {
            
            UIView *frameView = [self frameView];
            
            if (frameView.contentMode == UIViewContentModeScaleAspectFit)
                frameView.contentMode = UIViewContentModeScaleAspectFill;
            else
                frameView.contentMode = UIViewContentModeScaleAspectFit;
            
        }
    }
}

- (void)handlePan: (UIPanGestureRecognizer *)recognizer {
    CGPoint touchPoint = [recognizer locationInView:self.view];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        _hasMoved = NO;
        _controlJudge = NO;
        _touchBeginValue = _moviePosition;
        _touchBeginPoint = touchPoint;
    }
    if (recognizer.state == UIGestureRecognizerStateChanged) {
        if (fabs(touchPoint.x - _touchBeginPoint.x) < kLeastMoveDistance && fabs(touchPoint.y - _touchBeginPoint.y) < kLeastMoveDistance) {
            return;
        }
        _hasMoved = YES;
        
        // 如果还没有判断出是什么手势就进行判断
        if (!_controlJudge) {
            // 根据滑动角度的tan值来进行判断
            float tan = fabs(touchPoint.y - _touchBeginPoint.y) / fabs(touchPoint.x - _touchBeginPoint.x);
            
            // 当滑动角度小于30度的时候, 进度手势
            if (tan < 1 / sqrt(3)) {
                _controlType = HCDPlayerControlTypeProgress;
                _controlJudge = YES;
            } else if (tan > sqrt(3)) {
                if (_touchBeginPoint.x < self.view.frame.size.width / 2) {
                    _controlType = HCDPlayerControlTypeLight;
                } else {
                    _controlType = HCDPlayerControlTypeVoice;
                }
                _controlJudge = YES;
            } else {
                _controlType = HCDPlayerControlTypeNone;
                return;
            }
        }
        if (_controlType == HCDPlayerControlTypeProgress) {
            float value = [self moveProgressControlWithTempPoint:touchPoint];
            [self timeValueChangingWithValue:value];
        }
    }
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        
//        const CGPoint vt = [recognizer velocityInView:self.view];
//        const CGPoint pt = [recognizer translationInView:self.view];
//        const CGFloat sp = MAX(0.1, log10(fabs(vt.x)) - 1.0);
//        const CGFloat sc = fabs(pt.x) * 0.33 * sp;
//        if (sc > 10) {
//
//            const CGFloat ff = pt.x > 0 ? 1.0 : -1.0;
//            [self setMoviePosition: _moviePosition + ff * MIN(sc, 600.0)];
//        }
        _controlJudge = NO;
        if (_hasMoved) {
            if (_controlType == HCDPlayerControlTypeProgress) {
                self.draggingProgressView.hidden = YES;
                float value = [self moveProgressControlWithTempPoint:touchPoint];
                [self setMoviePosition:value];
            }
        }
        //LoggerStream(2, @"pan %.2f %.2f %.2f sec", pt.x, vt.x, sc);
    }
}

- (float)moveProgressControlWithTempPoint:(CGPoint)tempPoint {
    float tempValue = _touchBeginValue + 90 * ((tempPoint.x - _touchBeginPoint.x) / kScreenWidth);
    if (tempValue > _decoder.duration) {
        tempValue = _decoder.duration;
    }else if (tempValue < 0){
        tempValue = 0.0f;
    }
    return tempValue;
}

-(void)timeValueChangingWithValue:(float)value{
    if (value > _touchBeginValue) {
        self.draggingProgressView.directionImageView.image = [UIImage imageNamed:@"hcdplayer.bundle/icon_video_player_fast"];
    } else if (value < _touchBeginValue) {
        self.draggingProgressView.directionImageView.image = [UIImage imageNamed:@"hcdplayer.bundle/icon_video_player_forward"];
    }
    self.draggingProgressView.hidden = NO;
    CGFloat duration = _decoder.duration;
    self.draggingProgressView.durationTimeLabel.text = formatTimeInterval(duration, NO);
    self.draggingProgressView.shiftTimeLabel.text = formatTimeInterval(value, NO);
}

#pragma mark - public

-(void)play {
    if (self.playing) {
        return;
    }
    
    if (!_decoder.validVideo && !_decoder.validAudio) {
        return;
    }
    
    if (_interrupted) {
        return;
    }
    
    self.playing = YES;
    _interrupted = NO;
    _disableUpdateHUD = NO;
    _tickCorrectionTime = 0;
    _tickCounter = 0;
    
#ifdef DEBUG
    _debugStartTime = -1;
#endif
    
    [self asyncDecodeFrames];
    [self updatePlayButton];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self tick];
    });
    
    if (_decoder.validAudio)
        [self enableAudio:YES];
    
    LoggerStream(1, @"play movie");
}

- (void)pause {
    if (!self.playing)
        return;
    
    self.playing = NO;
    //_interrupted = YES;
    [self enableAudio:NO];
    [self updatePlayButton];
    LoggerStream(1, @"pause movie");
}

- (void) setMoviePosition: (CGFloat) position {
    BOOL playMode = self.playing;
    
    self.playing = NO;
    _disableUpdateHUD = YES;
    [self enableAudio:NO];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        [self updatePosition:position playMode:playMode];
    });
}

#pragma mark - actions

- (void)doneDidTouch:(id)sender {
    ((AppDelegate *)[[UIApplication sharedApplication] delegate]).isAllowAutorotate = NO;
    if (self.presentingViewController || !self.navigationController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)infoDidTouch:(id)sender {
    [self showInfoView: !_infoMode animated:YES];
}

- (void)playDidTouch:(id)sender{
    if (self.playing) {
        [self pause];
    } else {
        [self play];
    }
}

- (void)fullDidTouch:(id)sender {
    [self fullScreen];
}

- (void)exitFullDidTouch:(id)sender {
    [self fullScreen];
}

- (void)replayDidTouch:(id)sender {
    [self restorePlay];
}

- (void)forwardDidTouch: (id)sender{
    [self setMoviePosition: _moviePosition + 10];
}

- (void)rewindDidTouch: (id)sender{
    [self setMoviePosition: _moviePosition - 10];
}

- (void)progressDidChange: (id)sender{
    NSAssert(_decoder.duration != MAXFLOAT, @"bugcheck");
    UISlider *slider = sender;
    [self setMoviePosition:slider.value * _decoder.duration];
}

#pragma mark - 全屏旋转处理

//界面方向改变的处理
- (void)handleStatusBarOrientationChange: (NSNotification *)notification{
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    [self updatePlayerView:interfaceOrientation];
}

- (void)toOrientation:(UIInterfaceOrientation)orientation {
    if (_currentOrientation == orientation) {
        return;
    }
    _currentOrientation = orientation;
    [self updatePlayerView:_currentOrientation];
    [UIView animateWithDuration:0.5 animations:^{
        [[UIDevice currentDevice] setValue: @(orientation) forKey:@"orientation"];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)updatePlayerView:(UIInterfaceOrientation)orientation {
    if (orientation == UIInterfaceOrientationPortrait) {
        self.topHUD.frame = CGRectMake(0, 0, kScreenWidth, _statusBarHeight + 50);
        self.bottomView.frame = CGRectMake(0, kScreenHeight - (_tabbarSafeBottomMargin + 50), kScreenWidth, _tabbarSafeBottomMargin + 50);
        self.doneButton.frame = CGRectMake(0, _statusBarHeight, 50, 50);
        self.airPlayButton.frame = CGRectMake(kScreenWidth-50, _statusBarHeight, 50, 50);
        self.pauseButton.frame = CGRectMake(0, 0, 50, 50);
        self.playButton.frame = CGRectMake(0, 0, 50, 50);
        self.fullButton.frame = CGRectMake(kScreenWidth - 50, 0, 50, 50);
        self.exitFullButton.frame = CGRectMake(kScreenWidth - 50, 0, 50, 50);
        self.progressLabel.frame = CGRectMake(50, 0, 46, 50);
        self.leftLabel.frame = CGRectMake(kScreenWidth-100 + 4, 0, 50, 50);
        self.progressSlider.frame = CGRectMake(100, 0, kScreenWidth - 200, 50);
        
        [self.exitFullButton removeFromSuperview];
        [self.bottomView addSubview:self.fullButton];
        _fullscreen = YES;

    } else if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
        
        if (iPhoneX) {
            self.bottomView.frame = CGRectMake(0, kScreenHeight - 60, kScreenWidth, 60);
            self.topHUD.frame = CGRectMake(0, 0, kScreenWidth, 50);
            self.doneButton.frame = CGRectMake(_statusBarHeight, 0, 50, 50);
            self.airPlayButton.frame = CGRectMake(kScreenWidth - 50 - _statusBarHeight, 0, 50, 50);
            self.pauseButton.frame = CGRectMake(_statusBarHeight, 0, 50, 50);
            self.playButton.frame = CGRectMake(_statusBarHeight, 0, 50, 50);
            self.exitFullButton.frame = CGRectMake(kScreenWidth - 50 - _statusBarHeight, 0, 50, 50);
            self.progressLabel.frame = CGRectMake(50 + _statusBarHeight, 0, 46, 50);
            self.leftLabel.frame = CGRectMake(kScreenWidth - 100 - _statusBarHeight + 4, 0, 50, 50);
            self.progressSlider.frame = CGRectMake(100 + _statusBarHeight, 0, kScreenWidth - 200 - 2 * _statusBarHeight, 50);
        } else {
            self.bottomView.frame = CGRectMake(0, kScreenHeight - 50, kScreenWidth, 50);
            self.topHUD.frame = CGRectMake(0, 0, kScreenWidth, _statusBarHeight + 50);
            self.doneButton.frame = CGRectMake(0, _statusBarHeight, 50, 50);
            self.airPlayButton.frame = CGRectMake(kScreenWidth-50, _statusBarHeight, 50, 50);
            self.pauseButton.frame = CGRectMake(0, 0, 50, 50);
            self.playButton.frame = CGRectMake(0, 0, 50, 50);
            self.exitFullButton.frame = CGRectMake(kScreenWidth - 50, 0, 50, 50);
            self.progressLabel.frame = CGRectMake(50, 0, 46, 50);
            self.leftLabel.frame = CGRectMake(kScreenWidth-100 + 4, 0, 50, 50);
            self.progressSlider.frame = CGRectMake(100, 0, kScreenWidth - 200, 50);
        }
        [self.fullButton removeFromSuperview];
        [self.bottomView addSubview:self.exitFullButton];
        _fullscreen = NO;
    }
}

#pragma mark - private

- (void)initData {
    _statusBarHeight = kStatusBarHeight;
    _tabbarSafeBottomMargin = kTabbarSafeBottomMargin;
    _isFullScreen = NO;
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    switch (orientation) {
        case UIDeviceOrientationPortrait:
            _currentOrientation = UIInterfaceOrientationPortrait;
            break;
        case UIDeviceOrientationLandscapeLeft:
            _currentOrientation = UIInterfaceOrientationLandscapeLeft;
            break;
        case UIDeviceOrientationLandscapeRight:
            _currentOrientation = UIInterfaceOrientationLandscapeRight;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            _currentOrientation = UIInterfaceOrientationPortraitUpsideDown;
            break;
        default:
            break;
    }
}

- (void) setMovieDecoder: (HcdMovieDecoder *) decoder
               withError: (NSError *) error {
    LoggerStream(2, @"setMovieDecoder");
    
    if (!error && decoder) {
        
        _decoder        = decoder;
        _dispatchQueue  = dispatch_queue_create("HcdMovie", DISPATCH_QUEUE_SERIAL);
        _videoFrames    = [NSMutableArray array];
        _audioFrames    = [NSMutableArray array];
        
        if (_decoder.subtitleStreamsCount) {
            _subtitles = [NSMutableArray array];
        }
        
        if (_decoder.isNetwork) {
            
            _minBufferedDuration = NETWORK_MIN_BUFFERED_DURATION;
            _maxBufferedDuration = NETWORK_MAX_BUFFERED_DURATION;
            
        } else {
            
            _minBufferedDuration = LOCAL_MIN_BUFFERED_DURATION;
            _maxBufferedDuration = LOCAL_MAX_BUFFERED_DURATION;
        }
        
        if (!_decoder.validVideo)
            _minBufferedDuration *= 10.0; // increase for audio
        
        // allow to tweak some parameters at runtime
        if (_parameters.count) {
            
            id val;
            
            val = [_parameters valueForKey: HcdMovieParameterMinBufferedDuration];
            if ([val isKindOfClass:[NSNumber class]])
                _minBufferedDuration = [val floatValue];
            
            val = [_parameters valueForKey: HcdMovieParameterMaxBufferedDuration];
            if ([val isKindOfClass:[NSNumber class]])
                _maxBufferedDuration = [val floatValue];
            
            val = [_parameters valueForKey: HcdMovieParameterDisableDeinterlacing];
            if ([val isKindOfClass:[NSNumber class]])
                _decoder.disableDeinterlacing = [val boolValue];
            
            if (_maxBufferedDuration < _minBufferedDuration)
                _maxBufferedDuration = _minBufferedDuration * 2;
        }
        
        LoggerStream(2, @"buffered limit: %.1f - %.1f", _minBufferedDuration, _maxBufferedDuration);
        
        if (self.isViewLoaded) {
            
            [self setupPresentView];
            
            _progressLabel.hidden   = NO;
            self.progressSlider.hidden  = NO;
            _leftLabel.hidden       = NO;
            _infoButton.hidden      = NO;
            
            if (self.activityIndicatorView.isAnimating) {
                
                [self.activityIndicatorView stopAnimating];
                // if (self.view.window)
                [self restorePlay];
            }
        }
        
    } else {
        
        if (self.isViewLoaded && self.view.window) {
            
            [self.activityIndicatorView stopAnimating];
            if (!_interrupted)
                [self handleDecoderMovieError: error];
        }
    }
}

- (void)restorePlay {
    NSNumber *n = [gHistory valueForKey:_decoder.path];
    if (n) {
        [self updatePosition:n.floatValue playMode:YES];
    } else {
        [self play];
    }
}

- (void) setupPresentView
{
    CGRect bounds = self.view.bounds;
    
    if (_decoder.validVideo) {
        _glView = [[HcdMovieGLView alloc] initWithFrame:bounds decoder:_decoder];
    }
    
    if (!_glView) {
        
        LoggerVideo(0, @"fallback to use RGB video frame and UIKit");
        [_decoder setupVideoFrameFormat:HcdVideoFrameFormatRGB];
        _imageView = [[UIImageView alloc] initWithFrame:bounds];
        _imageView.backgroundColor = [UIColor blackColor];
    }
    
    UIView *frameView = [self frameView];
    frameView.contentMode = UIViewContentModeScaleAspectFit;
    frameView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    
    [self.view insertSubview:frameView atIndex:0];
    
    if (_decoder.validVideo) {
        
        [self setupUserInteraction];
        
    } else {
        
        _imageView.image = [UIImage imageNamed:@"Hcdmovie.bundle/music_icon.png"];
        _imageView.contentMode = UIViewContentModeCenter;
    }
    
    self.view.backgroundColor = [UIColor clearColor];
    
    if (_decoder.duration == MAXFLOAT) {
        
        self.leftLabel.text = @"\u221E"; // infinity
        self.leftLabel.font = [UIFont systemFontOfSize:14];
        
        CGRect frame;
        
        frame = self.leftLabel.frame;
        frame.origin.x += 40;
        frame.size.width -= 40;
        self.leftLabel.frame = frame;
        
        frame =self.progressSlider.frame;
        frame.size.width += 40;
        self.progressSlider.frame = frame;
        
    } else {
        
        [self.progressSlider addTarget:self
                            action:@selector(progressDidChange:)
                  forControlEvents:UIControlEventValueChanged];
    }
    
    if (_decoder.subtitleStreamsCount) {
        
        CGSize size = self.view.bounds.size;
        
        _subtitlesLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, size.height, size.width, 0)];
        _subtitlesLabel.numberOfLines = 0;
        _subtitlesLabel.backgroundColor = [UIColor clearColor];
        _subtitlesLabel.opaque = NO;
        _subtitlesLabel.adjustsFontSizeToFitWidth = NO;
        _subtitlesLabel.textAlignment = NSTextAlignmentCenter;
        _subtitlesLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _subtitlesLabel.textColor = [UIColor whiteColor];
        _subtitlesLabel.font = [UIFont systemFontOfSize:16];
        _subtitlesLabel.hidden = YES;
        
        [self.view addSubview:_subtitlesLabel];
    }
}

- (void) setupUserInteraction {
    UIView * view = [self frameView];
    view.userInteractionEnabled = YES;
    
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    _tapGestureRecognizer.numberOfTapsRequired = 1;
    
    _doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    _doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    
    [_tapGestureRecognizer requireGestureRecognizerToFail: _doubleTapGestureRecognizer];
    
    [view addGestureRecognizer:_doubleTapGestureRecognizer];
    [view addGestureRecognizer:_tapGestureRecognizer];
    
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    _panGestureRecognizer.enabled = YES;

    [view addGestureRecognizer:_panGestureRecognizer];
}

- (UIView *) frameView {
    return _glView ? _glView : _imageView;
}

- (void) audioCallbackFillData: (float *) outData
                     numFrames: (UInt32) numFrames
                   numChannels: (UInt32) numChannels {
    //fillSignalF(outData,numFrames,numChannels);
    //return;
    
    if (_buffered) {
        memset(outData, 0, numFrames * numChannels * sizeof(float));
        return;
    }
    
    @autoreleasepool {
        
        while (numFrames > 0) {
            
            if (!_currentAudioFrame) {
                
                @synchronized(_audioFrames) {
                    
                    NSUInteger count = _audioFrames.count;
                    
                    if (count > 0) {
                        
                        HcdAudioFrame *frame = _audioFrames[0];
                        
#ifdef DUMP_AUDIO_DATA
                        LoggerAudio(2, @"Audio frame position: %f", frame.position);
#endif
                        if (_decoder.validVideo) {
                            
                            const CGFloat delta = _moviePosition - frame.position;
                            
                            if (delta < -0.1) {
                                
                                memset(outData, 0, numFrames * numChannels * sizeof(float));
#ifdef DEBUG
                                LoggerStream(0, @"desync audio (outrun) wait %.4f %.4f", _moviePosition, frame.position);
                                _debugAudioStatus = 1;
                                _debugAudioStatusTS = [NSDate date];
#endif
                                break; // silence and exit
                            }
                            
                            [_audioFrames removeObjectAtIndex:0];
                            
                            if (delta > 0.1 && count > 1) {
                                
#ifdef DEBUG
                                LoggerStream(0, @"desync audio (lags) skip %.4f %.4f", _moviePosition, frame.position);
                                _debugAudioStatus = 2;
                                _debugAudioStatusTS = [NSDate date];
#endif
                                continue;
                            }
                            
                        } else {
                            
                            [_audioFrames removeObjectAtIndex:0];
                            _moviePosition = frame.position;
                            _bufferedDuration -= frame.duration;
                        }
                        
                        _currentAudioFramePos = 0;
                        _currentAudioFrame = frame.samples;
                    }
                }
            }
            
            if (_currentAudioFrame) {
                
                const void *bytes = (Byte *)_currentAudioFrame.bytes + _currentAudioFramePos;
                const NSUInteger bytesLeft = (_currentAudioFrame.length - _currentAudioFramePos);
                const NSUInteger frameSizeOf = numChannels * sizeof(float);
                const NSUInteger bytesToCopy = MIN(numFrames * frameSizeOf, bytesLeft);
                const NSUInteger framesToCopy = bytesToCopy / frameSizeOf;
                
                memcpy(outData, bytes, bytesToCopy);
                numFrames -= framesToCopy;
                outData += framesToCopy * numChannels;
                
                if (bytesToCopy < bytesLeft)
                    _currentAudioFramePos += bytesToCopy;
                else
                    _currentAudioFrame = nil;
                
            } else {
                
                memset(outData, 0, numFrames * numChannels * sizeof(float));
                //LoggerStream(1, @"silence audio");
#ifdef DEBUG
                _debugAudioStatus = 3;
                _debugAudioStatusTS = [NSDate date];
#endif
                break;
            }
        }
    }
}

- (void) enableAudio: (BOOL) on {
    id<HcdAudioManager> audioManager = [HcdAudioManager audioManager];
    
    if (on && _decoder.validAudio) {
        
        audioManager.outputBlock = ^(float *outData, UInt32 numFrames, UInt32 numChannels) {
            
            [self audioCallbackFillData: outData numFrames:numFrames numChannels:numChannels];
        };
        
        [audioManager play];
        
        LoggerAudio(2, @"audio device smr: %d fmt: %d chn: %d",
                    (int)audioManager.samplingRate,
                    (int)audioManager.numBytesPerSample,
                    (int)audioManager.numOutputChannels);
        
    } else {
        
        [audioManager pause];
        audioManager.outputBlock = ^(float * _Nonnull data, UInt32 numFrames, UInt32 numChannels) {
            
        };
    }
}

- (BOOL) addFrames: (NSArray *)frames
{
    if (_decoder.validVideo) {
        
        @synchronized(_videoFrames) {
            
            for (HcdMovieFrame *frame in frames)
                if (frame.type == HcdMovieFrameTypeVideo) {
                    [_videoFrames addObject:frame];
                    _bufferedDuration += frame.duration;
                }
        }
    }
    
    if (_decoder.validAudio) {
        
        @synchronized(_audioFrames) {
            
            for (HcdMovieFrame *frame in frames)
                if (frame.type == HcdMovieFrameTypeAudio) {
                    [_audioFrames addObject:frame];
                    if (!_decoder.validVideo)
                        _bufferedDuration += frame.duration;
                }
        }
        
        if (!_decoder.validVideo) {
            
            for (HcdMovieFrame *frame in frames)
                if (frame.type == HcdMovieFrameTypeArtwork)
                    self.artworkFrame = (HcdArtworkFrame *)frame;
        }
    }
    
    if (_decoder.validSubtitles) {
        
        @synchronized(_subtitles) {
            
            for (HcdMovieFrame *frame in frames)
                if (frame.type == HcdMovieFrameTypeSubtitle) {
                    [_subtitles addObject:frame];
                }
        }
    }
    
    return self.playing && _bufferedDuration < _maxBufferedDuration;
}

- (BOOL) decodeFrames {
    //NSAssert(dispatch_get_current_queue() == _dispatchQueue, @"bugcheck");
    
    NSArray *frames = nil;
    
    if (_decoder.validVideo ||
        _decoder.validAudio) {
        
        frames = [_decoder decodeFrames:0];
    }
    
    if (frames.count) {
        return [self addFrames: frames];
    }
    return NO;
}

- (void) asyncDecodeFrames {
    if (self.decoding)
        return;
    
    __weak HcdMovieViewController *weakSelf = self;
    __weak HcdMovieDecoder *weakDecoder = _decoder;
    
    const CGFloat duration = _decoder.isNetwork ? .0f : 0.1f;
    
    self.decoding = YES;
    dispatch_async(_dispatchQueue, ^{
        
        {
            __strong HcdMovieViewController *strongSelf = weakSelf;
            if (!strongSelf.playing)
                return;
        }
        
        BOOL good = YES;
        while (good) {
            
            good = NO;
            
            @autoreleasepool {
                
                __strong HcdMovieDecoder *decoder = weakDecoder;
                
                if (decoder && (decoder.validVideo || decoder.validAudio)) {
                    
                    NSArray *frames = [decoder decodeFrames:duration];
                    if (frames.count) {
                        
                        __strong HcdMovieViewController *strongSelf = weakSelf;
                        if (strongSelf)
                            good = [strongSelf addFrames:frames];
                    }
                }
            }
        }
        
        {
            __strong HcdMovieViewController *strongSelf = weakSelf;
            if (strongSelf) strongSelf.decoding = NO;
        }
    });
}

- (void)tick {
    if (_buffered && ((_bufferedDuration > _minBufferedDuration) || _decoder.isEOF)) {
        
        _tickCorrectionTime = 0;
        _buffered = NO;
        [self.activityIndicatorView stopAnimating];
    }
    
    CGFloat interval = 0;
    if (!_buffered)
        interval = [self presentFrame];
    
    if (self.playing) {
        
        const NSUInteger leftFrames =
        (_decoder.validVideo ? _videoFrames.count : 0) +
        (_decoder.validAudio ? _audioFrames.count : 0);
        
        if (0 == leftFrames) {
            
            if (_decoder.isEOF) {
                
                [self pause];
                [self updateHUD];
                return;
            }
            
            if (_minBufferedDuration > 0 && !_buffered) {
                
                _buffered = YES;
                [self.activityIndicatorView startAnimating];
            }
        }
        
        if (!leftFrames ||
            !(_bufferedDuration > _minBufferedDuration)) {
            
            [self asyncDecodeFrames];
        }
        
        const NSTimeInterval correction = [self tickCorrection];
        const NSTimeInterval time = MAX(interval + correction, 0.01);
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self tick];
        });
    }
    
    if ((_tickCounter++ % 3) == 0) {
        [self updateHUD];
    }
}

- (CGFloat)tickCorrection {
    if (_buffered)
        return 0;
    
    const NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    
    if (!_tickCorrectionTime) {
        
        _tickCorrectionTime = now;
        _tickCorrectionPosition = _moviePosition;
        return 0;
    }
    
    NSTimeInterval dPosition = _moviePosition - _tickCorrectionPosition;
    NSTimeInterval dTime = now - _tickCorrectionTime;
    NSTimeInterval correction = dPosition - dTime;
    
    //if ((_tickCounter % 200) == 0)
    //    LoggerStream(1, @"tick correction %.4f", correction);
    
    if (correction > 1.f || correction < -1.f) {
        
        LoggerStream(1, @"tick correction reset %.2f", correction);
        correction = 0;
        _tickCorrectionTime = 0;
    }
    
    return correction;
}

- (CGFloat)presentFrame {
    CGFloat interval = 0;
    
    if (_decoder.validVideo) {
        
        HcdVideoFrame *frame;
        
        @synchronized(_videoFrames) {
            
            if (_videoFrames.count > 0) {
                
                frame = _videoFrames[0];
                [_videoFrames removeObjectAtIndex:0];
                _bufferedDuration -= frame.duration;
            }
        }
        
        if (frame)
            interval = [self presentVideoFrame:frame];
        
    } else if (_decoder.validAudio) {
        
        //interval = _bufferedDuration * 0.5;
        
        if (self.artworkFrame) {
            
            _imageView.image = [self.artworkFrame asImage];
            self.artworkFrame = nil;
        }
    }
    
    if (_decoder.validSubtitles)
        [self presentSubtitles];
    
#ifdef DEBUG
    if (self.playing && _debugStartTime < 0)
        _debugStartTime = [NSDate timeIntervalSinceReferenceDate] - _moviePosition;
#endif
    
    return interval;
}

- (CGFloat) presentVideoFrame: (HcdVideoFrame *) frame {
    if (_glView) {
        [_glView render:frame];
    } else {
        HcdVideoFrameRGB *rgbFrame = (HcdVideoFrameRGB *)frame;
        _imageView.image = [rgbFrame asImage];
    }
    
    _moviePosition = frame.position;
    
    return frame.duration;
}

- (void) presentSubtitles {
    NSArray *actual, *outdated;
    
    if ([self subtitleForPosition:_moviePosition
                           actual:&actual
                         outdated:&outdated]){
        
        if (outdated.count) {
            @synchronized(_subtitles) {
                [_subtitles removeObjectsInArray:outdated];
            }
        }
        
        if (actual.count) {
            
            NSMutableString *ms = [NSMutableString string];
            for (HcdSubtitleFrame *subtitle in actual.reverseObjectEnumerator) {
                if (ms.length) [ms appendString:@"\n"];
                [ms appendString:subtitle.text];
            }
            
            if (![_subtitlesLabel.text isEqualToString:ms]) {
                
                CGSize viewSize = self.view.bounds.size;
                CGSize size = [ms sizeWithConstainedSize:viewSize font:_subtitlesLabel.font];
                _subtitlesLabel.text = ms;
                _subtitlesLabel.frame = CGRectMake(0, viewSize.height - size.height - 10,
                                                   viewSize.width, size.height);
                _subtitlesLabel.hidden = NO;
            }
            
        } else {
            
            _subtitlesLabel.text = nil;
            _subtitlesLabel.hidden = YES;
        }
    }
}

- (BOOL) subtitleForPosition: (CGFloat) position
                      actual: (NSArray **) pActual
                    outdated: (NSArray **) pOutdated
{
    if (!_subtitles.count)
        return NO;
    
    NSMutableArray *actual = nil;
    NSMutableArray *outdated = nil;
    
    for (HcdSubtitleFrame *subtitle in _subtitles) {
        
        if (position < subtitle.position) {
            
            break; // assume what subtitles sorted by position
            
        } else if (position >= (subtitle.position + subtitle.duration)) {
            
            if (pOutdated) {
                if (!outdated)
                    outdated = [NSMutableArray array];
                [outdated addObject:subtitle];
            }
            
        } else {
            
            if (pActual) {
                if (!actual)
                    actual = [NSMutableArray array];
                [actual addObject:subtitle];
            }
        }
    }
    
    if (pActual) *pActual = actual;
    if (pOutdated) *pOutdated = outdated;
    
    return actual.count || outdated.count;
}

- (void) updateBottomToolView {
//    UIBarButtonItem *playPauseBtn = self.playing ? _pauseBtn : _playBtn;
//    [_bottomBar setItems:@[_spaceItem, _rewindBtn, _fixedSpaceItem, playPauseBtn,
//                           _fixedSpaceItem, _fforwardBtn, _spaceItem] animated:NO];
    if (self.playing) {
        [self.playButton removeFromSuperview];
        [self.bottomView addSubview:self.pauseButton];
    } else {
        [self.pauseButton removeFromSuperview];
        [self.bottomView addSubview:self.playButton];
    }
}

- (void) updatePlayButton {
    [self updateBottomToolView];
}

- (void)updateHUD {
    NSLog(@"updateHUD");
    
    if (_disableUpdateHUD)
        return;
    
    const CGFloat duration = _decoder.duration;
    const CGFloat position = _moviePosition -_decoder.startTime;
    
    if (self.progressSlider.state == UIControlStateNormal)
        self.progressSlider.value = position / duration;
    _progressLabel.text = formatTimeInterval(position, NO);
    
    if (_decoder.duration != MAXFLOAT)
        self.leftLabel.text = formatTimeInterval(duration - position, YES);
    
#ifdef DEBUG
    const NSTimeInterval timeSinceStart = [NSDate timeIntervalSinceReferenceDate] - _debugStartTime;
    NSString *subinfo = _decoder.validSubtitles ? [NSString stringWithFormat: @" %lu",(unsigned long)_subtitles.count] : @"";
    
    NSString *audioStatus;
    
    if (_debugAudioStatus) {
        
         if (NSOrderedAscending == [_debugAudioStatusTS compare: [NSDate dateWithTimeIntervalSinceNow:-0.5]]) {
            _debugAudioStatus = 0;
        }
    }
    
    if      (_debugAudioStatus == 1) audioStatus = @"\n(audio outrun)";
    else if (_debugAudioStatus == 2) audioStatus = @"\n(audio lags)";
    else if (_debugAudioStatus == 3) audioStatus = @"\n(audio silence)";
    else audioStatus = @"";
    
    _messageLabel.text = [NSString stringWithFormat:@"%lu %lu %@ %c - %@ %@ %@\n%@",
                          (unsigned long)_videoFrames.count,
                          (unsigned long)_audioFrames.count,
                          subinfo,
                          self.decoding ? 'D' : ' ',
                          formatTimeInterval(timeSinceStart, NO),
                          //timeSinceStart > _moviePosition + 0.5 ? @" (lags)" : @"",
                          _decoder.isEOF ? @"- END" : @"",
                          audioStatus,
                          _buffered ? [NSString stringWithFormat:@"buffering %.1f%%", _bufferedDuration / _minBufferedDuration * 100] : @""];
#endif
}

- (void)showHUD: (BOOL)show {
    _hiddenHUD = !show;
//    _panGestureRecognizer.enabled = _hiddenHUD;
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:_hiddenHUD];
    
    __weak HcdMovieViewController *weakSelf = self;
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone
                     animations:^{
                         
                         CGFloat alpha = weakSelf.hiddenHUD ? 0 : 1;
                         weakSelf.topBar.alpha = alpha;
                         weakSelf.topHUD.alpha = alpha;
                         weakSelf.bottomView.alpha = alpha;
                     }
                     completion:nil];
    
}

- (void)setMoviePositionFromDecoder {
    _moviePosition = _decoder.position;
}

- (void)setDecoderPosition:(CGFloat)position {
    _decoder.position = position;
}

- (void)enableUpdateHUD {
    _disableUpdateHUD = NO;
}

- (void)updatePosition: (CGFloat)position
              playMode: (BOOL)playMode {
    [self freeBufferedFrames];
    
    position = MIN(_decoder.duration - 1, MAX(0, position));
    
    __weak HcdMovieViewController *weakSelf = self;
    
    dispatch_async(_dispatchQueue, ^{
        
        if (playMode) {
            
            {
                __strong HcdMovieViewController *strongSelf = weakSelf;
                if (!strongSelf) return;
                [strongSelf setDecoderPosition: position];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                __strong HcdMovieViewController *strongSelf = weakSelf;
                if (strongSelf) {
                    [strongSelf setMoviePositionFromDecoder];
                    [strongSelf play];
                }
            });
            
        } else {
            
            {
                __strong HcdMovieViewController *strongSelf = weakSelf;
                if (!strongSelf) return;
                [strongSelf setDecoderPosition: position];
                [strongSelf decodeFrames];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                __strong HcdMovieViewController *strongSelf = weakSelf;
                if (strongSelf) {
                    
                    [strongSelf enableUpdateHUD];
                    [strongSelf setMoviePositionFromDecoder];
                    [strongSelf presentFrame];
                    [strongSelf updateHUD];
                }
            });
        }
    });
}

- (void) freeBufferedFrames
{
    @synchronized(_videoFrames) {
        [_videoFrames removeAllObjects];
    }
    
    @synchronized(_audioFrames) {
        
        [_audioFrames removeAllObjects];
        _currentAudioFrame = nil;
    }
    
    if (_subtitles) {
        @synchronized(_subtitles) {
            [_subtitles removeAllObjects];
        }
    }
    
    _bufferedDuration = 0;
}

- (void) showInfoView: (BOOL) showInfo animated: (BOOL)animated
{
    if (!_tableView)
        [self createTableView];
    
    [self pause];
    
    CGSize size = self.view.bounds.size;
    CGFloat Y = self.topHUD.bounds.size.height;
    
    if (showInfo) {
        
        _tableView.hidden = NO;
        
        if (animated) {
            
            [UIView animateWithDuration:0.4
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone
                             animations:^{
                                 
                                 self.tableView.frame = CGRectMake(0,Y,size.width,size.height - Y);
                             }
                             completion:nil];
        } else {
            
            _tableView.frame = CGRectMake(0,Y,size.width,size.height - Y);
        }
        
    } else {
        
        if (animated) {
            
            [UIView animateWithDuration:0.4
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone
                             animations:^{
                                 
                                 self.tableView.frame = CGRectMake(0,size.height,size.width,size.height - Y);
                                 
                             }
                             completion:^(BOOL f){
                                 
                                 if (f) {
                                     self.tableView.hidden = YES;
                                 }
                             }];
        } else {
            
            _tableView.frame = CGRectMake(0,size.height,size.width,size.height - Y);
            _tableView.hidden = YES;
        }
    }
    
    _infoMode = showInfo;
}

- (void) createTableView
{
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth |UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.hidden = YES;
    
    CGSize size = self.view.bounds.size;
    CGFloat Y = self.topHUD.bounds.size.height;
    _tableView.frame = CGRectMake(0,size.height,size.width,size.height - Y);
    
    [self.view addSubview:_tableView];
}

- (void) handleDecoderMovieError: (NSError *) error
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failure", nil)
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Close", nil)
                                              otherButtonTitles:nil];
    
    [alertView show];
}

- (BOOL) interruptDecoder
{
    //if (!_decoder)
    //    return NO;
    return _interrupted;
}

- (void)fullScreen {
    if (_isFullScreen) {
        _isFullScreen = NO;
        [self toOrientation:UIInterfaceOrientationPortrait];
    } else {
        _isFullScreen = YES;
        [self toOrientation:UIInterfaceOrientationLandscapeRight];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return HcdMovieInfoSectionCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case HcdMovieInfoSectionGeneral:
            return NSLocalizedString(@"General", nil);
        case HcdMovieInfoSectionMetadata:
            return NSLocalizedString(@"Metadata", nil);
        case HcdMovieInfoSectionVideo: {
            NSArray *a = _decoder.info[@"video"];
            return a.count ? NSLocalizedString(@"Video", nil) : nil;
        }
        case HcdMovieInfoSectionAudio: {
            NSArray *a = _decoder.info[@"audio"];
            return a.count ?  NSLocalizedString(@"Audio", nil) : nil;
        }
        case HcdMovieInfoSectionSubtitles: {
            NSArray *a = _decoder.info[@"subtitles"];
            return a.count ? NSLocalizedString(@"Subtitles", nil) : nil;
        }
    }
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case HcdMovieInfoSectionGeneral:
            return HcdMovieInfoGeneralCount;
            
        case HcdMovieInfoSectionMetadata: {
            NSDictionary *d = [_decoder.info valueForKey:@"metadata"];
            return d.count;
        }
            
        case HcdMovieInfoSectionVideo: {
            NSArray *a = _decoder.info[@"video"];
            return a.count;
        }
            
        case HcdMovieInfoSectionAudio: {
            NSArray *a = _decoder.info[@"audio"];
            return a.count;
        }
            
        case HcdMovieInfoSectionSubtitles: {
            NSArray *a = _decoder.info[@"subtitles"];
            return a.count ? a.count + 1 : 0;
        }
            
        default:
            return 0;
    }
}

- (id) mkCell: (NSString *) cellIdentifier
    withStyle: (UITableViewCellStyle) style
{
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:style reuseIdentifier:cellIdentifier];
    }
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if (indexPath.section == HcdMovieInfoSectionGeneral) {
        
        if (indexPath.row == HcdMovieInfoGeneralBitrate) {
            
            int bitrate = [_decoder.info[@"bitrate"] intValue];
            cell = [self mkCell:@"ValueCell" withStyle:UITableViewCellStyleValue1];
            cell.textLabel.text = NSLocalizedString(@"Bitrate", nil);
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d kb/s",bitrate / 1000];
            
        } else if (indexPath.row == HcdMovieInfoGeneralFormat) {
            
            NSString *format = _decoder.info[@"format"];
            cell = [self mkCell:@"ValueCell" withStyle:UITableViewCellStyleValue1];
            cell.textLabel.text = NSLocalizedString(@"Format", nil);
            cell.detailTextLabel.text = format ? format : @"-";
        }
        
    } else if (indexPath.section == HcdMovieInfoSectionMetadata) {
        
        NSDictionary *d = _decoder.info[@"metadata"];
        NSString *key = d.allKeys[indexPath.row];
        cell = [self mkCell:@"ValueCell" withStyle:UITableViewCellStyleValue1];
        cell.textLabel.text = key.capitalizedString;
        cell.detailTextLabel.text = [d valueForKey:key];
        
    } else if (indexPath.section == HcdMovieInfoSectionVideo) {
        
        NSArray *a = _decoder.info[@"video"];
        cell = [self mkCell:@"VideoCell" withStyle:UITableViewCellStyleValue1];
        cell.textLabel.text = a[indexPath.row];
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.textLabel.numberOfLines = 2;
        
    } else if (indexPath.section == HcdMovieInfoSectionAudio) {
        
        NSArray *a = _decoder.info[@"audio"];
        cell = [self mkCell:@"AudioCell" withStyle:UITableViewCellStyleValue1];
        cell.textLabel.text = a[indexPath.row];
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.textLabel.numberOfLines = 2;
        BOOL selected = _decoder.selectedAudioStream == indexPath.row;
        cell.accessoryType = selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        
    } else if (indexPath.section == HcdMovieInfoSectionSubtitles) {
        
        NSArray *a = _decoder.info[@"subtitles"];
        
        cell = [self mkCell:@"SubtitleCell" withStyle:UITableViewCellStyleValue1];
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.textLabel.numberOfLines = 1;
        
        if (indexPath.row) {
            cell.textLabel.text = a[indexPath.row - 1];
        } else {
            cell.textLabel.text = NSLocalizedString(@"Disable", nil);
        }
        
        const BOOL selected = _decoder.selectedSubtitleStream == (indexPath.row - 1);
        cell.accessoryType = selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == HcdMovieInfoSectionAudio) {
        
        NSInteger selected = _decoder.selectedAudioStream;
        
        if (selected != indexPath.row) {
            
            _decoder.selectedAudioStream = indexPath.row;
            NSInteger now = _decoder.selectedAudioStream;
            
            if (now == indexPath.row) {
                
                UITableViewCell *cell;
                
                cell = [_tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                
                indexPath = [NSIndexPath indexPathForRow:selected inSection:HcdMovieInfoSectionAudio];
                cell = [_tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        
    } else if (indexPath.section == HcdMovieInfoSectionSubtitles) {
        
        NSInteger selected = _decoder.selectedSubtitleStream;
        
        if (selected != (indexPath.row - 1)) {
            
            _decoder.selectedSubtitleStream = indexPath.row - 1;
            NSInteger now = _decoder.selectedSubtitleStream;
            
            if (now == (indexPath.row - 1)) {
                
                UITableViewCell *cell;
                
                cell = [_tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                
                indexPath = [NSIndexPath indexPathForRow:selected + 1 inSection:HcdMovieInfoSectionSubtitles];
                cell = [_tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            
            // clear subtitles
            _subtitlesLabel.text = nil;
            _subtitlesLabel.hidden = YES;
            @synchronized(_subtitles) {
                [_subtitles removeAllObjects];
            }
        }
    }
}

@end
