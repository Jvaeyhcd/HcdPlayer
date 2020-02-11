//
//  ViewController.m
//  HCDPlayer
//
//  Created by Jvaeyhcd on 29/11/2019.
//  Copyright © 2016 Jvaeyhcd. All rights reserved.
//

#import "HPlayerViewController.h"
#import "HCDPlayerViewController.h"

@interface HPlayerViewController () <UITextFieldDelegate>

@property (nonatomic) HCDPlayerViewController *vcHCDPlayer;
@property (nonatomic) BOOL fullscreen;
@property (nonatomic) BOOL landscape;

@end

@implementation HPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self updateTitle];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_vcHCDPlayer close];
    [self unregisterNotification];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self initHCDPlayer];
    [self registerNotification];
    [self go];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)registerNotification {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(notifyPlayerError:) name:HCDPlayerNotificationError object:_vcHCDPlayer];
}

- (void)unregisterNotification {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
}

- (void)notifyPlayerError:(NSNotification *)notif {
    NSDictionary *userInfo = notif.userInfo;
    NSError *error = userInfo[HCDPlayerNotificationErrorKey];
    BOOL isAudioError = [error.domain isEqualToString:HCDPlayerErrorDomainAudioManager];
    NSString *title = isAudioError ? @"Audio Error" : @"Error";
    NSString *message = error.localizedDescription;
    if (isAudioError) {
        NSError *rawError = error.userInfo[NSLocalizedFailureReasonErrorKey];
        message = [message stringByAppendingFormat:@"\n%@", rawError];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)updateTitle {
    if (self.url.length == 0) {
        self.navigationItem.title = @"HCDPlayer";
    } else {
        self.navigationItem.title = [self.url lastPathComponent];
    }
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.returnKeyType == UIReturnKeyGo) {
        [textField resignFirstResponder];
        [self go];
    }
    return YES;
}

- (void)go {
    if (self.url.length == 0) return;
    [self updateTitle];
    _vcHCDPlayer.url = self.url;
    [_vcHCDPlayer close];
    [_vcHCDPlayer open];
}

- (void)initHCDPlayer {
    if (_vcHCDPlayer != nil) {
        [_vcHCDPlayer.view removeFromSuperview];
        self.vcHCDPlayer = nil;
    }
    HCDPlayerViewController *vc = [[HCDPlayerViewController alloc] init];
    vc.view.translatesAutoresizingMaskIntoConstraints = YES;
    vc.view.frame = self.view.frame;
    vc.autoplay = YES;
    vc.repeat = YES;
    vc.preventFromScreenLock = YES;
    vc.restorePlayAfterAppEnterForeground = YES;
    [self.view addSubview:vc.view];
    self.vcHCDPlayer = vc;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    BOOL isLandscape = size.width > size.height;
    [coordinator animateAlongsideTransition:nil
                                 completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                                     self.landscape = isLandscape;
                                 }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    if (touch.tapCount == 2) {
        self.fullscreen = !self.fullscreen;
    }
}

- (void)setFullscreen:(BOOL)fullscreen {
    _fullscreen = fullscreen;
    [self updatePlayerFrame];
}

- (void)setLandscape:(BOOL)landscape {
    _landscape = landscape;
    [self updatePlayerFrame];
}

- (void)updatePlayerFrame {
    BOOL fullscreen = _landscape || _fullscreen;
    [self.navigationController setNavigationBarHidden:fullscreen animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:fullscreen withAnimation:YES];
    [self setNeedsStatusBarAppearanceUpdate];
    [UIView animateWithDuration:0.2f
                     animations:^{
                         _vcHCDPlayer.view.frame = fullscreen ? self.view.frame : self.view.frame;
                     }];
}

- (BOOL)prefersStatusBarHidden {
    return (_landscape || _fullscreen);
}

@end
