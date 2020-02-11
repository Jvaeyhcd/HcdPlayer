//
//  HCDPlayerViewController.m
//  HCDPlayer
//
//  Created by Jvaeyhcd on 06/12/2019.
//  Copyright © 2016 Jvaeyhcd. All rights reserved.
//

#import "HCDPlayerViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import "HCDPlayerUtils.h"
#import "HcdFileManager.h"
#import "HcdAppManager.h"
#import "HcdPlayerDraggingProgressView.h"
#import "HcdBrightnessProgressView.h"
#import "HcdSoundProgressView.h"
#import "MRDLNA.h"
#import <GCDWebServer/GCDWebDAVServer.h>
#import <GCDWebServer/GCDWebServerFileResponse.h>
#import "HcdActionSheet.h"
#import "HcdPopSelectView.h"
#import "RemoteControlView.h"

#define kLeastMoveDistance 15.0

// 播放器状态
typedef enum : NSUInteger {
    HCDPlayerOperationNone,
    HCDPlayerOperationOpen,
    HCDPlayerOperationPlay,
    HCDPlayerOperationPause,
    HCDPlayerOperationClose,
} HCDPlayerOperation;

typedef enum : NSUInteger {
    HCDPlayerControlTypeNone,
    HCDPlayerControlTypeProgress,
    HCDPlayerControlTypeVoice,
    HCDPlayerControlTypeLight,
} HCDPlayerControlType;

@interface HCDPlayerViewController ()<DLNADelegate, GCDWebDAVServerDelegate, RemoteControlViewDelegate> {
    BOOL restorePlay;
    BOOL animatingHUD;
    NSTimeInterval showHUDTime;
    
    CGFloat _moviePosition;
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

@property (nonatomic, strong) HCDPlayer *player;
@property (nonatomic, strong) UIActivityIndicatorView *aivBuffering;

@property (nonatomic, weak) UIView *vTopBar;
@property (nonatomic, weak) UILabel *lblTitle;
@property (nonatomic, weak) UIView *vBottomBar;
@property (nonatomic, weak) UIButton *btnPlay;
@property (nonatomic, weak) UILabel *lblPosition;
@property (nonatomic, weak) UILabel *lblDuration;
@property (nonatomic, weak) UISlider *sldPosition;
@property (nonatomic, weak) UIButton *btnFull;
@property (nonatomic, weak) UIButton *btnClose;
@property (nonatomic, weak) UIButton *btnAirplay;
@property (nonatomic, weak) UIButton *btnLock;

@property (nonatomic) BOOL landscape;
@property (nonatomic) BOOL locked;

@property (nonatomic) UITapGestureRecognizer *grTap;
@property (nonatomic) UITapGestureRecognizer *dgrTap;
@property (nonatomic) UIPanGestureRecognizer *panGesture;

@property (nonatomic, assign) HCDPlayerControlType controlType;
@property (nonatomic, strong) HcdPlayerDraggingProgressView *draggingProgressView;
@property (nonatomic, strong) HcdBrightnessProgressView *brightnessProgressView;
@property (nonatomic, strong) HcdSoundProgressView *soundProgressView;

@property (nonatomic) dispatch_source_t timer;
@property (nonatomic) BOOL updateHUD;
@property (nonatomic) NSTimer *timerForHUD;

@property (nonatomic, readwrite) HCDPlayerStatus status;
@property (nonatomic) HCDPlayerOperation nextOperation;

@property (nonatomic, strong) MPVolumeView   *volumeView;             //音量控制控件
@property (nonatomic, strong) UISlider       *volumeSlider;           //用这个来控制音量
@property (nonatomic, assign) float          outputVolume;            //音量

@property (nonatomic, strong) RemoteControlView *dlnaControlView;
/**
 * DLNA manager
 */
@property (nonatomic, strong) MRDLNA *dlnaManager;

/**
 * 附近支持DLNA的设备
 */
@property (nonatomic, strong) NSArray *deviceArr;

/**
 * 服务器
 */
@property (nonatomic, strong) GCDWebDAVServer* davServer;

@end

@implementation HCDPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initAll];
    // auto play
    [self play];
    
    self.landscape = self.view.frame.size.width > self.view.frame.size.height;
    
    // 添加到播放记录中
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *relativePath = [self.url mutableCopy];
    relativePath = [relativePath  stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    relativePath = [relativePath stringByReplacingOccurrencesOfString:documentPath withString:@""];
    [[HcdAppManager sharedInstance] addPathToPlaylist:relativePath];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 不自动锁屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [HcdAppManager sharedInstance].isAllowAutorotate = YES;
    [self registerNotification];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [HcdAppManager sharedInstance].isAllowAutorotate = NO;
    [self unregisterNotification];
    [self close];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self showHUD];
}

