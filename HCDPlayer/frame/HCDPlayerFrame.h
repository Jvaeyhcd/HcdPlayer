//
//  HCDPlayerFrame.h
//  HCDPlayer
//
//  Created by Jvaeyhcd on 08/12/2019.
//  Copyright © 2016 Jvaeyhcd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    kHCDPlayerFrameTypeNone,
    kHCDPlayerFrameTypeVideo,
    kHCDPlayerFrameTypeAudio
} HCDPlayerFrameType;

@interface HCDPlayerFrame : NSObject

@property (nonatomic) HCDPlayerFrameType type;
@property (nonatomic) NSData *data;
@property (nonatomic) double position;
@property (nonatomic) double duration;

@end
