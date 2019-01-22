//
//  NSString+Hcd.m
//  HcdPlayer
//
//  Created by Salvador on 2019/1/21.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "NSString+Hcd.h"

@implementation NSString (Hcd)

- (CGFloat)widthWithConstainedWidth:(CGFloat)width font:(UIFont *)font {
    CGSize constraintRect = CGSizeMake(width, CGFLOAT_MAX);
    CGRect boundingBox = [self boundingRectWithSize:constraintRect options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: font} context:nil];
    return boundingBox.size.width;
}

@end
