//
//  UIImage+HAdd.m
//  HKit
//
//  Created by Jvaeyhcd on 2019/6/27.
//  Copyright © 2019 STS. All rights reserved.
//

#import "UIImage+Hcd.h"

static NSCache *imageCache;

@implementation UIImage (HAdd)

- (UIImage *)redrawImage:(CGSize)size scale:(CGFloat)scale {
    // 绘制区域
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    
    // 开启图形上下文 size:绘图的尺寸 opaque:不透明 scale:屏幕分辨率系数,0会选择当前设备的屏幕分辨率系数
    UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0);
    
    // 绘制 在指定区域拉伸并绘制
    [self drawInRect:rect];
    
    // 从图形上下文获取图片
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    // 关闭上下文
    UIGraphicsEndImageContext();
    
    return image;
}

- (UIImage *)redrawRoundedImage:(CGSize)size bgColor:(UIColor *)bgColor cornerRadius:(CGFloat)cornerRadius {
    // 绘制区域
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    
    // 开启图形上下文 size:绘图的尺寸 opaque:不透明 scale:屏幕分辨率系数,0会选择当前设备的屏幕分辨率系数
    UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0);
    
    // 背景颜色填充
    [bgColor setFill];
    UIRectFill(rect);
    
    // 圆角矩形路径
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:cornerRadius];
    
    // 进行路径裁切，后续的绘图都会出现在这个圆形路径内部
    [path addClip];
    
    // 绘制图像 在指定区域拉伸并绘制
    [self drawInRect:rect];
    
    // 从图形上下文获取图片
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    // 关闭上下文
    UIGraphicsEndImageContext();
    
    return image;
}

- (UIImage *)redrawOvalImage:(CGSize)size bgColor:(UIColor *)bgColor {
    // 绘制区域
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    
    // 开启图形上下文 size:绘图的尺寸 opaque:不透明 scale:屏幕分辨率系数,0会选择当前设备的屏幕分辨率系数
    UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0);
    
    // 背景颜色填充
    [bgColor setFill];
    UIRectFill(rect);
    
    // 圆形路径
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:rect];
    
    // 进行路径裁切，后续的绘图都会出现在这个圆形路径内部
    [path addClip];
    
    // 绘制图像 在指定区域拉伸并绘制
    [self drawInRect:rect];
    
    // 从图形上下文获取图片
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    // 关闭上下文
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)viewToImage:(UIView *)view {
    // 将视图渲染成图片
    [[UIApplication sharedApplication].keyWindow insertSubview:view atIndex:0];
    
    UIGraphicsBeginImageContextWithOptions(view.frame.size, YES, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [view.layer renderInContext:context];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [view removeFromSuperview];
    
    return image;
}

+ (UIImage *)circleImageWithSize:(CGSize)size {
    // NO代表透明
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    // 获取上下文
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    // 添加一个圆
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    CGContextAddEllipseInRect(ctx, rect);
    
    // 裁剪
    CGContextClip(ctx);
    // 得到裁剪后的图像
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    // 关闭上下文
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)imageWithColor:(UIColor *)color {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageCache = [[NSCache alloc] init];
    });
    
    UIImage *image = [imageCache objectForKey:color];
    if (image) {
        return image;
    }
    
    image = [self imageWithColor:color size:CGSizeMake(1,1)];
    [imageCache setObject:image forKey:color];
    
    return image;
}

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size {
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return img;
}

+ (UIImage *)resizableImageWithColor:(UIColor *)color cornerRadius:(CGFloat)cornerRadius {
    CGFloat minEdgeSize = cornerRadius * 2 + 1;
    CGRect rect = CGRectMake(0, 0, minEdgeSize, minEdgeSize);
    UIBezierPath *roundedRect = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:cornerRadius];
    roundedRect.lineWidth = 0;
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0f);
    [color setFill];
    [roundedRect fill];
    [roundedRect stroke];
    [roundedRect addClip];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return [image resizableImageWithCapInsets:UIEdgeInsetsMake(cornerRadius, cornerRadius, cornerRadius, cornerRadius)];
}

@end
