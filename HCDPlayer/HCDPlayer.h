//
//  HCDPlayer.h
//  HCDPlayer
//
//  Created by Jvaeyhcd on 09/12/2019.
//  Copyright © 2016 Jvaeyhcd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HCDPlayerDef.h"

typedef void (^onPauseComplete)(void);

@interface HCDPlayer : NSObject

@property (readonly, strong) UIView *playerView;

@property (nonatomic) double minBufferDuration;
@property (nonatomic) double maxBufferDuration;
@property (nonatomic) double position;
@property (nonatomic) double duration;
@property (nonatomic) BOOL opened;
@property (nonatomic) BOOL playing;
@property (nonatomic) BOOL buffering;
@property (nonatomic, strong) NSDictionary *metadata;

- (void)open:(NSString *)url;
- (void)close;
- (void)play;
- (void)pause;

@end
