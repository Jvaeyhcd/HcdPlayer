//
//  EditBottomView.m
//  HcdPlayer
//
//  Created by Salvador on 2019/2/25.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "EditBottomView.h"
#import "NSString+Hcd.h"

@implementation EditBottomView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.allBtn];
        [self addSubview:self.tipsLbl];
        [self addSubview:self.lineView];
        [self addSubview:self.deleteBtn];
        [self addSubview:self.moveBtn];
    }
    return self;
}

- (UIButton *)allBtn {
    if (!_allBtn) {
        _allBtn = [[UIButton alloc] init];
        _allBtn.frame = CGRectMake(6, 0, 40, 50);
        [_allBtn setImage:[UIImage imageNamed:@"hcdplayer.bundle/checkbox_circle"] forState:UIControlStateNormal];
        [_allBtn setImage:[UIImage imageNamed:@"hcdplayer.bundle/checkbox_circle_selected"] forState:UIControlStateSelected];
        _allBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    }
    return _allBtn;
}

- (UIButton *)moveBtn {
    if (!_moveBtn) {
        NSString *str = HcdLocalized(@"move", nil);
        CGFloat width = [str widthWithConstainedWidth:kScreenWidth font:[UIFont systemFontOfSize:14]] + 32;
        _moveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _moveBtn.frame = CGRectMake(CGRectGetMinX(self.deleteBtn.frame) - width - 8, 10, width, 30);
        [_moveBtn setTitle:str forState:UIControlStateNormal];
        _moveBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [_moveBtn setBackgroundColor:[UIColor whiteColor]];
        [_moveBtn setTitleColor:[UIColor color333] forState:UIControlStateNormal];
        _moveBtn.layer.borderWidth = 1;
        _moveBtn.layer.cornerRadius = 15;
        _moveBtn.layer.borderColor = kSplitLineBgColor.CGColor;
    }
    return _moveBtn;
}

- (UIButton *)deleteBtn {
    if (!_deleteBtn) {
        NSString *str = HcdLocalized(@"delete", nil);
        CGFloat width = [str widthWithConstainedWidth:kScreenWidth font:[UIFont systemFontOfSize:14]] + 32;
        _deleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _deleteBtn.frame = CGRectMake(kScreenWidth - width - kBasePadding, 10, width, 30);
        [_deleteBtn setTitle:str forState:UIControlStateNormal];
        _deleteBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [_deleteBtn setBackgroundColor:[UIColor whiteColor]];
        [_deleteBtn setTitleColor:[UIColor color333] forState:UIControlStateNormal];
        _deleteBtn.layer.borderWidth = 1;
        _deleteBtn.layer.cornerRadius = 15;
        _deleteBtn.layer.borderColor = kSplitLineBgColor.CGColor;
    }
    return _deleteBtn;
}

- (UILabel *)tipsLbl {
    UILabel *tipsLbl = [[UILabel alloc] initWithFrame:CGRectMake(46, 0, 120, 50)];
    tipsLbl.textColor = [UIColor color333];
    tipsLbl.font = [UIFont systemFontOfSize:14];
    tipsLbl.textAlignment = NSTextAlignmentLeft;
    tipsLbl.text = HcdLocalized(@"select_all", nil);
    return tipsLbl;
}

- (UIView *)lineView {
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 1)];
    lineView.backgroundColor = kSplitLineBgColor;
    return lineView;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
