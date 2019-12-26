//
//  HCDPlayerVideoFrame.h
//  HCDPlayer
//
//  Created by Jvaeyhcd on 05/12/2019.
//  Copyright © 2016 Jvaeyhcd. All rights reserved.
//

#import "HCDPlayerFrame.h"
#import <OpenGLES/ES2/gl.h>

typedef enum : NSUInteger {
    kHCDPlayerVideoFrameTypeNone,
    kHCDPlayerVideoFrameTypeRGB,
    kHCDPlayerVideoFrameTypeYUV
} HCDPlayerVideoFrameType;

@interface HCDPlayerVideoFrame : HCDPlayerFrame

@property (nonatomic) HCDPlayerVideoFrameType videoType;
@property (nonatomic) int width;
@property (nonatomic) int height;

- (BOOL)prepareRender:(GLuint)program;

@end
