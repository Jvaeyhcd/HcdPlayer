//
//  HcdValueTableViewCell.h
//  HcdPlayer
//
//  Created by Salvador on 2019/1/26.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kCellIdValueCell @"HcdValueTableViewCell"

NS_ASSUME_NONNULL_BEGIN

@interface HcdValueTableViewCell : UITableViewCell
+ (CGFloat)cellHeight;

@property (nonatomic, retain) UILabel *titleLbl;
@property (nonatomic, retain) UILabel *contentLbl;

@end

NS_ASSUME_NONNULL_END
