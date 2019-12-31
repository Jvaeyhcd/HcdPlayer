//
//  VersionView.m
//  HcdPlayer
//
//  Created by Salvador on 2019/4/20.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "VersionView.h"

@implementation VersionView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIImageView *iconImgView = [[UIImageView alloc] initWithFrame:CGRectMake((kScreenWidth - scaleFromiPhoneXDesign(120)) / 2, kBasePadding, scaleFromiPhoneXDesign(120), scaleFromiPhoneXDesign(120))];
        iconImgView.image = [UIImage imageNamed:@"hcdplayer.bundle/app_icon"];
        [self addSubview:iconImgView];
        [iconImgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(scaleFromiPhoneXDesign(120));
            make.top.mas_equalTo(kBasePadding);
            make.centerX.equalTo(self);
        }];
        
        UILabel *versionLbl = [[UILabel alloc] initWithFrame:CGRectMake(kBasePadding, CGRectGetMaxY(iconImgView.frame) + 2, kScreenWidth - 2 * kBasePadding, 20)];
        versionLbl.font = [UIFont systemFontOfSize:14];
        versionLbl.textColor = [UIColor color999];
        
        versionLbl.text = [NSString stringWithFormat:@"%@ %@", HcdLocalized(@"version", nil), [[[NSBundle mainBundle] infoDictionary]objectForKey:@"CFBundleShortVersionString"]];
        versionLbl.textAlignment = NSTextAlignmentCenter;
        [self addSubview:versionLbl];
        [versionLbl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_lessThanOrEqualTo(kBasePadding);
            make.top.equalTo(iconImgView.mas_bottom).offset(2);
            make.right.mas_equalTo(-kBasePadding);
            make.height.mas_equalTo(20);
        }];
    }
    return self;
}

@end
