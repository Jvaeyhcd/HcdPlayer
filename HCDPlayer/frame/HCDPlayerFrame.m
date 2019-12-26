//
//  HCDPlayerFrame.m
//  HCDPlayer
//
//  Created by Jvaeyhcd on 08/12/2019.
//  Copyright © 2016 Jvaeyhcd. All rights reserved.
//

#import "HCDPlayerFrame.h"

@implementation HCDPlayerFrame

- (id)init {
    self = [super init];
    if (self) {
        _type = kHCDPlayerFrameTypeNone;
        _data = nil;
    }
    return self;
}

@end
