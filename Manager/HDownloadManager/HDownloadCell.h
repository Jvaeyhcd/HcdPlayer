//
//  HDownloadCell.h
//  HcdPlayer
//
//  Created by Salvador on 2020/1/13.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HDownloadModel.h"

#define kCellIdHDownloadCell @"HDownloadCell"

NS_ASSUME_NONNULL_BEGIN

@interface HDownloadCell : UITableViewCell

@property (nonatomic, strong) HDownloadModel *model;

+ (CGFloat)cellHeight;

@end

NS_ASSUME_NONNULL_END
