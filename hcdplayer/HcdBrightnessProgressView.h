//
//  HcdBrightnessProgressView.h
//  HcdPlayer
//
//  Created by Salvador on 2019/3/15.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HcdBrightnessProgressView : UIView

/**
 进度百分比0~1
 */
@property (nonatomic, assign) CGFloat progress;

/**
 进度条颜色
 */
@property (nonatomic, strong) UIColor *progressColor;

- (void)show;

@end

NS_ASSUME_NONNULL_END