- (void)dealloc {
    [self pause];
    
    [self.davServer stop];
    self.davServer = nil;
    
    [self.dlnaManager endDLNA];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)registerNotification {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(notifyAppDidEnterBackground:)
               name:UIApplicationDidEnterBackgroundNotification object:nil];
    [nc addObserver:self selector:@selector(notifyAppWillEnterForeground:)
               name:UIApplicationWillEnterForegroundNotification object:nil];
    [nc addObserver:self selector:@selector(notifyPlayerOpened:) name:HCDPlayerNotificationOpened object:self.player];
    [nc addObserver:self selector:@selector(notifyPlayerClosed:) name:HCDPlayerNotificationClosed object:self.player];
    [nc addObserver:self selector:@selector(notifyPlayerEOF:) name:HCDPlayerNotificationEOF object:self.player];
    [nc addObserver:self selector:@selector(notifyPlayerBufferStateChanged:) name:HCDPlayerNotificationBufferStateChanged object:self.player];
    [nc addObserver:self selector:@selector(notifyPlayerError:) name:HCDPlayerNotificationError object:self.player];
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    float volume = session.outputVolume;
    [session setActive:YES error:nil];
    self.outputVolume = volume;
    self.soundProgressView.progress = volume;
    [nc addObserver:self selector:@selector(notifyVolumeChanged:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
}

- (void)unregisterNotification {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
}

#pragma mark - Init
- (void)initAll {
    [self initPlayer];
    [self initDLNAManager];
    [self initGCDWebServer];
    [self initTopBar];
    [self initBottomBar];
    [self initBuffering];
    [self initLock];
    [self initDraggingProgressView];
    [self initSoundView];
    [self initBrightnessView];
    [self initGestures];
    self.status = HCDPlayerStatusNone;
    self.nextOperation = HCDPlayerOperationNone;
}

- (void)onPlayButtonTapped:(id)sender {
    if (self.player.playing) {
        [self pause];
    } else {
        [self play];
    }
}

- (void)onFullButtonTapped:(id)sender {
    if (_landscape) {
        [self setInterfaceOrientation:UIInterfaceOrientationPortrait];
    } else {
        [self setInterfaceOrientation:UIInterfaceOrientationLandscapeRight];
    }
}

- (void)onCloseButtonTapped:(id)sender {
    if (IS_PAD) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    if (_landscape) {
        [self setInterfaceOrientation:UIInterfaceOrientationPortrait];
        return;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onLockButtonTapped {
    self.locked = !self.locked;
    [self setDevivceLocked:self.locked];
    if (self.locked) {
        [self hideHUD];
    } else {
        [self showHUD];
    }
}

- (void)onAirplayButtonTapped {
    
    // 锁屏
    self.locked = YES;
    [self setDevivceLocked:self.locked];
    
    // 暂停播放
    [self pause];

    if (!self.deviceArr || self.deviceArr.count == 0) {
        [self.dlnaManager startSearch];
    }

    NSMutableArray *deviceNameArr = [NSMutableArray array];
    for (CLUPnPDevice *device in self.deviceArr) {
        [deviceNameArr addObject:device.friendlyName];
    }

    HcdPopSelectView *selectDeviceView = [[HcdPopSelectView alloc] initWithDataArray:deviceNameArr title:@"请选择要投屏的设备"];

    selectDeviceView.seletedIndex = ^(NSInteger index) {
        
        CLUPnPDevice *device = [self.deviceArr objectAtIndex:index];
        self.dlnaControlView.deviceLbl.text = device.friendlyName;
        [self.dlnaManager endDLNA];
        self.dlnaManager.device = device;
        self.dlnaManager.playUrl = [NSString stringWithFormat:@"%@video.mov", self.davServer.serverURL.absoluteString];
        [self.dlnaManager startDLNA];
    };

    [[UIApplication sharedApplication].keyWindow addSubview:selectDeviceView];
    [selectDeviceView show];
}

- (void)onSliderStartSlide:(id)sender {
    self.updateHUD = NO;
    self.grTap.enabled = NO;
}

- (void)onSliderValueChanged:(id)sender {
    UISlider *slider = sender;
    int seconds = slider.value;
    self.lblPosition.text = [HCDPlayerUtils durationStringFromSeconds:seconds];
}

- (void)onSliderEndSlide:(id)sender {
    UISlider *slider = sender;
    float position = slider.value;
    [self setPlayerPosition:position];
}

- (void)syncHUD {
    [self syncHUD:NO];
}

- (void)syncHUD:(BOOL)force {
    if (!force) {
        if (self.vTopBar.hidden) return;
        if (!self.player.playing) return;
        if (!self.updateHUD) return;
    }
    
    // position
    double position = self.player.position;
    int seconds = ceil(position);
    self.lblPosition.text = [HCDPlayerUtils durationStringFromSeconds:seconds];
    self.sldPosition.value = seconds;
}

- (void)open {
    if (self.status == HCDPlayerStatusClosing) {
        self.nextOperation = HCDPlayerOperationOpen;
        return;
    }
    if (self.status != HCDPlayerStatusNone &&
        self.status != HCDPlayerStatusClosed) {
        return;
    }
    self.status = HCDPlayerStatusOpening;
    self.aivBuffering.hidden = NO;
    [self.aivBuffering startAnimating];
    [self.player open:self.url];
}

- (void)close {
    if (self.status == HCDPlayerStatusOpening) {
        self.nextOperation = HCDPlayerOperationClose;
        return;
    }
    self.status = HCDPlayerStatusClosing;
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [self.player close];
//    [self.btnPlay setTitle:@"|>" forState:UIControlStateNormal];
    [self.btnPlay setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_play"] forState:UIControlStateNormal];
    [self.btnPlay setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_play_hl"] forState:UIControlStateHighlighted];
}

- (void)play {
    if (self.status == HCDPlayerStatusNone ||
        self.status == HCDPlayerStatusClosed) {
        [self open];
        self.nextOperation = HCDPlayerOperationPlay;
    }
    if (self.status != HCDPlayerStatusOpened &&
        self.status != HCDPlayerStatusPaused &&
        self.status != HCDPlayerStatusEOF) {
        return;
    }
    self.status = HCDPlayerStatusPlaying;
    [UIApplication sharedApplication].idleTimerDisabled = self.preventFromScreenLock;
    [self.player play];
//    [self.btnPlay setTitle:@"||" forState:UIControlStateNormal];
    [self.btnPlay setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_pause"] forState:UIControlStateNormal];
    [self.btnPlay setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_pause"] forState:UIControlStateHighlighted];
}

- (void)replay {
    self.player.position = 0;
    [self play];
}

- (void)pause {
    if (self.status != HCDPlayerStatusOpened &&
        self.status != HCDPlayerStatusPlaying &&
        self.status != HCDPlayerStatusEOF) {
        return;
    }
    self.status = HCDPlayerStatusPaused;
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [self.player pause];
//    [self.btnPlay setTitle:@"|>" forState:UIControlStateNormal];
    [self.btnPlay setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_play"] forState:UIControlStateNormal];
    [self.btnPlay setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_play_hl"] forState:UIControlStateHighlighted];
}

- (BOOL)doNextOperation {
    if (self.nextOperation == HCDPlayerOperationNone) return NO;
    switch (self.nextOperation) {
        case HCDPlayerOperationOpen:
            [self open];
            break;
        case HCDPlayerOperationPlay:
            [self play];
            break;
        case HCDPlayerOperationPause:
            [self pause];
            break;
        case HCDPlayerOperationClose:
            [self close];
            break;
        default:
            break;
    }
    self.nextOperation = HCDPlayerOperationNone;
    return YES;
}

- (void)setDevivceLocked:(BOOL)locked {
    [HcdAppManager sharedInstance].isLocked = locked;
    if (locked) {
        [self.btnLock setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_lock"] forState:UIControlStateNormal];
    } else {
        [self.btnLock setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_unlock"] forState:UIControlStateNormal];
    }
}

#pragma mark - Notifications
- (void)notifyAppDidEnterBackground:(NSNotification *)notif {
    if (self.player.playing) {
        [self pause];
        if (self.restorePlayAfterAppEnterForeground) restorePlay = YES;
    }
}

- (void)notifyAppWillEnterForeground:(NSNotification *)notif {
    if (restorePlay) {
        restorePlay = NO;
        [self play];
    }
}

- (void)notifyPlayerEOF:(NSNotification *)notif {
    self.status = HCDPlayerStatusEOF;
    if (self.repeat) [self replay];
    else [self close];
}

- (void)notifyPlayerClosed:(NSNotification *)notif {
    self.status = HCDPlayerStatusClosed;
    [self.aivBuffering stopAnimating];
    [self destroyTimer];
    [self doNextOperation];
}

- (void)notifyPlayerOpened:(NSNotification *)notif {
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.aivBuffering stopAnimating];
    });
    
    self.status = HCDPlayerStatusOpened;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }

        NSString *title = nil;
        if (strongSelf.player.metadata != nil) {
            NSString *t = strongSelf.player.metadata[@"title"];
            NSString *a = strongSelf.player.metadata[@"artist"];
            if (t != nil) title = t;
            if (a != nil) title = [title stringByAppendingFormat:@" - %@", a];
        }
        if (title == nil) title = [strongSelf.url lastPathComponent];
        title = [title stringByRemovingPercentEncoding];

        strongSelf.lblTitle.text = title;
        double duration = strongSelf.player.duration;
        int seconds = ceil(duration);
        strongSelf.lblDuration.text = [HCDPlayerUtils durationStringFromSeconds:seconds];
        strongSelf.sldPosition.enabled = seconds > 0;
        strongSelf.sldPosition.maximumValue = seconds;
        strongSelf.sldPosition.minimumValue = 0;
        strongSelf.sldPosition.value = 0;
        strongSelf.updateHUD = YES;
        [strongSelf createTimer];
        [strongSelf showHUD];
    });

    if (![self doNextOperation]) {
        if (self.autoplay) [self play];
    }
}

- (void)notifyPlayerBufferStateChanged:(NSNotification *)notif {
    NSDictionary *userInfo = notif.userInfo;
    BOOL state = [userInfo[HCDPlayerNotificationBufferStateKey] boolValue];
    if (state) {
        self.status = HCDPlayerStatusBuffering;
        [self.aivBuffering startAnimating];
    } else {
        self.status = HCDPlayerStatusPlaying;
        [self.aivBuffering stopAnimating];
    }
}

- (void)notifyPlayerError:(NSNotification *)notif {
    NSDictionary *userInfo = notif.userInfo;
    NSError *error = userInfo[HCDPlayerNotificationErrorKey];

    if ([error.domain isEqualToString:HCDPlayerErrorDomainDecoder]) {
        __weak typeof(self)weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }

            [strongSelf.aivBuffering stopAnimating];
            strongSelf.status = HCDPlayerStatusNone;
            strongSelf.nextOperation = HCDPlayerOperationNone;
        });

        NSLog(@"Player decoder error: %@", error);
    } else if ([error.domain isEqualToString:HCDPlayerErrorDomainAudioManager]) {
        NSLog(@"Player audio error: %@", error);
        // I am not sure what will cause the audio error,
        // if it happens, please issue to me
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:HCDPlayerNotificationError object:self userInfo:notif.userInfo];
}

- (void)notifyVolumeChanged:(NSNotification *)notif {
    float volume = [[[notif userInfo] objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
    if (self.outputVolume != volume) {
        [self.soundProgressView show];
        self.soundProgressView.progress = volume;
        self.outputVolume = volume;
    }
}

#pragma mark - UI
- (void)initPlayer {
    self.player = [[HCDPlayer alloc] init];
    UIView *v = self.player.playerView;
    v.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:v];
    
    // Add constraints
    NSDictionary *views = NSDictionaryOfVariableBindings(v);
    NSArray<NSLayoutConstraint *> *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[v]|"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:views];
    [self.view addConstraints:ch];
    NSArray<NSLayoutConstraint *> *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[v]|"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:views];
    [self.view addConstraints:cv];
}

- (void)initDLNAManager {
    self.dlnaManager = [MRDLNA sharedMRDLNAManager];
    self.dlnaManager.delegate = self;
    
    [self.dlnaManager startSearch];
}

/**
 开启服务器
 */
- (void)initGCDWebServer {
    __weak typeof(self) weakSelf = self;
    NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    self.davServer = [[GCDWebDAVServer alloc] initWithUploadDirectory:documentsPath];
    self.davServer.delegate =  self;
    [self.davServer addHandlerForMethod:@"GET" pathRegex:@"/video.mov" requestClass:[GCDWebServerRequest class] asyncProcessBlock:^(__kindof GCDWebServerRequest * _Nonnull request, GCDWebServerCompletionBlock  _Nonnull completionBlock) {
        NSString *path = [weakSelf.url stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        GCDWebServerFileResponse *res = [GCDWebServerFileResponse responseWithFile:path byteRange:request.byteRange];
        completionBlock(res);
    }];
    [self.davServer start];
}

- (void)initBuffering {
    UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    aiv.translatesAutoresizingMaskIntoConstraints = NO;
    aiv.hidesWhenStopped = YES;
    [self.view addSubview:aiv];
    
    UIView *view = self.view;
    
    // Add constraints
    NSLayoutConstraint *cx = [NSLayoutConstraint constraintWithItem:aiv
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1
                                                           constant:0];
    NSLayoutConstraint *cy = [NSLayoutConstraint constraintWithItem:aiv
                                                          attribute:NSLayoutAttributeCenterY
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:view
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:1
                                                           constant:0];
    [self.view addConstraints:@[cx, cy]];
    self.aivBuffering = aiv;
}

- (void)initLock {
    UIButton *lockBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    lockBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [lockBtn setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_unlock"] forState:UIControlStateNormal];
    [lockBtn addTarget:self action:@selector(onLockButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    lockBtn.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    lockBtn.layer.cornerRadius = 16;
    lockBtn.clipsToBounds = YES;
    [self.view addSubview:lockBtn];
    
    UIButton *closeBtn = self.btnClose;
    
    NSDictionary *views = NSDictionaryOfVariableBindings(lockBtn, closeBtn);
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[lockBtn(==32)]"
                                                          options:0
                                                          metrics:nil
                                                            views:views];

    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[lockBtn(==32)]"
                                                          options:0
                                                          metrics:nil
                                                            views:views];
    
    NSLayoutConstraint *cy = [NSLayoutConstraint constraintWithItem:lockBtn
                                               attribute:NSLayoutAttributeCenterY
                                               relatedBy:NSLayoutRelationEqual
                                                  toItem:self.view
                                               attribute:NSLayoutAttributeCenterY
                                              multiplier:1
                                                constant:0];
    
    NSLayoutConstraint *cx = [NSLayoutConstraint constraintWithItem:lockBtn
                                                          attribute:NSLayoutAttributeLeft
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:closeBtn
                                                          attribute:NSLayoutAttributeLeft
                                                         multiplier:1
                                                           constant:8];
    
    
    [self.view addConstraints:ch];
    [self.view addConstraints:cv];
    [self.view addConstraint:cx];
    [self.view addConstraint:cy];
    
    self.btnLock = lockBtn;
}

- (void)initDraggingProgressView {
    HcdPlayerDraggingProgressView *progressView = [HcdPlayerDraggingProgressView new];
    progressView.hidden = YES;
    progressView.translatesAutoresizingMaskIntoConstraints = NO;
    progressView.layer.cornerRadius = 8;
    [self.view addSubview:progressView];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(progressView);
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[progressView(==150)]"
                                                          options:0
                                                          metrics:nil
                                                            views:views];

    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[progressView(==80)]"
                                                          options:0
                                                          metrics:nil
                                                            views:views];
    
    NSLayoutConstraint *cx = [NSLayoutConstraint constraintWithItem:progressView
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1
                                                           constant:0];
    
    NSLayoutConstraint *cy = [NSLayoutConstraint constraintWithItem:progressView
                                                          attribute:NSLayoutAttributeCenterY
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:1
                                                           constant:0];
    [self.view addConstraints:@[cx, cy]];
    [self.view addConstraints:ch];
    [self.view addConstraints:cv];
    self.draggingProgressView = progressView;
}

- (void)initSoundView {
    HcdSoundProgressView *soundView = [HcdSoundProgressView getInstance];
    soundView.layer.cornerRadius = 16;
    soundView.translatesAutoresizingMaskIntoConstraints = NO;
    soundView.hidden = YES;

    [self.view addSubview:soundView];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(soundView);
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[soundView(==32)]"
                                                          options:0
                                                          metrics:nil
                                                            views:views];

    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[soundView(==140)]"
                                                          options:0
                                                          metrics:nil
                                                            views:views];
    
    NSLayoutConstraint *cx = [NSLayoutConstraint constraintWithItem:soundView
                                                          attribute:NSLayoutAttributeRight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.btnFull
                                                          attribute:NSLayoutAttributeRight
                                                         multiplier:1
                                                           constant:-kBasePadding];
    
    NSLayoutConstraint *cy = [NSLayoutConstraint constraintWithItem:soundView
                                                          attribute:NSLayoutAttributeCenterY
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:1
                                                           constant:0];
    [self.view addConstraints:@[cx, cy]];
    [self.view addConstraints:ch];
    [self.view addConstraints:cv];
    
    self.soundProgressView = soundView;
}

- (void)initBrightnessView {
    HcdBrightnessProgressView *brightnessView = [[HcdBrightnessProgressView alloc] initWithFrame:CGRectMake(kBasePadding, (kScreenHeight - 140) / 2, 32, 140)];
    brightnessView.translatesAutoresizingMaskIntoConstraints = NO;
    brightnessView.layer.cornerRadius = 16;
    brightnessView.hidden = YES;
    [self.view addSubview:brightnessView];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(brightnessView);
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[brightnessView(==32)]"
                                                          options:0
                                                          metrics:nil
                                                            views:views];

    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[brightnessView(==140)]"
                                                          options:0
                                                          metrics:nil
                                                            views:views];
    
    NSLayoutConstraint *cx = [NSLayoutConstraint constraintWithItem:brightnessView
                                                          attribute:NSLayoutAttributeLeft
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.btnPlay
                                                          attribute:NSLayoutAttributeLeft
                                                         multiplier:1
                                                           constant:kBasePadding];
    
    NSLayoutConstraint *cy = [NSLayoutConstraint constraintWithItem:brightnessView
                                                          attribute:NSLayoutAttributeCenterY
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:1
                                                           constant:0];
    [self.view addConstraints:@[cx, cy]];
    [self.view addConstraints:ch];
    [self.view addConstraints:cv];
    
    self.brightnessProgressView = brightnessView;
}

