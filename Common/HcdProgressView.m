//
//  HcdProgressView.m
//  HcdPlayer
//
//  Created by Salvador on 2019/3/15.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "HcdProgressView.h"

@interface HcdProgressView()

@property (nonatomic, strong) CALayer *progressLayer;
@property (nonatomic, assign) CGFloat currentViewWidth;

@end

@implementation HcdProgressView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.direction = HcdProgressDirectionLeftToRight;
        self.progressLayer = [CALayer layer];
        self.backgroundColor = [UIColor grayColor];
        self.progressLayer.backgroundColor = [UIColor redColor].CGColor;
        self.progressLayer.frame = CGRectMake(0, 0, 0, frame.size.height);
        [self.layer addSublayer:self.progressLayer];
        self.currentViewWidth = frame.size.width;
    }
    return self;
}

@synthesize progress = _progress;
- (void)setProgress:(CGFloat)progress {
    _progress = progress;
    CGFloat viewWidth = self.frame.size.width;
    CGFloat viewHeight = self.frame.size.height;
    switch (self.direction) {
        case HcdProgressDirectionLeftToRight:
        {
            if (progress <= 0) {
                self.progressLayer.frame = CGRectMake(0, 0, 0, viewHeight);
            } else if (progress <= 1) {
                self.progressLayer.frame = CGRectMake(0, 0, progress * viewWidth, viewHeight);
            } else {
                self.progressLayer.frame = CGRectMake(0, 0, viewWidth, viewHeight);
            }
            break;
        }
        case HcdProgressDirectionRightToLeft:
        {
            if (progress <= 0) {
                self.progressLayer.frame = CGRectMake(viewWidth, 0, 0, viewHeight);
            } else if (progress <= 1) {
                self.progressLayer.frame = CGRectMake((1 - progress) * viewWidth, 0, progress * viewWidth, viewHeight);
            } else {
                self.progressLayer.frame = CGRectMake(0, 0, viewWidth, viewHeight);
            }
            break;
        }
        case HcdProgressDirectionBottomToTop:
        {
            if (progress <= 0) {
                self.progressLayer.frame = CGRectMake(0, 0, viewWidth, 0);
            } else if (progress <= 1) {
                self.progressLayer.frame = CGRectMake(0, (1 - progress) * viewHeight, viewWidth, progress * viewHeight);
            } else {
                self.progressLayer.frame = CGRectMake(0, 0, viewWidth, viewHeight);
            }
            break;
        }
        case HcdProgressDirectionTopToBottom:
        {
            if (progress <= 0) {
                self.progressLayer.frame = CGRectMake(0, 0, viewWidth, 0);
            } else if (progress <= 1) {
                self.progressLayer.frame = CGRectMake(0, 0, viewWidth, progress * viewHeight);
            } else {
                self.progressLayer.frame = CGRectMake(0, 0, viewWidth, viewHeight);
            }
            break;
        }
        default:
            break;
    }
}

- (CGFloat)progress {
    return _progress;
}

@synthesize progressColor = _progressColor;
- (void)setProgressColor:(UIColor *)progressColor {
    _progressColor = progressColor;
    self.progressLayer.backgroundColor = progressColor.CGColor;
}

- (UIColor *)progressColor {
    return _progressColor;
}

@end
