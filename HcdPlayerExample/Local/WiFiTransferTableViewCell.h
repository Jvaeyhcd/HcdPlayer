//
//  WiFiTransferTableViewCell.h
//  HcdPlayer
//
//  Created by Salvador on 2019/2/20.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kCellIdWiFiTransfer @"WiFiTransferTableViewCell"

NS_ASSUME_NONNULL_BEGIN

@interface WiFiTransferTableViewCell : UITableViewCell

@property (nonatomic, retain) UILabel *addressLbl;

+ (CGFloat)cellHeight;

@end

NS_ASSUME_NONNULL_END
