//
//  HCDPlayerVideoFrame.m
//  HCDPlayer
//
//  Created by Jvaeyhcd on 05/12/2019.
//  Copyright © 2016 Jvaeyhcd. All rights reserved.
//

#import "HCDPlayerVideoFrame.h"

@implementation HCDPlayerVideoFrame

- (id)init {
    self = [super init];
    if (self) {
        self.type = kHCDPlayerFrameTypeVideo;
    }
    return self;
}

- (BOOL)prepareRender:(GLuint)program {
    return NO;
}

@end