- (void)initTopBar {
    CGRect frame = self.view.bounds;
    CGFloat height = kNavHeight;
    frame.size.height = height;
    UIView *v = [[UIView alloc] initWithFrame:frame];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    [self.view addSubview:v];
    NSDictionary *views = NSDictionaryOfVariableBindings(v);
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[v]|"
                                                          options:0
                                                          metrics:nil
                                                            views:views];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|[v(==%f)]", height]
                                                          options:0
                                                          metrics:nil
                                                            views:views];
    [self.view addConstraints:ch];
    [self.view addConstraints:cv];
    
    // Title Label
    UILabel *lbltitle = [[UILabel alloc] init];
    lbltitle.translatesAutoresizingMaskIntoConstraints = NO;
    lbltitle.backgroundColor = [UIColor clearColor];
    lbltitle.text = @"";
    lbltitle.font = [UIFont systemFontOfSize:15];
    lbltitle.textColor = [UIColor whiteColor];
    lbltitle.textAlignment = NSTextAlignmentCenter;
    [v addSubview:lbltitle];
    views = NSDictionaryOfVariableBindings(lbltitle);
    cv = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%f-[lbltitle]|", kStatusBarHeight] options:0 metrics:nil views:views];
    [v addConstraints:cv];
    
    // Close Button
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.translatesAutoresizingMaskIntoConstraints = NO;
    closeBtn.backgroundColor = [UIColor clearColor];
