//
//  HcdValueTableViewCell.m
//  HcdPlayer
//
//  Created by Salvador on 2019/1/26.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "HcdValueTableViewCell.h"

@implementation HcdValueTableViewCell

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
    self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.frame];
    self.selectedBackgroundView.backgroundColor = kSelectedCellBgColor;
    self.tintColor = kMainColor;
    
    if (!_titleLbl) {
        _titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(kBasePadding, 0, kScreenWidth / 2 - kBasePadding, 50)];
        _titleLbl.font = [UIFont systemFontOfSize:16];
        _titleLbl.textColor = [UIColor color333];
        [self addSubview:_titleLbl];
        [_titleLbl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(50);
            make.left.mas_equalTo(kBasePadding);
            make.top.mas_equalTo(0);
            make.right.mas_equalTo(-kScreenWidth / 2);
        }];
    }
    if (!_contentLbl) {
        _contentLbl = [[UILabel alloc] initWithFrame:CGRectMake(kScreenWidth / 2, 0, kScreenWidth / 2 - 2 * kBasePadding, 50)];
        _contentLbl.font = [UIFont systemFontOfSize:16];
        _contentLbl.textColor = [UIColor color999];
        _contentLbl.textAlignment = NSTextAlignmentRight;
        [self addSubview:_contentLbl];
        [_contentLbl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(50);
            make.left.mas_equalTo(kScreenWidth / 2);
            make.top.mas_equalTo(0);
            make.right.mas_equalTo(-2 * kBasePadding);
        }];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (CGFloat)cellHeight {
    return 50;
}

@end
