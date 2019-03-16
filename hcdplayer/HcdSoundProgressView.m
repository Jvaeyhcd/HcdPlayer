//
//  HcdSoundProgressView.m
//  HcdPlayer
//
//  Created by Salvador on 2019/3/15.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "HcdSoundProgressView.h"
#import "HcdProgressView.h"

@interface HcdSoundProgressView()

@property (nonatomic, strong) HcdProgressView *progressView;
@property (nonatomic, strong) UIImageView     *iconImgView;

@end

@implementation HcdSoundProgressView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initSubviews];
    }
    return self;
}

- (void)layoutSubviews {
    NSLog(@"layoutSubviews");
    [super layoutSubviews];
    self.progressView.progress = _progress;
}

- (void)initSubviews {
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
    self.autoresizesSubviews = YES;
    [self addSubview:self.iconImgView];
    [self.iconImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.mas_centerX);
        make.width.mas_equalTo(20);
        make.height.mas_equalTo(15);
        make.bottom.mas_equalTo(-8);
    }];
    
    [self addSubview:self.progressView];
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(8);
        make.centerX.equalTo(self.mas_centerX);
        make.width.mas_equalTo(2);
        make.bottom.mas_equalTo(-31);
    }];
}

- (HcdProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[HcdProgressView alloc] initWithFrame:CGRectMake(19, 8, 2, 100)];
        _progressView.progressColor = kMainColor;
        _progressView.direction = HcdProgressDirectionBottomToTop;
        _progressView.progress = 0.0;
    }
    return _progressView;
}

- (UIImageView *)iconImgView {
    if (!_iconImgView) {
        _iconImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 36, 27)];
        _iconImgView.contentMode = UIViewContentModeScaleAspectFill;
        _iconImgView.image = [UIImage imageNamed:@"hcdplayer.bundle/icon_sound_2"];
    }
    return _iconImgView;
}

@synthesize progress = _progress;
- (void)setProgress:(CGFloat)progress {
    _progress = progress;
    self.progressView.progress = progress;
    if (progress <= 0) {
        self.iconImgView.image = [UIImage imageNamed:@"hcdplayer.bundle/icon_sound_1"];
    } else if (progress <= 0.5) {
        self.iconImgView.image = [UIImage imageNamed:@"hcdplayer.bundle/icon_sound_2"];
    } else {
        self.iconImgView.image = [UIImage imageNamed:@"hcdplayer.bundle/icon_sound_3"];
    }
}


@synthesize progressColor = _progressColor;
- (void)setProgressColor:(UIColor *)progressColor {
    _progressColor = progressColor;
    self.progressView.progressColor = progressColor;
}

@end
