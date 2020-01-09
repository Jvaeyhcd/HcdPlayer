//
//  MoveViewController.h
//  HcdPlayer
//
//  Created by Salvador on 2019/1/23.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TOSMBClient.h"

NS_ASSUME_NONNULL_BEGIN

@interface MoveViewController : BaseViewController<UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (nonatomic, copy) NSString *currentPath;
@property (nonatomic, copy) NSMutableArray *fileList;

@property (nonatomic, assign) BOOL isDownload;

@property (nonatomic, strong) TOSMBSession *session;

@end

NS_ASSUME_NONNULL_END
