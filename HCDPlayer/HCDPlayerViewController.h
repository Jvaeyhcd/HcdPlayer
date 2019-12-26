//
//  HCDPlayerViewController.h
//  HCDPlayer
//
//  Created by Jvaeyhcd on 06/12/2019.
//  Copyright © 2016 Jvaeyhcd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HCDPlayer.h"

typedef enum : NSUInteger {
    HCDPlayerStatusNone,
    HCDPlayerStatusOpening,
    HCDPlayerStatusOpened,
    HCDPlayerStatusPlaying,
    HCDPlayerStatusBuffering,
    HCDPlayerStatusPaused,
    HCDPlayerStatusEOF,
    HCDPlayerStatusClosing,
    HCDPlayerStatusClosed,
} HCDPlayerStatus;

@interface HCDPlayerViewController : UIViewController

@property (nonatomic, copy) NSString *url;
@property (nonatomic) BOOL autoplay;
@property (nonatomic) BOOL repeat;
@property (nonatomic) BOOL preventFromScreenLock;
@property (nonatomic) BOOL restorePlayAfterAppEnterForeground;
@property (nonatomic, readonly) HCDPlayerStatus status;

- (void)open;
- (void)close;
- (void)play;
- (void)pause;

@end
