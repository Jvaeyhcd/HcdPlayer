//
//  HcdBrightnessProgressView.m
//  HcdPlayer
//
//  Created by Salvador on 2019/3/15.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "HcdBrightnessProgressView.h"
#import "HcdProgressView.h"

@interface HcdBrightnessProgressView()

@property (nonatomic, strong) HcdProgressView *progressView;
@property (nonatomic, strong) UIImageView     *iconImgView;

@end

@implementation HcdBrightnessProgressView


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initSubviews];
    }
    return self;
}

- (void)initSubviews {
    [self addSubview:self.progressView];
}

- (HcdProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[HcdProgressView alloc] initWithFrame:CGRectMake(19, 8, 2, 100)];
        _progressView.progressColor = kMainColor;
        _progressView.progress = 0.5;
    }
    return _progressView;
}

@end