//    [button setTitle:@"|>" forState:UIControlStateNormal];
    [closeBtn setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_close"] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(onCloseButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [v addSubview:closeBtn];
    views = NSDictionaryOfVariableBindings(closeBtn);
    cv = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%f-[closeBtn]|", kStatusBarHeight] options:0 metrics:nil views:views];
    [v addConstraints:cv];
    
    // Airplay Button
    UIButton *airplayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    airplayBtn.translatesAutoresizingMaskIntoConstraints = NO;
    airplayBtn.backgroundColor = [UIColor clearColor];
    [airplayBtn setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_tv"] forState:UIControlStateNormal];
    [airplayBtn addTarget:self action:@selector(onAirplayButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [v addSubview:airplayBtn];
    views = NSDictionaryOfVariableBindings(airplayBtn);
    cv = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%f-[airplayBtn]|", kStatusBarHeight] options:0 metrics:nil views:views];
    [v addConstraints:cv];
    
    NSString *path = [[self.url mutableCopy] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    FileType fileType = [[HcdFileManager sharedHcdFileManager] getFileTypeByPath:path];
    if (fileType != FileType_video) {
        airplayBtn.hidden = YES;
    }
    
    views = NSDictionaryOfVariableBindings(closeBtn, lbltitle, airplayBtn);
    ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[closeBtn(==32)]-[lbltitle]-[airplayBtn(==32)]-|"
                                                 options:0
                                                 metrics:nil
                                                   views:views];
    [v addConstraints:ch];
    
    self.vTopBar = v;
    self.lblTitle = lbltitle;
    self.btnClose = closeBtn;
    self.btnAirplay = airplayBtn;
}

- (void)initBottomBar {
    CGFloat height = 44 + kTabbarSafeBottomMargin;
    CGRect frame = self.view.bounds;
    frame.size.height = height;
    UIView *v = [[UIView alloc] initWithFrame:frame];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    [self.view addSubview:v];
    NSDictionary *views = NSDictionaryOfVariableBindings(v);
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[v]|"
                                                          options:0
                                                          metrics:nil
                                                            views:views];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[v(==%f)]|", height]
                                                          options:0
                                                          metrics:nil
                                                            views:views];
    [self.view addConstraints:ch];
    [self.view addConstraints:cv];
    
    // Play/Pause Button
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.backgroundColor = [UIColor clearColor];
//    [button setTitle:@"|>" forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_play"] forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_play_hl"] forState:UIControlStateHighlighted];
    [button addTarget:self action:@selector(onPlayButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [v addSubview:button];
    views = NSDictionaryOfVariableBindings(button);
    cv = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|[button]-%f-|", kTabbarSafeBottomMargin] options:0 metrics:nil views:views];
    [v addConstraints:cv];
    
    // Position Label
    UILabel *lblpos = [[UILabel alloc] init];
    lblpos.translatesAutoresizingMaskIntoConstraints = NO;
    lblpos.backgroundColor = [UIColor clearColor];
    lblpos.text = @"--:--:--";
    lblpos.font = [UIFont systemFontOfSize:15];
    lblpos.textColor = [UIColor whiteColor];
    lblpos.textAlignment = NSTextAlignmentCenter;
    [v addSubview:lblpos];
    views = NSDictionaryOfVariableBindings(lblpos);
    cv = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|[lblpos]-%f-|", kTabbarSafeBottomMargin] options:0 metrics:nil views:views];
    [v addConstraints:cv];
    
    UISlider *sldpos = [[UISlider alloc] init];
    sldpos.translatesAutoresizingMaskIntoConstraints = NO;
    sldpos.backgroundColor = [UIColor clearColor];
    sldpos.minimumTrackTintColor = kMainColor;
    sldpos.maximumTrackTintColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
    sldpos.continuous = YES;
    [sldpos addTarget:self action:@selector(onSliderStartSlide:) forControlEvents:UIControlEventTouchDown];
    [sldpos addTarget:self action:@selector(onSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [sldpos addTarget:self action:@selector(onSliderEndSlide:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    [sldpos setThumbImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_progress"] forState:UIControlStateNormal];
    [v addSubview:sldpos];
    views = NSDictionaryOfVariableBindings(sldpos);
    cv = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|[sldpos]-%f-|", kTabbarSafeBottomMargin] options:0 metrics:nil views:views];
    [v addConstraints:cv];
    
    UILabel *lblduration = [[UILabel alloc] init];
    lblduration.translatesAutoresizingMaskIntoConstraints = NO;
    lblduration.backgroundColor = [UIColor clearColor];
    lblduration.text = @"--:--:--";
    lblduration.font = [UIFont systemFontOfSize:15];
    lblduration.textColor = [UIColor whiteColor];
    lblduration.textAlignment = NSTextAlignmentCenter;
    [v addSubview:lblduration];
    views = NSDictionaryOfVariableBindings(lblduration);
    cv = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|[lblduration]-%f-|", kTabbarSafeBottomMargin] options:0 metrics:nil views:views];
    [v addConstraints:cv];
    
    // Enter full or exit full button
    UIButton *fullBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    fullBtn.translatesAutoresizingMaskIntoConstraints = NO;
    fullBtn.backgroundColor = [UIColor clearColor];
//    [button setTitle:@"|>" forState:UIControlStateNormal];
    [fullBtn setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_fullscreen"] forState:UIControlStateNormal];
    [fullBtn addTarget:self action:@selector(onFullButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [v addSubview:fullBtn];
    views = NSDictionaryOfVariableBindings(fullBtn);
    cv = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|[fullBtn]-%f-|", kTabbarSafeBottomMargin] options:0 metrics:nil views:views];
    [v addConstraints:cv];
    
    views = NSDictionaryOfVariableBindings(button, lblpos, sldpos, lblduration, fullBtn);
    ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[button(==32)]-[lblpos(==72)]-[sldpos]-[lblduration(==72)]-[fullBtn(==32)]-|"
                                                 options:0
                                                 metrics:nil
                                                   views:views];
    [v addConstraints:ch];
    
    self.vBottomBar = v;
    self.btnPlay = button;
    self.lblPosition = lblpos;
    self.sldPosition = sldpos;
    self.lblDuration = lblduration;
    self.btnFull = fullBtn;
}

- (void)initGestures {
    
    // double tap gesture
    UITapGestureRecognizer *dTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapGesutreRecognizer:)];
    dTap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:dTap];
    self.dgrTap = dTap;
    
    // single tap gesture
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapGesutreRecognizer:)];
    tap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tap];
    self.grTap = tap;
    
    // pan gesture
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanGesutreRecognizer:)];
    pan.enabled = YES;
    [self.view addGestureRecognizer:pan];
    self.panGesture = pan;
}

#pragma mark - Show/Hide HUD
- (void)showHUD {
    if (animatingHUD) return;

    [self syncHUD:YES];
    animatingHUD = YES;
    if (!self.locked) {
        self.vTopBar.hidden = NO;
        self.vBottomBar.hidden = NO;
    }
    
    self.btnLock.hidden = NO;

    __weak typeof(self)weakSelf = self;
    [UIView animateWithDuration:0.5f
                     animations:^{
                         __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!self.locked) {
            strongSelf.vTopBar.alpha = 1.0f;
            strongSelf.vBottomBar.alpha = 1.0f;
        }
                         strongSelf.btnLock.alpha = 1.0f;
                     }
                     completion:^(BOOL finished) {
                         animatingHUD = NO;
                     }];
    [self startTimerForHideHUD];
}

- (void)hideHUD {
    if (animatingHUD) return;
    animatingHUD = YES;

    __weak typeof(self)weakSelf = self;
    [UIView animateWithDuration:0.5f
                     animations:^{
                         __strong typeof(weakSelf)strongSelf = weakSelf;
                         strongSelf.vTopBar.alpha = 0.0f;
                         strongSelf.vBottomBar.alpha = 0.0f;
                         strongSelf.btnLock.alpha = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         __strong typeof(weakSelf)strongSelf = weakSelf;

                         strongSelf.vTopBar.hidden = YES;
                         strongSelf.vBottomBar.hidden = YES;
                         strongSelf.btnLock.hidden = YES;

                         animatingHUD = NO;
                     }];
    [self stopTimerForHideHUD];
}

#pragma mark - Timer
- (void)startTimerForHideHUD {
    [self updateTimerForHideHUD];
    if (self.timerForHUD != nil) return;
    self.timerForHUD = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(timerForHideHUD:) userInfo:nil repeats:YES];
}

