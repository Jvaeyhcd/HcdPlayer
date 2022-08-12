//
//  CDFFmpegViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2020/7/10.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import "CDFFmpegViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import "HcdAppManager.h"
#import "HcdFileManager.h"
#import "HcdPlayerDraggingProgressView.h"
#import "HcdBrightnessProgressView.h"
#import "HcdSoundProgressView.h"
#import "MRDLNA.h"
#import <GCDWebServer/GCDWebDAVServer.h>
#import <GCDWebServer/GCDWebServerFileResponse.h>
#import "HcdActionSheet.h"
#import "HcdPopSelectView.h"
#import "RemoteControlView.h"
#import "GadientLayerView.h"
#import "HCDPlayerUtils.h"
#import "DNLAViewController.h"
#import "PlaylistModelDao.h"

typedef enum : NSUInteger {
    HCDPlayerControlTypeNone,
    HCDPlayerControlTypeProgress,
    HCDPlayerControlTypeVoice,
    HCDPlayerControlTypeLight,
} HCDPlayerControlType;

@interface CDFFmpegViewController ()<CDFFmpegPlayerDelegate, CDFFmpegControlDelegate, DLNADelegate, GCDWebDAVServerDelegate>
{
    NSArray *_localMovies;
    NSArray *_remoteMovies;
    
    //记录触摸开始时的视频播放的时间
    float _touchBeginValue;
    //记录触摸开始亮度
    float _touchBeginLightValue;
    //记录触摸开始的音量
    float _touchBeginVoiceValue;
    //当前播放的进度，手势快进的时候记录当前播放的进度
    CGFloat _currentProgress;
}

@property (nonatomic, weak) GadientLayerView *vTopBar;
@property (nonatomic, weak) UILabel *lblTitle;
@property (nonatomic, weak) GadientLayerView *vBottomBar;
@property (nonatomic, weak) UIButton *btnPlay;
@property (nonatomic, weak) UILabel *lblPosition;
@property (nonatomic, weak) UILabel *lblDuration;
@property (nonatomic, weak) UISlider *sldPosition;
@property (nonatomic, weak) UIButton *btnFull;
@property (nonatomic, weak) UIButton *btnClose;
@property (nonatomic, weak) UIButton *btnAirplay;
@property (nonatomic, weak) UIButton *btnLock;

@property (nonatomic, assign) HCDPlayerControlType controlType;
@property (nonatomic, strong) HcdPlayerDraggingProgressView *draggingProgressView;
@property (nonatomic, strong) HcdBrightnessProgressView *brightnessProgressView;
@property (nonatomic, strong) HcdSoundProgressView *soundProgressView;

@property (nonatomic) dispatch_source_t timer;
@property (nonatomic) BOOL updateHUD;
@property (nonatomic) NSTimer *timerForHUD;

@property (nonatomic, assign) BOOL restorePlay;
@property (nonatomic, assign) BOOL animatingHUD;
@property (nonatomic, assign) NSTimeInterval showHUDTime;

@property (nonatomic) BOOL landscape;
@property (nonatomic) BOOL locked;
@property (nonatomic) CGFloat statusBarHeight;
@property (nonatomic, strong) CDFFmpegPlayer *player;

/// 是否正在拖动进度条
@property (nonatomic, assign) BOOL isDraggingSlider;

@property (nonatomic, strong) UIView * contentView;

@property (nonatomic, strong) MPVolumeView   *volumeView;             //音量控制控件
@property (nonatomic, strong) UISlider       *volumeSlider;           //用这个来控制音量
@property (nonatomic, assign) float          outputVolume;            //音量

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

@implementation CDFFmpegViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.statusBarHeight = STATUS_BAR_HEIGHT;
    _remoteMovies = @[];
    
    [self initAll];
    
    self.playlistModel.path = self.path;
    
    if (self.playlistModel.position > 0) {
        [self.player setMoviePosition:self.playlistModel.position playMode:NO];
    }
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 不自动锁屏
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    [HcdAppManager sharedInstance].isAllowAutorotate = YES;
    [self registerNotification];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO];
    
    // 恢复自动锁屏
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [HcdAppManager sharedInstance].isAllowAutorotate = NO;
    
    [self unregisterNotification];
    [self pause];
    
    [[PlaylistModelDao sharedPlaylistModelDao] insertOrUpdateData:self.playlistModel];
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [self pause];
    
    [self.davServer stop];
    self.davServer = nil;
    
    [self.dlnaManager endDLNA];
}

