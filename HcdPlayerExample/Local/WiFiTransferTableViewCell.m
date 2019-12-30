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
    
    UILabel *tipsLbl = [[UILabel alloc] initWithFrame:CGRectMake((kScreenWidth - scaleFromiPhoneXDesign(300)) / 2, CGRectGetMaxY(topImg.frame) + kBasePadding, scaleFromiPhoneXDesign(300), 32)];
    tipsLbl.textColor = [UIColor color999];
    tipsLbl.textAlignment = NSTextAlignmentCenter;
    tipsLbl.numberOfLines = 2;
    tipsLbl.font = kFont(12);
    tipsLbl.text = HcdLocalized(@"wifiTransferTips", nil);
    [self addSubview:tipsLbl];
    
    _addressLbl = [[UILabel alloc] initWithFrame:CGRectMake(kBasePadding, CGRectGetMaxY(tipsLbl.frame) + kBasePadding, kScreenWidth - 2 * kBasePadding, 20)];
    _addressLbl.font = kFont(18);
    _addressLbl.textColor = [UIColor color333];
    _addressLbl.textAlignment = NSTextAlignmentCenter;
    _addressLbl.numberOfLines = 1;
    _addressLbl.text = @"";
    [self addSubview:_addressLbl];
}

+ (CGFloat)cellHeight {
    return scaleFromiPhoneXDesign(200);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
