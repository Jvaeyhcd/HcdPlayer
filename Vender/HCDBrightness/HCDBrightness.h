//
//  HCDBrightness.h
//  HcdPlayer
//
//  Created by Salvador on 2021/2/26.
//  Copyright © 2021 Salvador. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HCDBrightness : NSObject

/**
 保存当前的亮度
 */
+ (void)saveDefaultBrightness;
/*!
 @method
 @abstract 逐步设置亮度
 */
+ (void)graduallySetBrightness:(CGFloat)value;

/*!
 @method
 @abstract 逐步恢复亮度
 */
+ (void)graduallyResumeBrightness;

/**
 增加的方法，使亮度快速恢复到之前的值
 */
+ (void)fastResumeBrightness;

@end

NS_ASSUME_NONNULL_END
