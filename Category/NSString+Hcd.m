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

- (CGSize)sizeWithConstainedSize:(CGSize)size font:(UIFont *)font {
    CGRect boundingBox = [self boundingRectWithSize:size options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: font} context:nil];
    return boundingBox.size;
}

- (BOOL)isBlankString {
    if (self == nil) {
        return YES;
    }
    if (self == NULL) {
        return YES;
    }
    if ([self isKindOfClass:[NSNull class]]) {
        return YES;
    }
    if ([[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length]==0) {
        
        return YES;
    }
    return NO;
}

/**
 * 移除字符串中所有的空白、换行和Tab
 */
- (NSString *)removeAllSpaceAndNewline {
    
    NSString *temp = [self stringByReplacingOccurrencesOfString:@" " withString:@""];
    temp = [temp stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    temp = [temp stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    return temp;
    
}

/**
 * 移除字符串前后的空白、换行和Tab
 *
 */
- (NSString *)removeBothSideSpaceAndNewline {
    
    NSString *temp = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSString *text = [temp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet ]];
    return text;
}

/**
 * 将十个以上的空格替换成十个
 *
 */
- (NSString *)replaceMoreThan10SpaceTo10Space {
    
    NSMutableString *result = [NSMutableString string];
    
    // 连续空格的个数
    NSInteger seriesSpaceNumber = 0;
    
    NSInteger i = 0, len = self.length;
    
    for (; i < len; i++) {
        NSRange range = NSMakeRange(i, 1);
        NSString *s = [self substringWithRange:range];
        if ([s  isEqual: @" "] || [s  isEqual: @"\t"]) {
            if (seriesSpaceNumber < 10) {
                [result appendString:s];
                seriesSpaceNumber += 1;
            }
        } else {
            [result appendString:s];
            seriesSpaceNumber = 0;
        }
        //        if (c == ' ' || c == '\t') {
        //            if (seriesSpaceNumber < 10) {
        //                [result appendFormat:@"%02x", c];
        //                seriesSpaceNumber += 1;
        //            }
        //        } else {
        //            [result appendFormat:@"%02x", c];
        //            seriesSpaceNumber = 0;
        //        }
    }
    
    return result;
}

@end
