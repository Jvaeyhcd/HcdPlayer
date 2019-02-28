//
//  NSString+Hcd.h
//  HcdPlayer
//
//  Created by Salvador on 2019/1/21.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Hcd)

- (CGFloat)widthWithConstainedWidth:(CGFloat)width font:(UIFont *)font;
- (CGSize)sizeWithConstainedSize:(CGSize)size font:(UIFont *)font;
- (BOOL)isBlankString;
- (NSString *)removeAllSpaceAndNewline;
- (NSString *)removeBothSideSpaceAndNewline;
- (NSString *)replaceMoreThan10SpaceTo10Space;
@end

NS_ASSUME_NONNULL_END
