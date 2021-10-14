//
//  UIViewController+Hcd.h
//  HcdPlayer
//
//  Created by Salvador on 2019/1/21.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <UIKit/UIKit.h>

#define LEFT 1
#define RIGHT 2

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (Hcd)

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

- (void)popViewController:(BOOL)animated;

- (void)showBarButtonItemWithStr:(NSString *)str position:(NSInteger)position;

- (void)showBarButtonItemWithImage:(UIImage *)image position:(NSInteger)position;

- (void)setNavigationBarBackgroundColor:(UIColor *)color
                             titleColor:(UIColor *)titleColor;

@end

NS_ASSUME_NONNULL_END
