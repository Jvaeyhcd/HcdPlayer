//
//  AppDelegate.m
//  HcdPlayer
//
//  Created by Salvador on 2019/1/15.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "AppDelegate.h"

#import "MainViewController.h"
#import "HcdAppManager.h"
#import "PasscodeViewController.h"
#import "NetworkServiceDao.h"
#import "HDownloadModelDao.h"
#import "PlaylistModelDao.h"
#import "HcdFileManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [[HcdLocalized sharedInstance] initLanguage];
    [self initRootViewController];
    [self initDataBase];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissPasscode) name:@"dismissPasscode" object:nil];
    
    return YES;
}

- (void)dismissPasscode {
    self.window.rootViewController = [HcdAppManager sharedInstance].mainVc;
    [self.window makeKeyAndVisible];
}

- (void)initDataBase {
    [[NetworkServiceDao sharedNetworkServiceDao] createOrUpgradeTable];
    [[HDownloadModelDao sharedHDownloadModelDao] createOrUpgradeTable];
    [[PlaylistModelDao sharedPlaylistModelDao] createOrUpgradeTable];
}

- (void)initRootViewController {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [HcdAppManager sharedInstance].mainVc;
    [self.window makeKeyAndVisible];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    DLog(@"applicationWillResignActive");
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
    DLog(@"applicationDidEnterBackground");
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    DLog(@"applicationWillEnterForeground");
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    DLog(@"applicationDidBecomeActive");
    
    if ([[HcdAppManager sharedInstance] needPasscode] && ![HcdAppManager sharedInstance].passcodeViewShow) {
        PasscodeViewController *vc = [[PasscodeViewController alloc] init];
        vc.type = PasscodeTypeUnLock;
        UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:vc];
        nvc.modalPresentationStyle = UIModalPresentationFullScreen;
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:nvc animated:NO completion:^{
            
        }];
    }
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    DLog(@"applicationWillTerminate");
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_9_0
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(nullable NSString *)sourceApplication annotation:(id)annotation{
    // 判断传过来的url是否为文件类型
    if ([url.scheme isEqualToString:@"file"]) {
        [self showFileActionSheetWithFilePath:url.absoluteString];
    }
    
}
#else
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options{
    // 判断传过来的url是否为文件类型
    if ([url.scheme isEqualToString:@"file"]) {
        [self showFileActionSheetWithFilePath:url.absoluteString];
    }
    return YES;
}
#endif

- (void)showFileActionSheetWithFilePath:(NSString *)filePath {
    // 显示是打开还是保存至App
    HcdActionSheet *deleteSheet = [[HcdActionSheet alloc] initWithCancelStr:HcdLocalized(@"cancel", nil) otherButtonTitles:@[HcdLocalized(@"open", nil), HcdLocalized(@"save", nil)] attachTitle:[[filePath lastPathComponent] stringByRemovingPercentEncoding]];
    
    deleteSheet.seletedButtonIndex = ^(NSInteger index) {
        switch (index) {
            case 1: {
                [[HcdFileManager sharedHcdFileManager] openFile:filePath];
                break;
            }
            case 2: {
                [[HcdFileManager sharedHcdFileManager] showMoveViewController:filePath];
                break;
            }
            default:
                break;
        }
    };
    [[UIApplication sharedApplication].keyWindow addSubview:deleteSheet];
    [deleteSheet showHcdActionSheet];
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    
    if (IS_PAD) {
        // is ipad
        return UIInterfaceOrientationMaskAll;
    }
    
    BOOL isAllowAutorotate = [HcdAppManager sharedInstance].isAllowAutorotate;
    BOOL isLocked = [HcdAppManager sharedInstance].isLocked;
    UIInterfaceOrientationMask supportedInterfaceOrientationsForWindow = [HcdAppManager sharedInstance].supportedInterfaceOrientationsForWindow;
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

- (BOOL)getIsIpad {

    NSString *deviceType = [UIDevice currentDevice].model;
    if([deviceType isEqualToString:@"iPhone"]) {
        // iPhone
        return NO;
    } else if([deviceType isEqualToString:@"iPod touch"]) {
        //iPod Touch
        return NO;
    } else if([deviceType isEqualToString:@"iPad"]) {
        //iPad
        return YES;
    }

    return NO;
}


@end
