//
//  HcdPopSelectView.m
//  HcdPlayer
//
//  Created by Salvador on 2019/9/14.
//  Copyright © 2019 Salvador. All rights reserved.
//  

#import "HcdPopSelectView.h"
#import "UIView+Hcd.h"
#import "NSString+Hcd.h"

#define kCellIdSingleSelectTableViewCell @"SingleSelectTableViewCell"

#define kContenViewHeight kScaleFrom_iPhone6_Desgin(110)

#define kRowHeight 50.0

@interface HcdPopSelectView()<UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSArray *dataArray;

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) UIView *dialogView;

@property (nonatomic, strong) UILabel *titleLbl;

@property (nonatomic, assign) CGFloat dialogViewHeight;

@end

@implementation HcdPopSelectView

- (instancetype)initWithDataArray:(NSArray *)dataArray title:(NSString *)title {
    if (self = [super init]) {
        _dataArray = dataArray;
        _title = title;
        
        [self initUI];
    }
    return self;
}

- (void)show {
    
    [UIView animateWithDuration:0.3f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0 options:UIViewAnimationOptionLayoutSubviews animations:^{
        
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5f];
        self.dialogView.frame = CGRectMake(0, kScreenHeight - self.dialogViewHeight, kScreenWidth, self.dialogViewHeight);
        
    } completion:^(BOOL finished) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss:)];
        tap.delegate = self;
        [self addGestureRecognizer:tap];
        
        self.dialogView.frame = CGRectMake(0, kScreenHeight - self.dialogViewHeight, kScreenWidth, self.dialogViewHeight);
    }];
}

#pragma mark - private

//隐藏
-(void)dismiss:(UITapGestureRecognizer *)tap{
    
    if( CGRectContainsPoint(self.frame, [tap locationInView:self.dialogView])) {
        NSLog(@"tap");
    } else{
        
        [self dismissBlock:^(BOOL complete) {
            
        }];
    }
}

//隐藏ActionSheet的Block
-(void)dismissBlock:(void(^)(BOOL complete))block{
    
    [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0 options:UIViewAnimationOptionLayoutSubviews animations:^{
        
        [self setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.0f]];
        [self.dialogView setFrame:CGRectMake(0, kScreenHeight, kScreenWidth, self.dialogViewHeight)];
        
    } completion:^(BOOL finished) {
        
        block(finished);
        [self removeFromSuperview];
        
    }];
    
}

/**
 初始化界面
 */
- (void)initUI {
    
    self.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
    self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    
    CGFloat dialogViewHeight = kTabbarSafeBottomMargin;
    
    CGFloat titleHeight = [_title sizeWithConstainedSize:CGSizeMake(kScreenWidth - 140, CGFLOAT_MAX) font:[UIFont systemFontOfSize:12.0]].height;
    titleHeight += (kBasePadding * 2);
    if (titleHeight < 50) {
        titleHeight = 50;
    }
    dialogViewHeight += titleHeight;
    
    NSInteger tableRows = self.dataArray.count < 5 ? self.dataArray.count : 5;
    dialogViewHeight += (tableRows) * kRowHeight;
    
    self.dialogViewHeight = dialogViewHeight;
    
    self.dialogView.frame = CGRectMake(0, self.frame.size.height, kScreenWidth, self.dialogViewHeight);
    self.titleLbl.frame = CGRectMake(70, 0, kScreenWidth - 140, 50);
    self.tableView.frame = CGRectMake(0, CGRectGetMaxY(self.titleLbl.frame), kScreenWidth, (tableRows) * kRowHeight);
    
    self.titleLbl.text = _title;
}

#pragma mark - lazy load

- (UIView *)dialogView {
    if (!_dialogView) {
        _dialogView = [[UIView alloc]initWithFrame:CGRectMake(0, self.frame.size.height, kScreenWidth, self.dialogViewHeight)];
        _dialogView.userInteractionEnabled = YES;
        _dialogView.backgroundColor = [UIColor whiteColor];
        [_dialogView setCornerOnTop:8.0];
        [self addSubview:_dialogView];
    }
    return _dialogView;
}

- (UILabel *)titleLbl {
    if (!_titleLbl) {
        _titleLbl = [[UILabel alloc]initWithFrame:CGRectMake(70, 0, kScreenWidth - 140, 50)];
        _titleLbl.font = [UIFont systemFontOfSize:12.0f];
        _titleLbl.textColor = [UIColor grayColor];
        _titleLbl.textAlignment = NSTextAlignmentCenter;
        _titleLbl.backgroundColor = [UIColor whiteColor];
        _titleLbl.numberOfLines = 0;
        [self.dialogView addSubview:_titleLbl];
    }
    return _titleLbl;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        [_tableView registerClass:[SingleSelectTableViewCell class] forCellReuseIdentifier:kCellIdSingleSelectTableViewCell];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor whiteColor];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [self.dialogView addSubview:_tableView];
    }
    return _tableView;
}

- (NSArray *)dataArray {
    if (!_dataArray) {
        _dataArray = [NSArray array];
    }
    return _dataArray;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([NSStringFromClass([touch.view class]) isEqualToString:@"UITableViewCellContentView"]) {
        // if touch the tableview's cell, disable the gesture.
        return NO;
    }
    return YES;
}

#pragma mark - UITableViewDelegate, UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [SingleSelectTableViewCell cellHeight];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SingleSelectTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdSingleSelectTableViewCell forIndexPath:indexPath];
    cell.titleLbl.text = [self.dataArray objectAtIndex:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self dismissBlock:^(BOOL complete) {
        if (self.seletedIndex) {
            self.seletedIndex(indexPath.row);
        }
    }];
}

@end


@implementation SingleSelectTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self initUI];
    }
    return self;
}

- (void)initUI {
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.frame = CGRectMake(0, 0, kScreenWidth, [SingleSelectTableViewCell cellHeight]);
    
    self.titleLbl.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
}

- (UILabel *)titleLbl {
    if (!_titleLbl) {
        _titleLbl = [[UILabel alloc] init];
        _titleLbl.textAlignment = NSTextAlignmentCenter;
        _titleLbl.font = [UIFont systemFontOfSize:16];
        _titleLbl.backgroundColor = [UIColor whiteColor];
        _titleLbl.textColor = [UIColor blackColor];
        [self.contentView addSubview:_titleLbl];
    }
    return _titleLbl;
}

+ (CGFloat)cellHeight {
    return kRowHeight;
}

@end
