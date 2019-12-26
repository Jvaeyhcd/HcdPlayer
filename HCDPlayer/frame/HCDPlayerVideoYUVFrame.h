//
//  HCDPlayerVideoYUVFrame.h
//  HCDPlayer
//
//  Created by Jvaeyhcd on 09/12/2019.
//  Copyright © 2016 Jvaeyhcd. All rights reserved.
//

#import "HCDPlayerVideoFrame.h"

@interface HCDPlayerVideoYUVFrame : HCDPlayerVideoFrame

@property (nonatomic, strong) NSData *Y;    // Luma
@property (nonatomic, strong) NSData *Cb;   // Chroma Blue
@property (nonatomic, strong) NSData *Cr;   // Chroma Red

@end
