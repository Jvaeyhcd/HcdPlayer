//
//  HcdInputTableViewCell.h
//  HcdPlayer
//
//  Created by Salvador on 2020/1/2.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kCellIdInputCell @"HcdInputTableViewCell"

typedef void(^HCDInputChangedBlock)(NSString * _Nullable text);

NS_ASSUME_NONNULL_BEGIN

@interface HcdInputTableViewCell : UITableViewCell

@property (nonatomic, copy) HCDInputChangedBlock textChanged;

+ (CGFloat)cellHeight;

@property (nonatomic, retain) UILabel *titleLbl;
@property (nonatomic, retain) UITextField *inputTF;


@end

NS_ASSUME_NONNULL_END
