//
//  GadientLayerView.m
//  HcdPlayer
//
//  Created by Salvador on 2020/4/14.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import "GadientLayerView.h"

@interface GadientLayerView()

@end

@implementation GadientLayerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.gradientLayer.frame = self.bounds;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.gradientLayer.frame = self.bounds;
}

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        
        _gradientLayer = [CAGradientLayer layer];
        
        //  设置 gradientLayer 的 Frame
        _gradientLayer.frame = self.bounds;
        
        //  创建渐变色数组，需要转换为CGColor颜色
        _gradientLayer.colors = @[(id)[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0].CGColor,
                                 (id)[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8].CGColor];
        
        //  设置三种颜色变化点，取值范围 0.0~1.0
        _gradientLayer.locations = @[@(0.0f) ,@(1.0f)];
        
        //  设置渐变颜色方向，左上点为(0,0), 右下点为(1,1)
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(0, 1);
        
        [self.layer addSublayer:_gradientLayer];
    }
    return _gradientLayer;
}

@end
