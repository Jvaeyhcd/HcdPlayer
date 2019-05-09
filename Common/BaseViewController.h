//
//  BaseViewController.h
//  HcdPlayer
//
//  Created by Salvador on 2019/3/5.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BaseViewController : UIViewController

/**
 * 强制转屏
 * @param orientation 屏幕旋转的方向
 */
- (void)setInterfaceOrientation:(UIInterfaceOrientation)orientation;

@end

NS_ASSUME_NONNULL_END
