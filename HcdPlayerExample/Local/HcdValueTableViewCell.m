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
        _titleLbl.font = [UIFont systemFontOfSize:15];
        _titleLbl.textColor = [UIColor color333];
        [self addSubview:_titleLbl];
    }
    if (!_contentLbl) {
        _contentLbl = [[UILabel alloc] initWithFrame:CGRectMake(kScreenWidth / 2, 0, kScreenWidth / 2 - 2 * kBasePadding, 50)];
        _contentLbl.font = [UIFont systemFontOfSize:15];
        _contentLbl.textColor = [UIColor color999];
        _contentLbl.textAlignment = NSTextAlignmentRight;
        [self addSubview:_contentLbl];
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
