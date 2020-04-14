//
//  UIDevice+Hcd.h
//  HcdPlayer
//
//  Created by Salvador on 2020/3/30.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIDevice (Hcd)

/// 是否是iPhone X
+ (BOOL)isIphoneX;

/// 是否是全面屏的ipad
+ (BOOL)isIpadX;

/// 是否是普通iPhone
+ (BOOL)isIphone;

/// 是否是普通iPad
+ (BOOL)isIpad;

/// 状态栏的高度
+ (CGFloat)statusBarHeight;

/// 导航栏的高度
+ (CGFloat)navBarHeight;

/// 状态栏和导航栏的高度
+ (CGFloat)statusBarAndNavBarHeight;

/// tabbar的高度
+ (CGFloat)tabBarHeight;

/// 顶部安全区域
+ (CGFloat)topSafeHeight;

/// 底部安全区域
+ (CGFloat)bottomSafeHeight;

@end

NS_ASSUME_NONNULL_END
