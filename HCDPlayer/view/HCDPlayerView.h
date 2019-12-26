//
//  HCDPlayerView.h
//  HCDPlayer
//
//  Created by Jvaeyhcd on 05/12/2019.
//  Copyright © 2016 Jvaeyhcd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HCDPlayerVideoFrame;

@interface HCDPlayerView : UIView

@property (nonatomic) CGSize contentSize;
@property (nonatomic) CGFloat rotation;
@property (nonatomic) BOOL isYUV;
@property (nonatomic) BOOL keepLastFrame;

- (void)render:(HCDPlayerVideoFrame *)frame;
- (void)clear;

@end
