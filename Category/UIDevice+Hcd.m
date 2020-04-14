//
//  UIDevice+Hcd.m
//  HcdPlayer
//
//  Created by Salvador on 2020/3/30.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import "UIDevice+Hcd.h"

@implementation UIDevice (Hcd)

+ (BOOL)isIphoneX {
    return [UIScreen mainScreen].bounds.size.width >= 375.0f && [UIScreen mainScreen].bounds.size.height >= 812.0f && [self isIphone];
}

+ (BOOL)isIphone {
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
}

+ (BOOL)isIpadX {
    return ([[[UIDevice currentDevice] model] containsString:@"iPad8"] && ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? (CGSizeEqualToSize(CGSizeMake(1668, 2388), [[UIScreen mainScreen] currentMode].size) || CGSizeEqualToSize(CGSizeMake(2048, 2732), [[UIScreen mainScreen] currentMode].size)) : NO));
}

+ (BOOL)isIpad {
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}

+ (CGFloat)statusBarHeight {
    return [[UIApplication sharedApplication] statusBarFrame].size.height;
}

+ (CGFloat)navBarHeight {
    if ([self isIphone]) {
        return 44;
    } else if ([self isIpadX]) {
        return 50;
    } else if ([self isIpad]) {
        if ([[UIDevice currentDevice].systemVersion floatValue] >= 12.0f) {
            return 50;
        } else {
            return 44;
        }
    }
    return 44;
}

+ (CGFloat)tabBarHeight {
    return [self isIphoneX] ? 49.0 + 34.0 : 49.0;
}

+ (CGFloat)statusBarAndNavBarHeight {
    return [self statusBarHeight] + [self navBarHeight];
}

+ (CGFloat)bottomSafeHeight {
    return [self isIphoneX] ? 34.0f : 0.0f;
}

+ (CGFloat)topSafeHeight {
    return [self isIphoneX] ? 44.0f : 0.0f;
}

@end
