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
        
        self.deviceLbl.frame = CGRectMake(0, 0, scaleFromiPhoneXDesign(230), scaleFromiPhoneXDesign(30));
        self.deviceLbl.center = self.tvImageView.center;
        
        self.statusLbl.frame = CGRectMake((kScreenWidth - scaleFromiPhoneXDesign(230)) / 2, CGRectGetMaxY(self.tvImageView.frame) + kBasePadding, scaleFromiPhoneXDesign(230), 20);
        
        self.changeBtn.frame = CGRectMake(kScreenWidth / 2 - scaleFromiPhoneXDesign(100) - 2, CGRectGetMaxY(self.statusLbl.frame) + 2 * kBasePadding, scaleFromiPhoneXDesign(100), scaleFromiPhoneXDesign(36));
        [self.changeBtn setCornerOnLeft:scaleFromiPhoneXDesign(18)];
        
        self.quitBtn.frame = CGRectMake(kScreenWidth / 2 + 2, CGRectGetMinY(self.changeBtn.frame), scaleFromiPhoneXDesign(100), scaleFromiPhoneXDesign(36));
        [self.quitBtn setCornerOnRight:scaleFromiPhoneXDesign(18)];
    }
    return self;
}

- (void)show {
    [self removeFromSuperview];
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    self.hidden = NO;
}

- (void)hide {
    self.hidden = YES;
    [self removeFromSuperview];
}

#pragma mark - private

/**
 click quit DLNA play button.
 */
- (void)clickQuitBtn {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didClickQuitDLNAPlay)]) {
        [self.delegate didClickQuitDLNAPlay];
    }
}

/**
 Click change device button.
 */
- (void)clickChangeBtn {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didClickChangeDevice)]) {
        [self.delegate didClickChangeDevice];
    }
}

#pragma mark - lazy load

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
        [_quitBtn addTarget:self action:@selector(clickQuitBtn) forControlEvents:UIControlEventTouchUpInside];
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
        [_changeBtn addTarget:self action:@selector(clickChangeBtn) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_changeBtn];
    }
    return _changeBtn;
}

- (UILabel *)deviceLbl {
    if (!_deviceLbl) {
        _deviceLbl = [[UILabel alloc] init];
        _deviceLbl.font = [UIFont systemFontOfSize:16];
        _deviceLbl.textColor = [UIColor whiteColor];
        _deviceLbl.textAlignment = NSTextAlignmentCenter;
        _deviceLbl.text = @"客厅电视";
        [self addSubview:_deviceLbl];
    }
    return _deviceLbl;
}

- (UILabel *)statusLbl {
    if (!_statusLbl) {
        _statusLbl = [[UILabel alloc] init];
        _statusLbl.font = [UIFont systemFontOfSize:12];
        _statusLbl.textColor = [UIColor color999];
        _statusLbl.textAlignment = NSTextAlignmentCenter;
        _statusLbl.text = @"正在播放";
        [self addSubview:_statusLbl];
    }
    return _statusLbl;
}

@end
