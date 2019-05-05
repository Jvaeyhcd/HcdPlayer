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

@property (nonatomic, assign) UIInterfaceOrientationMask supportedInterfaceOrientationsForWindow;
@property (nonatomic, assign) BOOL isLocked;
@property (nonatomic, assign) BOOL isAllowAutorotate;
@property (nonatomic, copy) NSString *passcode;

/**
 主界面
 */
@property (nonatomic, strong) MainViewController *mainVc;

+ (HcdAppManager *)sharedInstance;

- (BOOL)needPasscode;
- (void)setNeedPasscode:(BOOL)needPasscode;

@end

NS_ASSUME_NONNULL_END
