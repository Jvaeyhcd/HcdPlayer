//
//  HcdDeviceManager.h
//  HcdPlayer
//
//  Created by Salvador on 2019/3/19.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MainViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface HcdAppManager : NSObject

/**
 * 锁定状态下支持的设备方向
 */
@property (nonatomic, assign) UIInterfaceOrientationMask supportedInterfaceOrientationsForWindow;

/**
 * 是否锁定屏幕
 */
@property (nonatomic, assign) BOOL isLocked;

/**
 * 是否允许自动旋转
 */
@property (nonatomic, assign) BOOL isAllowAutorotate;

/**
 * 是否显示解锁密码界面
 */
@property (nonatomic, assign) BOOL passcodeViewShow;

/**
 * 设置的解锁密码
 */
@property (nonatomic, copy) NSString *passcode;

/**
 * 主界面
 */
@property (nonatomic, strong) MainViewController *mainVc;

/**
 * 播放主界面列表
 */
@property (nonatomic, copy) NSArray *playList;

+ (HcdAppManager *)sharedInstance;

/**
 * 返回是否需要输入解锁密码解锁
 */
- (BOOL)needPasscode;

/**
 * 设置需要输入的解锁密码
 */
- (void)setNeedPasscode:(BOOL)needPasscode;

/**
 * 将播放路径添加到播放列表
 * @param path 文件路径
 */
- (void)addPathToPlaylist:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
