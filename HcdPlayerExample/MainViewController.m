//
//  ViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2019/1/15.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "MainViewController.h"

#import "UIView+Hcd.h"

#import "SettingViewController.h"
#import "NetworkMainViewController.h"
#import "LocalMainViewController.h"
#import "BrowserViewController.h"

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

- (void)createTabbar {
    LocalMainViewController *localVc = [[LocalMainViewController alloc] init];
    localVc.tabBarItem.image = [UIImage imageNamed:@"hcdplayer.bundle/tabbar_file"];
    localVc.tabBarItem.selectedImage = [UIImage imageNamed:@"hcdplayer.bundle/tabbar_file_selected"];
    localVc.tabBarItem.title = HcdLocalized(@"local", nil);
    
    NetworkMainViewController *networkVc = [[NetworkMainViewController alloc] init];
    networkVc.tabBarItem.image = [UIImage imageNamed:@"hcdplayer.bundle/tabbar_wifi"];
    networkVc.tabBarItem.selectedImage = [UIImage imageNamed:@"hcdplayer.bundle/tabbar_wifi_selected"];
    networkVc.tabBarItem.title = HcdLocalized(@"network", nil);
    
    SettingViewController *settingVc = [[SettingViewController alloc] init];
    settingVc.tabBarItem.image = [UIImage imageNamed:@"hcdplayer.bundle/tabbar_setting"];
    settingVc.tabBarItem.selectedImage = [UIImage imageNamed:@"hcdplayer.bundle/tabbar_setting_selected"];
    settingVc.tabBarItem.title = HcdLocalized(@"setting", nil);
    
    UINavigationController *nvc1 = [[BaseNavigationController alloc] initWithRootViewController:localVc];
    UINavigationController *nvc4 = [[BaseNavigationController alloc] initWithRootViewController:settingVc];
    
    [self setViewControllers:[NSArray arrayWithObjects:nvc1, nvc4, nil]];
    
    self.tabBar.backgroundColor = [UIColor colorWithRGBHex:0xfafafa];
    
    [UITabBar appearance].shadowImage = [[UIImage alloc] init];
    [UITabBar appearance].backgroundImage = [[UIImage alloc] init];
    [UITabBar appearance].translucent = NO;
//    [[UITabBar appearance] setBackgroundImage:[UIImage imageNamed:@"hcdplayer.bundle/tabbar_bg"]];
    [[UITabBar appearance] setTintColor:kTabbarSelectedColor];
    [self.tabBar dropShadowWithOffset:CGSizeMake(0, -3) radius:10 color:[UIColor colorWithRGBHex:0xE0E0E0] opacity:0.8];
    
//    UIView *tabbarBgView = [[UIView alloc] init];
//    tabbarBgView.backgroundColor = kBarBgColor;
//    tabbarBgView.frame = self.tabBar.bounds;
//
//    [[UITabBar appearance] insertSubview:tabbarBgView atIndex:0];
}


@end
