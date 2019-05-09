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
 * 视频界面是否是显示状态
 */
@property (nonatomic, assign) BOOL passcodeViewShow;

/**
 * 设置的解锁密码
 */
@property (nonatomic, copy) NSString *passcode;

/**
 主界面
 */
@property (nonatomic, strong) MainViewController *mainVc;

+ (HcdAppManager *)sharedInstance;

/**
 * 返回是否需要输入解锁密码解锁
 */
- (BOOL)needPasscode;

/**
 * 设置需要输入的解锁密码
 */
- (void)setNeedPasscode:(BOOL)needPasscode;

@end

NS_ASSUME_NONNULL_END
