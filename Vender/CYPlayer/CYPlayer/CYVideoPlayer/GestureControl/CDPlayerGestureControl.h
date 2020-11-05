//
//  CDPlayerGestureControl.h
//  CDPlayerGestureControl
//
//  Created by yellowei on 2017/12/10.
//  Copyright © 2017年 yellowei. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CDPanDirection) {
    CDPanDirection_Unknown,
    CDPanDirection_V,
    CDPanDirection_H,
};

typedef NS_ENUM(NSUInteger, CDPanLocation) {
    CDPanLocation_Unknown,
    CDPanLocation_Left,
    CDPanLocation_Right,
};

@interface CDPlayerGestureControl : NSObject

@property (nonatomic, strong, readonly) UITapGestureRecognizer *singleTap;
@property (nonatomic, strong, readonly) UITapGestureRecognizer *doubleTap;
@property (nonatomic, strong, readonly) UIPanGestureRecognizer *panGR;

@property (nonatomic, weak, readwrite) UIView *targetView;
@property (nonatomic, assign, readwrite) CDPanDirection panDirection;
@property (nonatomic, assign, readwrite) CDPanLocation panLocation;


- (instancetype)initWithTargetView:(__weak UIView *)view;

@property (nonatomic, copy, readwrite, nullable) BOOL(^triggerCondition)(CDPlayerGestureControl *control, UIGestureRecognizer *gesture);

@property (nonatomic, copy, readwrite, nullable) void(^singleTapped)(CDPlayerGestureControl *control);
@property (nonatomic, copy, readwrite, nullable) void(^doubleTapped)(CDPlayerGestureControl *control);
@property (nonatomic, copy, readwrite, nullable) void(^beganPan)(CDPlayerGestureControl *control, CDPanDirection direction, CDPanLocation location);
@property (nonatomic, copy, readwrite, nullable) void(^changedPan)(CDPlayerGestureControl *control, CDPanDirection direction, CDPanLocation location, CGPoint translate);
@property (nonatomic, copy, readwrite, nullable) void(^endedPan)(CDPlayerGestureControl *control, CDPanDirection direction, CDPanLocation location);

@end

NS_ASSUME_NONNULL_END
