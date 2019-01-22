//
//  UIView+Hcd.m
//  HcdPlayer
//
//  Created by Salvador on 2019/1/21.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "UIView+Hcd.h"

@implementation UIView (Hcd)

- (void)dropShadowWithOffset:(CGSize)offset radius:(CGFloat)radius color:(UIColor *)color opacity:(CGFloat)opacity {
    [self.layer setShadowPath: [[UIBezierPath bezierPathWithRect:self.bounds] CGPath]];
    self.layer.shadowColor = [color CGColor];
    self.layer.shadowOffset = offset;
    self.layer.shadowRadius = radius;
    self.layer.shadowOpacity = opacity;
    
    self.clipsToBounds = NO;
}

@end