- (void)stopTimerForHideHUD {
    if (self.timerForHUD == nil) return;
    [self.timerForHUD invalidate];
    self.timerForHUD = nil;
}

- (void)updateTimerForHideHUD {
    showHUDTime = [NSDate timeIntervalSinceReferenceDate];
}

- (void)timerForHideHUD:(NSTimer *)timer {
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    if (now - showHUDTime > 5) {
        [self hideHUD];
        [self stopTimerForHideHUD];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    BOOL isLandscape = size.width > size.height;
    [coordinator animateAlongsideTransition:nil
                                 completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                                     self.landscape = isLandscape;
                                 }];
}

#pragma mark - Setter
- (void)setLandscape:(BOOL)landscape {
    _landscape = landscape;
    [self updatePlayerFrame];
}

#pragma mark - Update Player Frame
- (void)updatePlayerFrame {
    if (_landscape) {
        if (IS_PAD) {
            [self.btnClose setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_close"] forState:UIControlStateNormal];
        } else {
            [self.btnClose setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_back"] forState:UIControlStateNormal];
        }
        [self.btnFull setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_fullscreen_exit"] forState:UIControlStateNormal];
    } else {
        [self.btnClose setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_close"] forState:UIControlStateNormal];
        [self.btnFull setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_fullscreen"] forState:UIControlStateNormal];
    }
    
    // 播放音频不显示AirPlay
    self.btnAirplay.hidden = _landscape;
    NSString *path = [[self.url mutableCopy] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    FileType fileType = [[HcdFileManager sharedHcdFileManager] getFileTypeByPath:path];
    if (fileType != FileType_video) {
        self.btnAirplay.hidden = YES;
    }
}

#pragma mark - Gesture
- (void)onTapGesutreRecognizer:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (recognizer == self.grTap) {
            if (self.vTopBar.hidden) [self showHUD];
            else [self hideHUD];
        } else if (recognizer == self.dgrTap) {
            
            if (self.status == HCDPlayerStatusEOF) {
                return;
            }
            
            if (self.status == HCDPlayerStatusPlaying) {
                [self pause];
            } else if (self.status == HCDPlayerStatusPaused) {
                [self play];
            }
        }
    }
}

- (void)onPanGesutreRecognizer:(UITapGestureRecognizer *)recognizer {
    if (self.locked) {
        return;
    }
    
    CGPoint touchPoint = [recognizer locationInView:self.view];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        _hasMoved = NO;
        _controlJudge = NO;
        _touchBeginValue = self.player.position;
        _touchBeginVoiceValue = self.outputVolume;
        _touchBeginLightValue = [UIScreen mainScreen].brightness;
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
                    _controlType = HCDPlayerControlTypeVoice;
                } else {
                    _controlType = HCDPlayerControlTypeLight;
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
        } else if (HCDPlayerControlTypeLight == _controlType) {
            
            CGFloat brightness = [UIScreen mainScreen].brightness;
            brightness -= ((touchPoint.y - _touchBeginPoint.y) / 10000);
            [UIScreen mainScreen].brightness = brightness;
            
            [self.brightnessProgressView show];
            self.brightnessProgressView.progress = brightness;
            
        } else if (HCDPlayerControlTypeVoice == _controlType) {
            self.volumeView.frame = CGRectMake(-1000, -100, 100, 100);
            [self.view addSubview:self.volumeView];
            // 根据触摸开始时的音量和触摸开始时的点去计算出现在滑动到的音量
            float voiceValue = _touchBeginVoiceValue - ((touchPoint.y - _touchBeginPoint.y) / CGRectGetHeight(self.view.frame));
            //判断控制一下, 不能超出 0~1
            if (voiceValue < 0) {
                self.volumeSlider.value = 0;
            } else if(voiceValue > 1) {
                self.volumeSlider.value = 1;
            } else {
                self.volumeSlider.value = voiceValue;
            }
            
            [self.soundProgressView show];
            self.soundProgressView.progress = voiceValue;
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
//                self.draggingProgressView.hidden = YES;
                float value = [self moveProgressControlWithTempPoint:touchPoint];
                [self setPlayerPosition:value];
            } else if (_controlType == HCDPlayerControlTypeLight) {
//                self.brightnessProgressView.hidden = YES;
            } else if (_controlType == HCDPlayerControlTypeVoice) {
//                self.soundProgressView.hidden = YES;
            }
        }
        //LoggerStream(2, @"pan %.2f %.2f %.2f sec", pt.x, vt.x, sc);
    }
}

- (void)createTimer {
    if (self.timer != nil) return;

    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC, 1 * NSEC_PER_SEC);

    __weak typeof(self)weakSelf = self;
    dispatch_source_set_event_handler(timer, ^{
        [weakSelf syncHUD];
    });
    dispatch_resume(timer);
    self.timer = timer;
}