- (void)registerNotification {
    
    NSError *error;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:YES error:&error];
    
    self.outputVolume = audioSession.outputVolume;
    self.soundProgressView.progress = audioSession.outputVolume;
    
    [[AVAudioSession sharedInstance] addObserver:self forKeyPath:@"outputVolume" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:(void *)[AVAudioSession sharedInstance]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if(context == (__bridge void *)[AVAudioSession sharedInstance]){
        float newValue = [[change objectForKey:@"new"] floatValue];
        float oldValue = [[change objectForKey:@"old"] floatValue];
        DLog(@"%f-%f", oldValue, newValue);
        self.outputVolume = newValue;
        self.soundProgressView.progress = newValue;
        [self.soundProgressView show];
    }
}

- (void)unregisterNotification {
    [[AVAudioSession sharedInstance] removeObserver:self forKeyPath:@"outputVolume" context:(void *)[AVAudioSession sharedInstance]];
}

- (void)notifyVolumeChanged:(NSNotification *)notif {
    float volume = [[[notif userInfo] objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
    if (self.outputVolume != volume) {
        [self.soundProgressView show];
        self.soundProgressView.progress = volume;
        self.outputVolume = volume;
    }
}

#pragma mark - UI界面的各种初始化

/// 初始化所有内容
- (void)initAll {
    [self initPlayer];
    [self initDLNAManager];
    [self initGCDWebServer];
    [self initTopBar];
    [self initBottomBar];
//    [self initBuffering];
    [self initLock];
    [self initDraggingProgressView];
    [self initSoundView];
    [self initBrightnessView];
//    [self initGestures];
}

- (void)initPlayer {
    
    self.player.control_delegate = self;
    
    UIView * contentView = [UIView new];
    contentView.backgroundColor = [UIColor blackColor];
    self.contentView = contentView;
    [self.view addSubview:contentView];
    [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.bottom.mas_equalTo(0);
    }];
    
    [contentView addSubview:self.player.view];
    
    [self.player.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.bottom.mas_equalTo(0);
    }];
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
    self.davServer.delegate = self;
    [self.davServer addHandlerForMethod:@"GET" pathRegex:@"/video.mov" requestClass:[GCDWebServerRequest class] asyncProcessBlock:^(__kindof GCDWebServerRequest * _Nonnull request, GCDWebServerCompletionBlock  _Nonnull completionBlock) {
        NSString *path = [weakSelf.path stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        GCDWebServerFileResponse *res = [GCDWebServerFileResponse responseWithFile:path byteRange:request.byteRange];
        completionBlock(res);
    }];
    NSMutableDictionary* options = [NSMutableDictionary dictionary];
    [options setObject:@NO forKey:GCDWebServerOption_AutomaticallySuspendInBackground];
    [self.davServer startWithOptions:options error:nil];
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
    GadientLayerView *v = [[GadientLayerView alloc] initWithFrame:frame];
    v.gradientLayer.colors = @[(id)[UIColor colorWithWhite:0 alpha:0.8].CGColor,(id)[UIColor colorWithWhite:0 alpha:0.0].CGColor];
    v.gradientLayer.startPoint = CGPointMake(0, 0);
    v.gradientLayer.endPoint = CGPointMake(0, 1);
    v.translatesAutoresizingMaskIntoConstraints = NO;
//    v.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
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
    
    NSString *path = [[self.path mutableCopy] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
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
    GadientLayerView *v = [[GadientLayerView alloc] initWithFrame:frame];
    v.translatesAutoresizingMaskIntoConstraints = NO;
//    v.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
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

#pragma mark - 各种UI操作事件

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

/**
 * 点击投屏按钮
 */
- (void)onAirplayButtonTapped {
    
    // 不锁屏
    self.locked = NO;
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
        DNLAViewController *dnlaViewController = [[DNLAViewController alloc] init];
        dnlaViewController.device = device;
        dnlaViewController.playUrl = [NSString stringWithFormat:@"%@video.mov", self.davServer.serverURL.absoluteString];
        BaseNavigationController *dnlaNav = [[BaseNavigationController alloc] initWithRootViewController: dnlaViewController];
        dnlaNav.modalPresentationStyle = UIModalPresentationFullScreen;
        [self.player clickedPause:YES];
        [self presentViewController:dnlaNav animated:YES completion:nil];
    };

    [[UIApplication sharedApplication].keyWindow addSubview:selectDeviceView];
    [selectDeviceView show];
    
//    [self hideHUD];
}

- (void)onSliderStartSlide:(id)sender {
    self.isDraggingSlider = YES;
}

- (void)onSliderValueChanged:(id)sender {
    
}

- (void)onSliderEndSlide:(id)sender {
    UISlider *slider = sender;
    CGFloat position = slider.value;
    [self.player setMoviePosition:position playMode:YES];
    self.isDraggingSlider = NO;
}

#pragma mark - CDFFmpegControlDelegate 手势相关

- (void)cdFFmpegPlayer:(CDFFmpegPlayer *)player singleTapped:(CDPlayerGestureControl *)control {
    if (self.vTopBar.hidden) {
        [self showHUD];
    } else {
        [self hideHUD];
    }
}

- (void)cdFFmpegPlayer:(CDFFmpegPlayer *)player doubleTapped:(CDPlayerGestureControl *)control {
    
}

- (void)cdFFmpegPlayer:(CDFFmpegPlayer *)player
              beganPan:(CDPlayerGestureControl *)control
             direction:(CDPanDirection)direction
              location:(CDPanLocation)location {
    
    _touchBeginVoiceValue = self.outputVolume;
    
    switch (direction) {
        case CDPanDirection_H: {
            _currentProgress = self.player.decoder.position / self.player.decoder.duration;
            [self hideHUD];
            break;
        }
        case CDPanDirection_V: {
            break;
        }
        case CDPanDirection_Unknown: {
            break;
        }
            
        default:
            break;
    }
}

- (void)cdFFmpegPlayer:(CDFFmpegPlayer *)player
            changedPan:(CDPlayerGestureControl *)control
             direction:(CDPanDirection)direction
              location:(CDPanLocation)location
             translate:(CGPoint)translate {
    switch (direction) {
        case CDPanDirection_H: {
            // 显示进度
            if (self.player.decoder.duration <= 0) {
                return;
            }
            DLog(@"%f", translate.x);
            [self changePlayingProgress:translate.x * 0.0003];
            break;
        }
        case CDPanDirection_V: {
            switch (location) {
                case CDPanLocation_Left: {
                    self.volumeView.frame = CGRectMake(-1000, -100, 100, 100);
                    // 左边调节声音
                    self.outputVolume = self.outputVolume - translate.y * 0.004;
                    //判断控制一下, 不能超出 0~1
                    if (self.outputVolume < 0) {
                        self.outputVolume = 0;
                    } else if (self.outputVolume > 1) {
                        self.outputVolume = 1;
                    }
                    self.volumeSlider.value = self.outputVolume;
                    self.soundProgressView.progress = self.outputVolume;
                    [self.soundProgressView show];
                    break;
                }
                case CDPanLocation_Right: {
                    // 右边调节亮度
                    CGFloat brightness = [UIScreen mainScreen].brightness - translate.y * 0.004;
                    [UIScreen mainScreen].brightness = brightness;
                    
                    [self.brightnessProgressView show];
                    self.brightnessProgressView.progress = brightness;
                    break;
                }
                default: break;
            }
            break;
        }
        case CDPanDirection_Unknown: {
            break;
        }
            
        default:
            break;
    }
}

- (void)cdFFmpegPlayer:(CDFFmpegPlayer *)player
              endedPan:(CDPlayerGestureControl *)control
             direction:(CDPanDirection)direction
              location:(CDPanLocation)location {
    switch (direction) {
        case CDPanDirection_H: {
            
            CGFloat position = _currentProgress * self.player.decoder.duration;
            [self.player setMoviePosition:position playMode:YES];
            break;
        }
        case CDPanDirection_V: {
            break;
        }
        case CDPanDirection_Unknown: {
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - Show/Hide HUD
- (void)showHUD {
    if (self.animatingHUD) return;

    [self syncHUD:YES];
    self.animatingHUD = YES;
    if (!self.locked) {
        self.vTopBar.hidden = NO;
        self.vBottomBar.hidden = NO;
    }
    
    self.btnLock.hidden = NO;

    __weak typeof(self)weakSelf = self;
    [UIView animateWithDuration:0.5f animations:^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!self.locked) {
            strongSelf.vTopBar.alpha = 1.0f;
            strongSelf.vBottomBar.alpha = 1.0f;
        }
        strongSelf.btnLock.alpha = 1.0f;
    } completion:^(BOOL finished) {
        weakSelf.animatingHUD = NO;
    }];
    [self startTimerForHideHUD];
}

- (void)hideHUD {
    if (self.animatingHUD) return;
    self.animatingHUD = YES;

    __weak typeof(self)weakSelf = self;
    [UIView animateWithDuration:0.5f animations:^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        strongSelf.vTopBar.alpha = 0.0f;
        strongSelf.vBottomBar.alpha = 0.0f;
        if (!self.locked) {
            strongSelf.btnLock.alpha = 0.0f;
        }
    } completion:^(BOOL finished) {
        __strong typeof(weakSelf)strongSelf = weakSelf;

        strongSelf.vTopBar.hidden = YES;
        strongSelf.vBottomBar.hidden = YES;
        if (!self.locked) {
            strongSelf.btnLock.hidden = YES;
        }

        weakSelf.animatingHUD = NO;
    }];
    [self stopTimerForHideHUD];
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
    double position = self.player.currentTime;
    int seconds = ceil(position);
    self.lblPosition.text = [HCDPlayerUtils durationStringFromSeconds:seconds];
    self.sldPosition.value = seconds;
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
    self.showHUDTime = [NSDate timeIntervalSinceReferenceDate];
}

- (void)timerForHideHUD:(NSTimer *)timer {
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    if (now - self.showHUDTime > 5) {
        [self hideHUD];
        [self stopTimerForHideHUD];
    }
}

- (void)setDevivceLocked:(BOOL)locked {
    [HcdAppManager sharedInstance].isLocked = locked;
    if (locked) {
        [self.btnLock setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_lock"] forState:UIControlStateNormal];
    } else {
        [self.btnLock setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_unlock"] forState:UIControlStateNormal];
    }
}

#pragma mark - private

- (void)pause {
    [self.player pause];
}

- (void)play {
    [self.player play];
}

-(void)changePlayingProgress:(float)progress{
    
    if (progress > 0) {
        self.draggingProgressView.directionImageView.image = [UIImage imageNamed:@"hcdplayer.bundle/icon_video_player_fast"];
    } else if (progress < 0) {
        self.draggingProgressView.directionImageView.image = [UIImage imageNamed:@"hcdplayer.bundle/icon_video_player_forward"];
    }
    
    _currentProgress += progress;
    if (_currentProgress > 1) {
        _currentProgress = 1;
    } else if (_currentProgress < 0) {
        _currentProgress = 0;
    }
    
    CGFloat value = _currentProgress * self.player.decoder.duration;
    
#if DEBUG
    DLog(@"_touchBeginValue:%f value:%f", _touchBeginValue, value);
#endif
    
    CGFloat duration = self.player.decoder.duration;
    self.draggingProgressView.durationTimeLabel.text = [HCDPlayerUtils durationStringFromSeconds:duration];
    self.draggingProgressView.shiftTimeLabel.text = [HCDPlayerUtils durationStringFromSeconds:value];
    [self.draggingProgressView show];
}

#pragma mark - 状态栏颜色
- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)shouldAutorotate {
    
    return ![HcdAppManager sharedInstance].isLocked;
}

# pragma mark - 系统横竖屏切换调用

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    BOOL isLandscape = size.width > size.height;

    self.landscape = isLandscape;
    if (isLandscape) {
        [self.player.view mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.top.right.bottom.mas_equalTo(0);
        }];
    } else {
        [self.player.view mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.top.right.bottom.mas_equalTo(0);
        }];
    }
}

