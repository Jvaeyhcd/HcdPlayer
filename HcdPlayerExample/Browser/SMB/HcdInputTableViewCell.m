//
//  HcdInputTableViewCell.m
//  HcdPlayer
//
//  Created by Salvador on 2020/1/2.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import "HcdInputTableViewCell.h"

@implementation HcdInputTableViewCell

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
            make.width.mas_equalTo(kScreenWidth / 3 - kBasePadding);
        }];
    }
    if (!_inputTF) {
        _inputTF = [[UITextField alloc] initWithFrame:CGRectMake(kScreenWidth / 2, 0, kScreenWidth / 2 - kBasePadding, 50)];
        _inputTF.font = [UIFont systemFontOfSize:16];
        _inputTF.textColor = [UIColor color333];
        _inputTF.textAlignment = NSTextAlignmentLeft;
        [_inputTF addTarget:self action:@selector(textFieldTextChange:) forControlEvents:UIControlEventEditingChanged];
        [self addSubview:_inputTF];
        [_inputTF mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(50);
            make.left.mas_equalTo(kScreenWidth / 3);
            make.top.mas_equalTo(0);
            make.right.mas_equalTo(-kBasePadding);
        }];
    }
}

-(void)textFieldTextChange:(UITextField *)textField{
    NSLog(@"textField1 - 输入框内容改变,当前内容为: %@", textField.text);
    NSString *text = textField.text;
    if (self.textChanged) {
        self.textChanged(text);
    }
}

- (void)setRequired:(BOOL)required {
    _required = required;
    if (_required) {
        self.inputTF.placeholder = HcdLocalized(@"required", nil);
    } else {
        self.inputTF.placeholder = HcdLocalized(@"optional", nil);
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
