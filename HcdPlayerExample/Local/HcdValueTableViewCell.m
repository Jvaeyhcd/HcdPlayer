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
    
    if (!_titleLlb) {
        _titleLlb = [[UILabel alloc] initWithFrame:CGRectMake(kBasePadding, 0, kScreenWidth - 4 * kBasePadding, 50)];
        _titleLlb.font = [UIFont systemFontOfSize:16];
        _titleLlb.textColor = [UIColor color333];
        [self addSubview:_titleLlb];
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
