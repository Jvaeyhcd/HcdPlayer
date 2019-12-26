//
//  HCDPlayerAudioFrame.m
//  HCDPlayer
//
//  Created by Jvaeyhcd on 08/12/2019.
//  Copyright © 2016 Jvaeyhcd. All rights reserved.
//

#import "HCDPlayerAudioFrame.h"

@implementation HCDPlayerAudioFrame

- (id)init {
    self = [super init];
    if (self) {
        self.type = kHCDPlayerFrameTypeAudio;
    }
    return self;
}

@end
