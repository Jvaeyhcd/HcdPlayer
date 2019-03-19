//
//  HcdDeviceManager.h
//  HcdPlayer
//
//  Created by Salvador on 2019/3/19.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HcdDeviceManager : NSObject

@property (nonatomic, assign) UIInterfaceOrientationMask supportedInterfaceOrientationsForWindow;
@property (nonatomic, assign) BOOL isLocked;
@property (nonatomic, assign) BOOL isAllowAutorotate;

+ (HcdDeviceManager *)sharedInstance;

@end

NS_ASSUME_NONNULL_END
