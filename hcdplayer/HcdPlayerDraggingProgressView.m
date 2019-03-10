//
//  HcdPlayerDraggingProgressView.m
//  HcdPlayer
//
//  Created by Salvador on 2019/3/10.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "HcdPlayerDraggingProgressView.h"

@interface HcdPlayerDraggingProgressView()

@property (nonatomic, strong, readonly) UIView *contentView;

@end

@implementation HcdPlayerDraggingProgressView

@synthesize contentView = _contentView;
@synthesize directionImageView = _directionImageView;
@synthesize shiftTimeLabel = _shiftTimeLabel;
@synthesize separatorLabel = _separatorLabel;
@synthesize durationTimeLabel = _durationTimeLabel;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _setupViews];
    }
    return self;
}

#pragma mark -

- (void)setProgressTime:(NSTimeInterval)progressTime {
    float beforeProgressTime = _progressTime;
    
    _progressTime = progressTime;
    
    if ( beforeProgressTime > _progressTime ) {
        _directionImageView.image = [UIImage imageNamed:@"hcdplayer.bundle/icon_video_player_forward"];
    }
    else if ( beforeProgressTime < _progressTime ) {
        _directionImageView.image = [UIImage imageNamed:@"hcdplayer.bundle/icon_video_player_fast"];
    }
}

- (void)setProgressTimeStr:(NSString *)shiftTimeStr {
    self.shiftTimeLabel.text = shiftTimeStr;
}

- (void)setProgressTimeStr:(NSString *)shiftTimeStr totalTimeStr:(NSString *)totalTimeStr {
    self.shiftTimeLabel.text = shiftTimeStr;
    self.durationTimeLabel.text = totalTimeStr;
}

#pragma mark -

- (void)_setupViews {
    [self addSubview:self.contentView];
    [self.contentView addSubview:self.directionImageView];
    [self.contentView addSubview:self.shiftTimeLabel];
    [self.contentView addSubview:self.separatorLabel];
    [self.contentView addSubview:self.durationTimeLabel];
    
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
        CGFloat width = 150;
        CGFloat height = width * 8 / 15;
        make.size.mas_offset(CGSizeMake(ceil(width), ceil(height)));
    }];
    
    [self.directionImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.offset(0);
        make.bottom.equalTo(self.mas_centerY);
        make.centerX.offset(0);
    }];
    
    [self.separatorLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.offset(0);
        make.top.equalTo(self.directionImageView.mas_bottom);
        make.bottom.offset(0);
        make.width.offset(5);
    }];
    
    [self.shiftTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.separatorLabel.mas_left);
        make.centerY.equalTo(self.separatorLabel);
        make.left.offset(0);
    }];
    
    [self.durationTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.separatorLabel.mas_right);
        make.centerY.equalTo(self.separatorLabel);
        make.right.offset(0);
    }];
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [UIView new];
        _contentView.layer.cornerRadius = 8;
    }
    return _contentView;
}

- (UIImageView *)directionImageView {
    if (!_directionImageView) {
        _directionImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _directionImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _directionImageView;
}

- (UILabel *)shiftTimeLabel {
    if (!_shiftTimeLabel) {
        _shiftTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _shiftTimeLabel.font = [UIFont systemFontOfSize:13];
        _shiftTimeLabel.textColor = [UIColor whiteColor];
        _shiftTimeLabel.textAlignment = NSTextAlignmentRight;
    }
    return _shiftTimeLabel;
}

- (UILabel *)separatorLabel {
    if (!_separatorLabel) {
        _separatorLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _separatorLabel.font = [UIFont systemFontOfSize:13];
        _separatorLabel.textColor = [UIColor whiteColor];
        _separatorLabel.text = @"/";
    }
    return _separatorLabel;
}

- (UILabel *)durationTimeLabel {
    if (!_durationTimeLabel) {
        _durationTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _durationTimeLabel.font = [UIFont systemFontOfSize:13];
        _durationTimeLabel.textColor = [UIColor whiteColor];
        _durationTimeLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _durationTimeLabel;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
