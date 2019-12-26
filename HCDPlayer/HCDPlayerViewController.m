//
//  HCDPlayerViewController.m
//  HCDPlayer
//
//  Created by Jvaeyhcd on 06/12/2019.
//  Copyright © 2016 Jvaeyhcd. All rights reserved.
//

#import "HCDPlayerViewController.h"
#import "HCDPlayerUtils.h"

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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self registerNotification];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self unregisterNotification];
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
    [self.btnPlay setTitle:@"|>" forState:UIControlStateNormal];
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
    [self.btnPlay setTitle:@"||" forState:UIControlStateNormal];
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
    [self.btnPlay setTitle:@"|>" forState:UIControlStateNormal];
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
    UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    aiv.translatesAutoresizingMaskIntoConstraints = NO;
    aiv.hidesWhenStopped = YES;
    [self.view addSubview:aiv];
    
    UIView *topbar = self.vTopBar;
    
    // Add constraints
    NSLayoutConstraint *cx = [NSLayoutConstraint constraintWithItem:aiv
                                                          attribute:NSLayoutAttributeRight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:topbar
                                                          attribute:NSLayoutAttributeRight
                                                         multiplier:1
                                                           constant:-8];
    NSLayoutConstraint *cy = [NSLayoutConstraint constraintWithItem:aiv
                                                          attribute:NSLayoutAttributeCenterY
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:topbar
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:1
                                                           constant:0];
    [self.view addConstraints:@[cx, cy]];
    self.aivBuffering = aiv;
}

- (void)initTopBar {
    CGRect frame = self.view.bounds;
    frame.size.height = 44;
    UIView *v = [[UIView alloc] initWithFrame:frame];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    [self.view addSubview:v];
    NSDictionary *views = NSDictionaryOfVariableBindings(v);
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[v]|"
                                                          options:0
                                                          metrics:nil
                                                            views:views];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[v(==44)]"
                                                          options:0
                                                          metrics:nil
                                                            views:views];
    [self.view addConstraints:ch];
    [self.view addConstraints:cv];
    
    // Title Label
    UILabel *lbltitle = [[UILabel alloc] init];
    lbltitle.translatesAutoresizingMaskIntoConstraints = NO;
    lbltitle.backgroundColor = [UIColor clearColor];
    lbltitle.text = @"HCDPlayer";
    lbltitle.font = [UIFont systemFontOfSize:15];
    lbltitle.textColor = [UIColor whiteColor];
    lbltitle.textAlignment = NSTextAlignmentCenter;
    [v addSubview:lbltitle];
    views = NSDictionaryOfVariableBindings(lbltitle);
    ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[lbltitle]-|" options:0 metrics:nil views:views];
    [v addConstraints:ch];
    cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[lbltitle]|" options:0 metrics:nil views:views];
    [v addConstraints:cv];
    
    self.vTopBar = v;
    self.lblTitle = lbltitle;
}

- (void)initBottomBar {
    CGRect frame = self.view.bounds;
    frame.size.height = 44;
    UIView *v = [[UIView alloc] initWithFrame:frame];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    [self.view addSubview:v];
    NSDictionary *views = NSDictionaryOfVariableBindings(v);
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[v]|"
                                                          options:0
                                                          metrics:nil
                                                            views:views];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[v(==44)]|"
                                                          options:0
                                                          metrics:nil
                                                            views:views];
    [self.view addConstraints:ch];
    [self.view addConstraints:cv];
    
    // Play/Pause Button
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.backgroundColor = [UIColor clearColor];
    [button setTitle:@"|>" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(onPlayButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [v addSubview:button];
    views = NSDictionaryOfVariableBindings(button);
    cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[button]|" options:0 metrics:nil views:views];
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
    cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[lblpos]|" options:0 metrics:nil views:views];
    [v addConstraints:cv];
    
    UISlider *sldpos = [[UISlider alloc] init];
    sldpos.translatesAutoresizingMaskIntoConstraints = NO;
    sldpos.backgroundColor = [UIColor clearColor];
    sldpos.continuous = YES;
    [sldpos addTarget:self action:@selector(onSliderStartSlide:) forControlEvents:UIControlEventTouchDown];
    [sldpos addTarget:self action:@selector(onSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [sldpos addTarget:self action:@selector(onSliderEndSlide:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    [v addSubview:sldpos];
    views = NSDictionaryOfVariableBindings(sldpos);
    cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[sldpos]|" options:0 metrics:nil views:views];
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
    cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[lblduration]|" options:0 metrics:nil views:views];
    [v addConstraints:cv];
    
    views = NSDictionaryOfVariableBindings(button, lblpos, sldpos, lblduration);
    ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[button(==32)]-[lblpos(==72)]-[sldpos]-[lblduration(==72)]-|"
                                                 options:0
                                                 metrics:nil
                                                   views:views];
    [v addConstraints:ch];
    
    self.vBottomBar = v;
    self.btnPlay = button;
    self.lblPosition = lblpos;
    self.sldPosition = sldpos;
    self.lblDuration = lblduration;
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
    self.vTopBar.hidden = NO;
    self.vBottomBar.hidden = NO;

    __weak typeof(self)weakSelf = self;
    [UIView animateWithDuration:0.5f
                     animations:^{
                         __strong typeof(weakSelf)strongSelf = weakSelf;
                         strongSelf.vTopBar.alpha = 1.0f;
                         strongSelf.vBottomBar.alpha = 1.0f;
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
                     }
                     completion:^(BOOL finished) {
                         __strong typeof(weakSelf)strongSelf = weakSelf;

                         strongSelf.vTopBar.hidden = YES;
                         strongSelf.vBottomBar.hidden = YES;

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

@end
