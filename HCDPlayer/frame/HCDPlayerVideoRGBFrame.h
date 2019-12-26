//
//  HCDPlayerVideoRGBFrame.h
//  HCDPlayer
//
//  Created by Jvaeyhcd on 09/12/2019.
//  Copyright © 2016 Jvaeyhcd. All rights reserved.
//

#import "HCDPlayerVideoFrame.h"

@interface HCDPlayerVideoRGBFrame : HCDPlayerVideoFrame

@property (nonatomic) NSUInteger linesize;
@property (nonatomic) BOOL hasAlpha;

@end
