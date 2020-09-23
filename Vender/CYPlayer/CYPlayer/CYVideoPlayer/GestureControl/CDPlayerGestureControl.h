//
//  CDPlayerGestureControl.h
//  CDPlayerGestureControl
//
//  Created by yellowei on 2017/12/10.
//  Copyright © 2017年 yellowei. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CYPanDirection) {
    CYPanDirection_Unknown,
    CYPanDirection_V,
    CYPanDirection_H,
};

typedef NS_ENUM(NSUInteger, CYPanLocation) {
    CYPanLocation_Unknown,
    CYPanLocation_Left,
    CYPanLocation_Right,
};

@interface CDPlayerGestureControl : NSObject

@property (nonatomic, strong, readonly) UITapGestureRecognizer *singleTap;
@property (nonatomic, strong, readonly) UITapGestureRecognizer *doubleTap;
@property (nonatomic, strong, readonly) UIPanGestureRecognizer *panGR;

@property (nonatomic, weak, readwrite) UIView *targetView;
@property (nonatomic, assign, readwrite) CYPanDirection panDirection;
@property (nonatomic, assign, readwrite) CYPanLocation panLocation;


- (instancetype)initWithTargetView:(__weak UIView *)view;

@property (nonatomic, copy, readwrite, nullable) BOOL(^triggerCondition)(CDPlayerGestureControl *control, UIGestureRecognizer *gesture);

@property (nonatomic, copy, readwrite, nullable) void(^singleTapped)(CDPlayerGestureControl *control);
@property (nonatomic, copy, readwrite, nullable) void(^doubleTapped)(CDPlayerGestureControl *control);
@property (nonatomic, copy, readwrite, nullable) void(^beganPan)(CDPlayerGestureControl *control, CYPanDirection direction, CYPanLocation location);
@property (nonatomic, copy, readwrite, nullable) void(^changedPan)(CDPlayerGestureControl *control, CYPanDirection direction, CYPanLocation location, CGPoint translate);
@property (nonatomic, copy, readwrite, nullable) void(^endedPan)(CDPlayerGestureControl *control, CYPanDirection direction, CYPanLocation location);

@end

NS_ASSUME_NONNULL_END
