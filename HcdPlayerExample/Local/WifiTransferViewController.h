//
//  WifiTransferViewController.h
//  HcdPlayer
//
//  Created by Salvador on 2019/1/21.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GCDWebUploader.h"
#import "Reachability.h"

NS_ASSUME_NONNULL_BEGIN

@interface WifiTransferViewController : UIViewController<GCDWebUploaderDelegate, UITableViewDelegate, UITableViewDataSource>

@end

NS_ASSUME_NONNULL_END
