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

@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, strong) UIColor *progressColor;

@end

NS_ASSUME_NONNULL_END