- (void)destroyTimer {
    if (self.timer == nil) return;
    
    dispatch_cancel(self.timer);
    self.timer = nil;
}

- (BOOL)shouldAutorotate {

    return !self.locked;
}

#pragma mark - private
- (float)moveProgressControlWithTempPoint:(CGPoint)tempPoint {
    float tempValue = _touchBeginValue + 90 * ((tempPoint.x - _touchBeginPoint.x) / kScreenWidth);
    if (tempValue > self.player.duration) {
        tempValue = self.player.duration;
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
    
#if DEBUG
    NSLog(@"_touchBeginValue:%f value:%f", _touchBeginValue, value);
#endif
    
    CGFloat duration = self.player.duration;
    self.draggingProgressView.durationTimeLabel.text = [HCDPlayerUtils durationStringFromSeconds:duration];
    self.draggingProgressView.shiftTimeLabel.text = [HCDPlayerUtils durationStringFromSeconds:value];
    [self.draggingProgressView show];
}

- (void)setPlayerPosition: (float)position {
    self.player.position = position;
    self.updateHUD = YES;
    self.grTap.enabled = YES;
}

#pragma mark - lazy load
- (MPVolumeView *)volumeView {
    if (!_volumeView) {
        _volumeView = [[MPVolumeView alloc] init];
        _volumeView.hidden = NO;
        [_volumeView setShowsRouteButton:YES];
        [_volumeView setFrame:CGRectMake(-100, -100, 40, 40)];
        [_volumeView setShowsVolumeSlider:YES];
        for (UIView * view in _volumeView.subviews) {
            if ([NSStringFromClass(view.class) isEqualToString:@"MPVolumeSlider"]) {
                self.volumeSlider = (UISlider *)view;
                break;
            }
        }
    }
    return _volumeView;
}

- (RemoteControlView *)dlnaControlView {
    if (!_dlnaControlView) {
        _dlnaControlView = [[RemoteControlView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
        _dlnaControlView.delegate = self;
    }
    return _dlnaControlView;
}

#pragma mark - RemoteControlViewDelegate

- (void)didClickChangeDevice {
    
    [self onAirplayButtonTapped];
}

- (void)didClickQuitDLNAPlay {
    // 停止endDLNA播放
    [self.dlnaManager endDLNA];
    // 隐藏播放控制界面
    [self.dlnaControlView hide];
    
    // 重新开始播放
    if (self.status == HCDPlayerStatusEOF) {
        [self replay];
    } else {
        [self play];
    }
}

#pragma mark - DLNADelegate

- (void)searchDLNAResult:(NSArray *)devicesArray {
    self.deviceArr = [[NSArray alloc] initWithArray:devicesArray];
}

- (void)dlnaStartPlay {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // dlna开始播放了回调
        [self.dlnaControlView show];
    });
    
}

#pragma mark - other
- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
