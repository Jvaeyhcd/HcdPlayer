//
//  UIView+Hcd.h
//  HcdPlayer
//
//  Created by Salvador on 2019/1/21.
//  Copyright © 2019 Salvador. All rights reserved.
//



NS_ASSUME_NONNULL_BEGIN

@interface UIView (Hcd)

- (void)dropShadowWithOffset:(CGSize)offset radius:(CGFloat)radius color:(UIColor *)color opacity:(CGFloat)opacity;

- (void)setCornerOnBottom:(CGFloat)radius;
- (void)setCornerOnTop:(CGFloat)radius;
- (void)setCornerOnLeft:(CGFloat)radius;
- (void)setCornerOnRight:(CGFloat)radius;

@end

NS_ASSUME_NONNULL_END
