//
//  RemoteControlView.m
//  HcdPlayer
//
//  Created by Salvador on 2019/9/15.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "RemoteControlView.h"
#import "UIView+Hcd.h"

@interface RemoteControlView()

/**
 电视机显示的图片UImageView
 */
@property (nonatomic, strong) UIImageView *tvImageView;

@end

@implementation RemoteControlView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        // 全局尺寸
        self.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
        self.backgroundColor = [UIColor colorWithRGBHex:0x323232];
        
        self.tvImageView.frame = CGRectMake((kScreenWidth - scaleFromiPhoneXDesign(230)) / 2, (kScreenHeight - scaleFromiPhoneXDesign(147) - 2 * kBasePadding - scaleFromiPhoneXDesign(36)) / 2 - scaleFromiPhoneXDesign(30), scaleFromiPhoneXDesign(230), scaleFromiPhoneXDesign(147));
        
        self.changeBtn.frame = CGRectMake(kScreenWidth / 2 - scaleFromiPhoneXDesign(100) - 2, CGRectGetMaxY(self.tvImageView.frame) + 2 * kBasePadding, scaleFromiPhoneXDesign(100), scaleFromiPhoneXDesign(36));
        [self.changeBtn setCornerOnLeft:scaleFromiPhoneXDesign(18)];
        
        self.quitBtn.frame = CGRectMake(kScreenWidth / 2 + 2, CGRectGetMaxY(self.tvImageView.frame) + 2 * kBasePadding, scaleFromiPhoneXDesign(100), scaleFromiPhoneXDesign(36));
        [self.quitBtn setCornerOnRight:scaleFromiPhoneXDesign(18)];
    }
    return self;
}

- (void)show {
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    self.hidden = NO;
}

- (void)hide {
    self.hidden = YES;
    [self removeFromSuperview];
}

- (UIImageView *)tvImageView {
    if (!_tvImageView) {
        _tvImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hcdplayer.bundle/image_tv"]];
        _tvImageView.contentMode = UIViewContentModeScaleAspectFill;
        _tvImageView.clipsToBounds = YES;
        [self addSubview:_tvImageView];
    }
    return _tvImageView;
}

- (UIButton *)quitBtn {
    if (!_quitBtn) {
        _quitBtn = [[UIButton alloc] init];
        _quitBtn.backgroundColor = [UIColor colorWithRGBHex:0x444444];
        [_quitBtn setTitle:@"退出播放" forState:UIControlStateNormal];
        [_quitBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _quitBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [self addSubview:_quitBtn];
    }
    return _quitBtn;
}

- (UIButton *)changeBtn {
    if (!_changeBtn) {
        _changeBtn = [[UIButton alloc] init];
        _changeBtn.backgroundColor = [UIColor colorWithRGBHex:0x444444];
        [_changeBtn setTitle:@"切换设备" forState:UIControlStateNormal];
        [_changeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _changeBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [self addSubview:_changeBtn];
    }
    return _changeBtn;
}

@end
