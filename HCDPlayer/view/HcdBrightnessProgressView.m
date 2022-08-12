//
//  HcdBrightnessProgressView.m
//  HcdPlayer
//
//  Created by Salvador on 2019/12/29.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "HcdBrightnessProgressView.h"
#import "HcdProgressView.h"

@interface HcdBrightnessProgressView()

@property (nonatomic, strong) HcdProgressView *progressView;
@property (nonatomic, strong) UIImageView     *iconImgView;

@property (nonatomic, weak) NSTimer *hideDelayTimer;

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

- (void)layoutSubviews {
    DLog(@"layoutSubviews");
    [super layoutSubviews];
    self.progressView.progress = _progress;
}

- (void)initSubviews {
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
    self.autoresizesSubviews = YES;
    [self addSubview:self.iconImgView];
    [self.iconImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.mas_centerX);
        make.width.mas_equalTo(16);
        make.height.mas_equalTo(12);
        make.bottom.mas_equalTo(-8);
    }];
    
    [self addSubview:self.progressView];
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(8);
        make.centerX.equalTo(self.mas_centerX);
        make.width.mas_equalTo(2);
        make.bottom.equalTo(self.iconImgView.mas_top).offset(-8);
    }];
}

- (HcdProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[HcdProgressView alloc] initWithFrame:CGRectMake(19, 8, 2, 100)];
        _progressView.progressColor = kMainColor;
        _progressView.direction = HcdProgressDirectionBottomToTop;
        _progressView.progress = 0.0;
        _progressView.layer.cornerRadius = 1;
        _progressView.clipsToBounds = YES;
    }
    return _progressView;
}

- (UIImageView *)iconImgView {
    if (!_iconImgView) {
        _iconImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 36, 27)];
        _iconImgView.contentMode = UIViewContentModeScaleAspectFill;
        _iconImgView.image = [UIImage imageNamed:@"hcdplayer.bundle/icon_brightness"];
    }
    return _iconImgView;
}

@synthesize progress = _progress;
- (void)setProgress:(CGFloat)progress {
    _progress = progress;
    self.progressView.progress = progress;
}


@synthesize progressColor = _progressColor;
- (void)setProgressColor:(UIColor *)progressColor {
    _progressColor = progressColor;
    self.progressView.progressColor = progressColor;
}

- (void)show {
    // Cancel any scheduled hideAnimated:afterDelay: calls
    if (self.hideDelayTimer) {
        [self.hideDelayTimer invalidate];
    }
    
    self.hidden = NO;
    self.alpha = 1.0;
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(handleHideTimer:) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    self.hideDelayTimer = timer;
}

- (void)handleHideTimer:(NSTimer *)timer {
    
    [UIView animateWithDuration:0.5 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        self.hidden = YES;
    }];
}

- (void)dealloc {
    if (self.hideDelayTimer) {
        [self.hideDelayTimer invalidate];
        self.hideDelayTimer = nil;
    }
}

@end
