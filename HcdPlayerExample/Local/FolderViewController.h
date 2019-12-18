//
//  FolderViewController.h
//  HcdPlayer
//
//  Created by Salvador on 2019/1/23.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FolderViewController : BaseViewController<UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (nonatomic, copy) NSString *currentPath;

@property (nonatomic, copy) NSString *titleStr;

@end

NS_ASSUME_NONNULL_END
