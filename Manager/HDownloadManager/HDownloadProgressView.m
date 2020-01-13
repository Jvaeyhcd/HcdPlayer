//
//  HDownloadProgressView.m
//  HcdPlayer
//
//  Created by Salvador on 2020/1/13.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import "HDownloadProgressView.h"

@interface HDownloadProgressView ()

/// 进度条view
@property (nonatomic, strong) UIView *progressView;

@end

@implementation HDownloadProgressView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = kSplitLineBgColor;
    }
    return self;
}

- (void)setProgress:(CGFloat)progress {
    
    _progress = progress;
    CGFloat width = self.frame.size.width * progress;
    [self.progressView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.mas_equalTo(0);
        make.width.mas_equalTo(width);
    }];
}

- (UIView *)progressView {
    if (!_progressView) {
        _progressView = [[UIView alloc] initWithFrame:self.bounds];
        _progressView.backgroundColor = kMainColor;
        [self addSubview:_progressView];
    }
    return _progressView;
}

@end
