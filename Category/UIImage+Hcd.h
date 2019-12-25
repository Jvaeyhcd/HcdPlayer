//
//  UIImage+HAdd.h
//  HKit
//
//  Created by Jvaeyhcd on 2019/6/27.
//  Copyright © 2019 STS. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (HAdd)

/**
 重新绘制图片
 @param size 绘制尺寸
 @param scale 缩放比例
 @return 新图
 */
- (UIImage *)redrawImage:(CGSize)size scale:(CGFloat)scale;

/**
 绘制圆角图片
 @param size 绘制尺寸
 @param bgColor 裁剪区域外的背景颜色
 @param cornerRadius 圆角
 @return 新图
 */
- (UIImage *)redrawRoundedImage:(CGSize)size bgColor:(UIColor *)bgColor cornerRadius:(CGFloat)cornerRadius;

/**
 重新绘制圆形图片
 @param size 绘制尺寸
 @param bgColor 裁剪区域外的背景颜色
 @return 新图
 */
- (UIImage *)redrawOvalImage:(CGSize)size bgColor:(UIColor *)bgColor;

/**
 界面转换为图片
 @param view 界面
 @return UIImage图片
 */
+ (UIImage *)viewToImage:(UIView *)view;

/**
 给图片添加圆角处理

 @param size 图片大小
 @return 处理后的图片
 */
+ (UIImage *)circleImageWithSize:(CGSize)size;


/// 纯色图片
/// @param color 图片的颜色
+ (UIImage * _Nonnull)imageWithColor:(UIColor * _Nonnull)color;

/// 纯色图片
/// @param color 图片颜色
/// @param size 图片大小
+ (UIImage * _Nonnull)imageWithColor:(UIColor * _Nonnull)color size:(CGSize)size;

/// 生成可以改变尺寸的图片
/// @param color 图片颜色
/// @param cornerRadius 圆角
+ (UIImage * _Nonnull)resizableImageWithColor:(UIColor * _Nonnull)color cornerRadius:(CGFloat)cornerRadius;

@end

NS_ASSUME_NONNULL_END
