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
#import "PlaylistViewController.h"
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
    localVc.tabBarItem.image = [UIImage imageNamed:@"hcdplayer.bundle/tabbar_folder"];
    localVc.tabBarItem.selectedImage = [UIImage imageNamed:@"hcdplayer.bundle/tabbar_folder"];
    localVc.tabBarItem.title = HcdLocalized(@"local", nil);
    
    PlaylistViewController *playListVc = [[PlaylistViewController alloc] init];
    playListVc.tabBarItem.image = [UIImage imageNamed:@"hcdplayer.bundle/tabbar_playlist"];
    playListVc.tabBarItem.selectedImage = [UIImage imageNamed:@"hcdplayer.bundle/tabbar_playlist"];
    playListVc.tabBarItem.title = HcdLocalized(@"playlist", nil);
    
    SettingViewController *settingVc = [[SettingViewController alloc] init];
    settingVc.tabBarItem.image = [UIImage imageNamed:@"hcdplayer.bundle/tabbar_settings"];
    settingVc.tabBarItem.selectedImage = [UIImage imageNamed:@"hcdplayer.bundle/tabbar_settings"];
    settingVc.tabBarItem.title = HcdLocalized(@"setting", nil);
    
    UINavigationController *nvc1 = [[BaseNavigationController alloc] initWithRootViewController:localVc];
    UINavigationController *nvc2 = [[BaseNavigationController alloc] initWithRootViewController:playListVc];
    UINavigationController *nvc4 = [[BaseNavigationController alloc] initWithRootViewController:settingVc];
    
    [self setViewControllers:[NSArray arrayWithObjects:nvc1, nvc2, nvc4, nil]];
    
    self.tabBar.backgroundColor = [UIColor colorWithRGBHex:0xfafafa];
    
    [UITabBar appearance].shadowImage = [[UIImage alloc] init];
    [UITabBar appearance].backgroundImage = [[UIImage alloc] init];
    [UITabBar appearance].translucent = NO;
    [[UITabBar appearance] setTintColor:kTabbarSelectedColor];
    [self.tabBar dropShadowWithOffset:CGSizeMake(0, -3) radius:10 color:[UIColor colorWithRGBHex:0xE0E0E0] opacity:0.8];
}


@end
