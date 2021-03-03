//
//  DNLAViewController.h
//  HcdPlayer
//
//  Created by Salvador on 2021/2/28.
//  Copyright © 2021 Salvador. All rights reserved.
//

#import "BaseViewController.h"
#import "MRDLNA.h"

NS_ASSUME_NONNULL_BEGIN

@interface DNLAViewController : BaseViewController

@property (nonatomic, copy) NSString *playUrl;

@property (nonatomic, strong) CLUPnPDevice *device;

@end

NS_ASSUME_NONNULL_END
