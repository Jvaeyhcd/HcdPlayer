//
//  HcdPopSelectView.h
//  HcdPlayer
//
//  Created by Salvador on 2019/9/14.
//  Copyright © 2019 Salvador. All rights reserved.
//  Pop select tableview

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HcdPopSelectView : UIView

@property (nonatomic, copy) NSString *title;

@property (nonatomic, copy) void(^commitBlock)(NSString *str);

@property (nonatomic, copy) void(^seletedIndex)(NSInteger index);

- (instancetype)initWithDataArray:(NSArray *)dataArray title:(NSString *)title;

- (void)show;

@end

@interface SingleSelectTableViewCell : UITableViewCell

+ (CGFloat)cellHeight;

@property (nonatomic, strong) UILabel *titleLbl;

@end

NS_ASSUME_NONNULL_END
