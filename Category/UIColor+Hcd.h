//
//  UIColor+Hcd.h
//  HcdPlayer
//
//  Created by Salvador on 2019/1/15.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (Hcd)

@property (nonatomic, readonly) CGColorSpaceModel colorSpaceModel;
@property (nonatomic, readonly) BOOL canProvideRGBComponents;
@property (nonatomic, readonly) CGFloat red;            // Only valid if canProvideRGBComponents is YES
@property (nonatomic, readonly) CGFloat green;          // Only valid if canProvideRGBComponents is YES
@property (nonatomic, readonly) CGFloat blue;           // Only valid if canProvideRGBComponents is YES
@property (nonatomic, readonly) CGFloat white;          // Only valid if colorSpaceModel == kCGColorSpaceModelMonochrome
@property (nonatomic, readonly) CGFloat alpha;
@property (nonatomic, readonly) UInt32 rgbHex;

+ (UIColor *)colorWithRGBHex:(UInt32)hex;
+ (UIColor *)colorWithHexString:(NSString *)stringToConvert;
+ (UIColor *)colorWithHexString:(NSString *)stringToConvert andAlpha:(CGFloat)alpha;

- (UIColor *)reverseColor;

+ (UIColor *)color333;
+ (UIColor *)color666;
+ (UIColor *)color999;

+ (UIColor *)colorRGBHex:(UInt32)hex darkColorRGBHex:(UInt32)darkHex;

@end

NS_ASSUME_NONNULL_END
