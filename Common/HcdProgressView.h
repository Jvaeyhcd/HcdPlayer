//
//  HcdProgressView.h
//  HcdPlayer
//
//  Created by Salvador on 2019/3/15.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    HcdProgressDirectionLeftToRight,
    HcdProgressDirectionRightToLeft,
    HcdProgressDirectionBottomToTop,
    HcdProgressDirectionTopToBottom
} HcdProgressDirection;

NS_ASSUME_NONNULL_BEGIN

@interface HcdProgressView : UIView

@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, strong) UIColor *progressColor;
@property (nonatomic, assign) HcdProgressDirection direction;

@end

NS_ASSUME_NONNULL_END
