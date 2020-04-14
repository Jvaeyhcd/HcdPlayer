//
//  GadientLayerView.h
//  HcdPlayer
//
//  Created by Salvador on 2020/4/14.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 有渐变色的UIView
@interface GadientLayerView : UIView

/// 渐变色的Layer
@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@end

NS_ASSUME_NONNULL_END
