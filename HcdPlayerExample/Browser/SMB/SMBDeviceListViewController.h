//
//  SMBDeviceListViewController.h
//  HcdPlayer
//
//  Created by Salvador on 2020/1/2.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import "BaseViewController.h"
#import "TOSMBClient.h"

NS_ASSUME_NONNULL_BEGIN

@interface SMBDeviceListViewController : BaseViewController

@property (nonatomic, strong, null_resettable) TOSMBSession *session;

@end

NS_ASSUME_NONNULL_END
