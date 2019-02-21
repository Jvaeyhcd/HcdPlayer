//
//  FilesListTableViewCell.h
//  HcdPlayer
//
//  Created by Salvador on 2019/1/21.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kCellIdFilesList @"FilesListTableViewCell"

NS_ASSUME_NONNULL_BEGIN

@interface FilesListTableViewCell : UITableViewCell

- (void)setFilePath:(NSString *)path;
- (void)setFaterFolder:(NSString *)path;

+ (CGFloat)cellHeight;

@end

NS_ASSUME_NONNULL_END
