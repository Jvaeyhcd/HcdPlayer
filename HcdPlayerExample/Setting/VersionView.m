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
        UIImageView *iconImgView = [[UIImageView alloc] initWithFrame:CGRectMake((kScreenWidth - scaleFromiPhoneXDesign(90)) / 2, kBasePadding, scaleFromiPhoneXDesign(90), scaleFromiPhoneXDesign(90))];
        iconImgView.image = [UIImage imageNamed:@"hcdplayer.bundle/app_icon"];
        [self addSubview:iconImgView];
        
        UILabel *versionLbl = [[UILabel alloc] initWithFrame:CGRectMake(kBasePadding, CGRectGetMaxY(iconImgView.frame) + 2, kScreenWidth - 2 * kBasePadding, 20)];
        versionLbl.font = [UIFont systemFontOfSize:14];
        versionLbl.textColor = [UIColor color333];
        versionLbl.text = @"bVersion";
        versionLbl.textAlignment = NSTextAlignmentCenter;
        [self addSubview:versionLbl];
    }
    return self;
}

@end
