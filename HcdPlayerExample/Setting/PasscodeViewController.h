//
//  PasscodeViewController.h
//  HcdPlayer
//
//  Created by Salvador on 2019/3/23.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"

typedef enum : NSUInteger {
    PasscodeTypeSet,
    PasscodeTypeRepeat,
    PasscodeTypeCancle,
    PasscodeTypeUnLock,
} PasscodeType;

NS_ASSUME_NONNULL_BEGIN

@interface PasscodeViewController : BaseViewController

@property (nonatomic, assign) PasscodeType type;

@end

NS_ASSUME_NONNULL_END
