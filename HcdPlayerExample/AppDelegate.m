//
//  AppDelegate.m
//  HcdPlayer
//
//  Created by Salvador on 2019/1/15.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "AppDelegate.h"

#import "MainViewController.h"
#import "HcdDeviceManager.h"
#import "PasscodeViewController.h"

@interface AppDelegate ()

@property (nonatomic, strong) MainViewController *mianVc;
@property (nonatomic, strong) UINavigationController *passcodeVc;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [[HcdLocalized sharedInstance] initLanguage];
    
    _mianVc = [[MainViewController alloc] init];
    
    PasscodeViewController *vc = [[PasscodeViewController alloc] init];
    vc.type = PasscodeTypeUnLock;
    _passcodeVc = [[UINavigationController alloc] initWithRootViewController:vc];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = _mianVc;
    [self.window makeKeyAndVisible];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissPasscode) name:@"dismissPasscode" object:nil];
    
    return YES;
}

- (void)dismissPasscode {
    self.window.rootViewController = _mianVc;
    [self.window makeKeyAndVisible];
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    if ([[HcdDeviceManager sharedInstance] needPasscode]) {
        self.window.rootViewController = _passcodeVc;
    } else {
        self.window.rootViewController = _mianVc;
    }
    [self.window makeKeyAndVisible];
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    BOOL isAllowAutorotate = [HcdDeviceManager sharedInstance].isAllowAutorotate;
    BOOL isLocked = [HcdDeviceManager sharedInstance].isLocked;
    UIInterfaceOrientationMask supportedInterfaceOrientationsForWindow = [HcdDeviceManager sharedInstance].supportedInterfaceOrientationsForWindow;
    if (isLocked) {
        return supportedInterfaceOrientationsForWindow;
    } else {
        if (isAllowAutorotate) {
            return (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight);
        } else {
            return UIInterfaceOrientationMaskPortrait;
        }
    }
    
}


@end
