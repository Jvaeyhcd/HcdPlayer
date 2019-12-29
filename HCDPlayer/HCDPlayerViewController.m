//
//  HCDPlayerViewController.m
//  HCDPlayer
//
//  Created by Jvaeyhcd on 06/12/2019.
//  Copyright © 2016 Jvaeyhcd. All rights reserved.
//

#import "HCDPlayerViewController.h"
#import "HCDPlayerUtils.h"
#import "HcdAppManager.h"

// 播放器状态
typedef enum : NSUInteger {
    HCDPlayerOperationNone,
    HCDPlayerOperationOpen,
    HCDPlayerOperationPlay,
    HCDPlayerOperationPause,
    HCDPlayerOperationClose,
} HCDPlayerOperation;

@interface HCDPlayerViewController () {
    BOOL restorePlay;
    BOOL animatingHUD;
    NSTimeInterval showHUDTime;
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

@property (nonatomic) dispatch_source_t timer;
@property (nonatomic) BOOL updateHUD;
@property (nonatomic) NSTimer *timerForHUD;

@property (nonatomic, readwrite) HCDPlayerStatus status;
@property (nonatomic) HCDPlayerOperation nextOperation;

@end

@implementation HCDPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initAll];
    // auto play
    [self play];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [HcdAppManager sharedInstance].isAllowAutorotate = YES;
    [self registerNotification];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [HcdAppManager sharedInstance].isAllowAutorotate = NO;
    [self unregisterNotification];
    [self close];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self showHUD];
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
}

- (void)unregisterNotification {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
}

#pragma mark - Init
- (void)initAll {
    [self initPlayer];
    [self initTopBar];
    [self initBottomBar];
    [self initBuffering];
    [self initLock];
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
    if (_landscape) {
        [self setInterfaceOrientation:UIInterfaceOrientationPortrait];
        return;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onLockButtonTapped:(id)sender {
    self.locked = !self.locked;
    [self setDevivceLocked:self.locked];
    if (self.locked) {
        [self hideHUD];
    } else {
        [self showHUD];
    }
}

- (void)onAirplayButtonTapped:(id)sender {
    
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
    self.player.position = position;
    self.updateHUD = YES;
    self.grTap.enabled = YES;
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
    [lockBtn addTarget:self action:@selector(onLockButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    lockBtn.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    lockBtn.layer.cornerRadius = 16;
    lockBtn.clipsToBounds = YES;
    [self.view addSubview:lockBtn];
    
    UIButton *closeBtn = self.btnClose;
    
    NSDictionary *views = NSDictionaryOfVariableBindings(lockBtn, closeBtn);
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[closeBtn]-[lockBtn(==32)]"
                                                          options:0
                                                          metrics:nil
                                                            views:views];

    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[lockBtn(==32)]"
                                                          options:0
                                                          metrics:nil
                                                            views:views];
    
    NSLayoutConstraint *cc = [NSLayoutConstraint constraintWithItem:lockBtn
                                               attribute:NSLayoutAttributeCenterY
                                               relatedBy:NSLayoutRelationEqual
                                                  toItem:self.view
                                               attribute:NSLayoutAttributeCenterY
                                              multiplier:1
                                                constant:0];
    [self.view addConstraints:ch];
    [self.view addConstraints:cv];
    [self.view addConstraint:cc];
    
    self.btnLock = lockBtn;
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
    [airplayBtn addTarget:self action:@selector(onAirplayButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [v addSubview:airplayBtn];
    views = NSDictionaryOfVariableBindings(airplayBtn);
    cv = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%f-[airplayBtn]|", kStatusBarHeight] options:0 metrics:nil views:views];
    [v addConstraints:cv];
    
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
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapGesutreRecognizer:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:tap];
    self.grTap = tap;
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
        [self.btnClose setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_back"] forState:UIControlStateNormal];
        [self.btnFull setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_fullscreen_exit"] forState:UIControlStateNormal];
    } else {
        [self.btnClose setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_close"] forState:UIControlStateNormal];
        [self.btnFull setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_fullscreen"] forState:UIControlStateNormal];
    }
    self.btnAirplay.hidden = _landscape;
}

#pragma mark - Gesture
- (void)onTapGesutreRecognizer:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (self.vTopBar.hidden) [self showHUD];
        else [self hideHUD];
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

@end