- (void)preferredContentSizeDidChangeForChildContentContainer:(nonnull id<UIContentContainer>)container {
    
}

- (void)systemLayoutFittingSizeDidChangeForChildContentContainer:(nonnull id<UIContentContainer>)container {
    
}


- (void)willTransitionToTraitCollection:(nonnull UITraitCollection *)newCollection withTransitionCoordinator:(nonnull id<UIViewControllerTransitionCoordinator>)coordinator {
    
}


#pragma mark - getter

- (CDFFmpegPlayer *)player {
    if (!_player) {
        NSString *path;
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        
        path = self.path.length > 0 ? self.path : _remoteMovies[6];
        
        // increase buffering for .wmv, it solves problem with delaying audio frames
        if ([path.pathExtension isEqualToString:@"wmv"]) {
            parameters[CDPlayerParameterMinBufferedDuration] = @(5.0);
        }
        
        // disable deinterlacing for iPhone, because it's complex operation can cause stuttering
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            parameters[CDPlayerParameterDisableDeinterlacing] = @(YES);
        }
        
        _player = [CDFFmpegPlayer movieViewWithContentPath:path parameters:parameters];
        _player.rate = 2.0;
        _player.delegate = self;
        _player.autoplay = YES;
        _player.generatPreviewImages = YES;
    }
    return _player;
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
    NSString *path = [[self.path mutableCopy] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    FileType fileType = [[HcdFileManager sharedHcdFileManager] getFileTypeByPath:path];
    if (fileType != FileType_video) {
        self.btnAirplay.hidden = YES;
    }
}

