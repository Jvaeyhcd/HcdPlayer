//
//  ViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2019/1/15.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "MainViewController.h"

#import "UIView+Hcd.h"
#import "UIImage+Hcd.h"

#import "SettingViewController.h"
#import "PlaylistViewController.h"
#import "LocalMainViewController.h"
#import "BrowserViewController.h"
#import "DownloadViewController.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"hPlayer";
    [self.view setBackgroundColor: kMainBgColor];
    
    [self createTabbar];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.tabBar dropShadowWithOffset:CGSizeMake(0, -3) radius:10 color:[UIColor colorWithRGBHex:0xE0E0E0] opacity:0.8];
}

- (void)createTabbar {
    LocalMainViewController *localVc = [[LocalMainViewController alloc] init];
    localVc.tabBarItem.image = [UIImage imageNamed:@"hcdplayer.bundle/tabbar_folder"];
    localVc.tabBarItem.selectedImage = [UIImage imageNamed:@"hcdplayer.bundle/tabbar_folder"];
    localVc.tabBarItem.title = HcdLocalized(@"local", nil);
    
    BrowserViewController *nearVc = [[BrowserViewController alloc] init];
    nearVc.tabBarItem.image = [UIImage imageNamed:@"hcdplayer.bundle/tabbar_near"];
    nearVc.tabBarItem.selectedImage = [UIImage imageNamed:@"hcdplayer.bundle/tabbar_near"];
    nearVc.tabBarItem.title = HcdLocalized(@"network", nil);
    
    PlaylistViewController *playListVc = [[PlaylistViewController alloc] init];
    playListVc.tabBarItem.image = [UIImage imageNamed:@"hcdplayer.bundle/tabbar_playlist"];
    playListVc.tabBarItem.selectedImage = [UIImage imageNamed:@"hcdplayer.bundle/tabbar_playlist"];
    playListVc.tabBarItem.title = HcdLocalized(@"playlist", nil);
    
    DownloadViewController *downloadVc = [[DownloadViewController alloc] init];
    downloadVc.tabBarItem.image = [UIImage imageNamed:@"hcdplayer.bundle/tabbar_download"];
    downloadVc.tabBarItem.selectedImage = [UIImage imageNamed:@"hcdplayer.bundle/tabbar_download"];
    downloadVc.tabBarItem.title = HcdLocalized(@"download", nil);
    
    SettingViewController *settingVc = [[SettingViewController alloc] init];
    settingVc.tabBarItem.image = [UIImage imageNamed:@"hcdplayer.bundle/tabbar_settings"];
    settingVc.tabBarItem.selectedImage = [UIImage imageNamed:@"hcdplayer.bundle/tabbar_settings"];
    settingVc.tabBarItem.title = HcdLocalized(@"setting", nil);
    
    UINavigationController *nvc1 = [[BaseNavigationController alloc] initWithRootViewController:localVc];
    UINavigationController *nvc2 = [[BaseNavigationController alloc] initWithRootViewController:nearVc];
    UINavigationController *nvc3 = [[BaseNavigationController alloc] initWithRootViewController:playListVc];
    UINavigationController *nvc4 = [[BaseNavigationController alloc] initWithRootViewController:downloadVc];
    UINavigationController *nvc5 = [[BaseNavigationController alloc] initWithRootViewController:settingVc];
    
    [self setViewControllers:[NSArray arrayWithObjects:nvc1, nvc2, nvc3, nvc4, nvc5, nil]];
    
    self.tabBar.backgroundColor = [UIColor colorWithRGBHex:0xfafafa];
    
    // 去除UITabbar上的黑线
    if (@available(iOS 13.0, *)) {
        UITabBarAppearance *standardAppearance = [[UITabBarAppearance alloc] init];
        UITabBarItemAppearance *inlineLayoutAppearance = [[UITabBarItemAppearance  alloc] init];
        [inlineLayoutAppearance.normal setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:10], NSForegroundColorAttributeName:[UIColor color999]}];
        [inlineLayoutAppearance.normal setIconColor:[UIColor color999]];
        [inlineLayoutAppearance.selected setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:10], NSForegroundColorAttributeName:kTabbarSelectedColor}];
        [inlineLayoutAppearance.selected setIconColor:kTabbarSelectedColor];
        standardAppearance.stackedLayoutAppearance = inlineLayoutAppearance;
        standardAppearance.backgroundColor = [UIColor whiteColor];
        standardAppearance.shadowImage = [UIImage imageWithColor:[UIColor clearColor]];
        self.tabBar.standardAppearance = standardAppearance;
    } else {
        [UITabBar appearance].shadowImage = [[UIImage alloc] init];
        [UITabBar appearance].backgroundImage = [[UIImage alloc] init];
    }
    [UITabBar appearance].translucent = NO;
    [[UITabBar appearance] setTintColor:kTabbarSelectedColor];
}


@end
