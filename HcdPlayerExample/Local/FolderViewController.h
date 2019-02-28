//
//  FolderViewController.h
//  HcdPlayer
//
//  Created by Salvador on 2019/1/23.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FolderViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (nonatomic, strong) NSString *currentPath;

@end

NS_ASSUME_NONNULL_END