#pragma mark - DLNADelegate

- (void)searchDLNAResult:(NSArray *)devicesArray {
    self.deviceArr = [[NSArray alloc] initWithArray:devicesArray];
}

- (void)dlnaStartPlay {
    
}

# pragma mark - CDFFmpegPlayerDelegate

- (void)cdFFmpegPlayer:(CDFFmpegPlayer *)player setSelectionsNumber:(CYPlayerSelectionsHandler)setNumHandler {
    
}

- (void)cdFFmpegPlayer:(CDFFmpegPlayer *)player changeSelections:(NSInteger)selectionsNum {
        
}

/// 播放器状态发生了变化
/// @param player 播放器对象
/// @param state 播放器状态
- (void)cdFFmpegPlayer:(CDFFmpegPlayer * _Nullable)player changeStatus:(CDFFmpegPlayerPlayState)state {
    if (state == CDFFmpegPlayerPlayState_Playing) {
        // 正在播放中
        [self.btnPlay setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_pause"] forState:UIControlStateNormal];
        [self.btnPlay setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_pause"] forState:UIControlStateHighlighted];
    } else if (state == CDFFmpegPlayerPlayState_Pause) {
        // 暂停播放
        [self.btnPlay setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_play"] forState:UIControlStateNormal];
        [self.btnPlay setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_play_hl"] forState:UIControlStateHighlighted];
    } else if (state == CDFFmpegPlayerPlayState_PlayEnd) {
        // 完成播放
        [self.btnPlay setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_play"] forState:UIControlStateNormal];
        [self.btnPlay setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_play_hl"] forState:UIControlStateHighlighted];
    }
}


- (void)cdFFmpegPlayer:(CDFFmpegPlayer * _Nullable)player controlViewDisplayStatus:(BOOL)isHidden {
    
}


- (void)cdFFmpegPlayer:(CDFFmpegPlayer * _Nullable)player onShareBtnCick:(UIButton * _Nullable)btn {
    
}


- (void)cdFFmpegPlayer:(CDFFmpegPlayer * _Nullable)player updatePosition:(CGFloat)position duration:(CGFloat)duration isDrag:(BOOL)isdrag {
    
    self.playlistModel.position = position;
    // 播放的进度
    dispatch_async(dispatch_get_main_queue(), ^{
        self.lblPosition.text = [HCDPlayerUtils durationStringFromSeconds:position];
        self.lblDuration.text = [HCDPlayerUtils durationStringFromSeconds:duration];
        
        if (!self.isDraggingSlider) {
            self.sldPosition.enabled = duration > 0;
            self.sldPosition.maximumValue = duration;
            self.sldPosition.minimumValue = 0;
            self.sldPosition.value = position;
        }
        
    });
}

- (void)cdFFmpegPlayerStartAutoPlaying:(CDFFmpegPlayer * _Nullable)player {
    
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
        [self.view addSubview:_volumeView];
    }
    return _volumeView;
}

- (PlaylistModel *)playlistModel {
    if (!_playlistModel) {
        _playlistModel = [[PlaylistModel alloc] init];
    }
    return _playlistModel;
}

@end
