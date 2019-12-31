//
//  WiFiTransferTableViewCell.m
//  HcdPlayer
//
//  Created by Salvador on 2019/2/20.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "WiFiTransferTableViewCell.h"

@implementation WiFiTransferTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initSubviews];
    }
    return self;
}

- (void)initSubviews {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    UIImageView *topImg = [[UIImageView alloc] initWithFrame:CGRectMake((kScreenWidth - scaleFromiPhoneXDesign(60)) / 2, scaleFromiPhoneXDesign(30), scaleFromiPhoneXDesign(60), scaleFromiPhoneXDesign(45))];
    topImg.contentMode = UIViewContentModeScaleAspectFill;
    topImg.image = [UIImage imageNamed:@"hcdplayer.bundle/pic_wifi_transfer"];
    [self addSubview:topImg];
    [topImg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(scaleFromiPhoneXDesign(30));
        make.width.mas_equalTo(scaleFromiPhoneXDesign(60));
        make.height.mas_equalTo(scaleFromiPhoneXDesign(45));
        make.centerX.equalTo(self);
    }];
    
    UILabel *tipsLbl = [[UILabel alloc] initWithFrame:CGRectMake((kScreenWidth - scaleFromiPhoneXDesign(300)) / 2, CGRectGetMaxY(topImg.frame) + kBasePadding, scaleFromiPhoneXDesign(300), 32)];
    tipsLbl.textColor = [UIColor color999];
    tipsLbl.textAlignment = NSTextAlignmentCenter;
    tipsLbl.numberOfLines = 2;
    tipsLbl.font = kFont(12);
    tipsLbl.text = HcdLocalized(@"wifiTransferTips", nil);
    [self addSubview:tipsLbl];
    [tipsLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(topImg.mas_bottom).offset(kBasePadding);
        make.width.mas_equalTo(scaleFromiPhoneXDesign(300));
        make.height.mas_equalTo(32);
        make.centerX.equalTo(self);
    }];
    
    _addressLbl = [[UILabel alloc] initWithFrame:CGRectMake(kBasePadding, CGRectGetMaxY(tipsLbl.frame) + kBasePadding, kScreenWidth - 2 * kBasePadding, 20)];
    _addressLbl.font = kFont(18);
    _addressLbl.textColor = [UIColor color333];
    _addressLbl.textAlignment = NSTextAlignmentCenter;
    _addressLbl.numberOfLines = 1;
    _addressLbl.text = @"";
    [self addSubview:_addressLbl];
    [_addressLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(tipsLbl.mas_bottom).offset(kBasePadding);
        make.left.mas_equalTo(kBasePadding);
        make.right.mas_equalTo(-kBasePadding);
        make.height.mas_equalTo(20);
    }];
}

+ (CGFloat)cellHeight {
    return scaleFromiPhoneXDesign(200);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
