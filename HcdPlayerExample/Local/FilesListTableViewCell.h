//
//  FilesListTableViewCell.h
//  HcdPlayer
//
//  Created by Salvador on 2019/1/21.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NetworkService.h"
#import "TOSMBClient.h"

#define kCellIdFilesList @"FilesListTableViewCell"

NS_ASSUME_NONNULL_BEGIN

@interface FilesListTableViewCell : UITableViewCell

- (void)setFilePath:(NSString *)path;

- (void)setFileUrlPath:(NSString *)url;

- (void)setFaterFolder:(NSString *)path;

- (void)setNetworkService:(NetworkService *)service;

- (void)setTOSMBSessionFile:(TOSMBSessionFile *)file;

- (void)addLongGes:(id)target action:(SEL)action;;

+ (CGFloat)cellHeight;

@end

NS_ASSUME_NONNULL_END
