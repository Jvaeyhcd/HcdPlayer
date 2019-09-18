//
//  RemoteControlView.h
//  HcdPlayer
//
//  Created by Salvador on 2019/9/15.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 遥控板界面
 */
@interface RemoteControlView : UIView

/**
 状态UILabel
 */
@property (nonatomic, strong) UILabel *statusLbl;

/**
 退出按钮
 */
@property (nonatomic, strong) UIButton *quitBtn;

/**
 切换设备按钮
 */
@property (nonatomic, strong) UIButton *changeBtn;

- (void)show;

- (void)hide;

@end

NS_ASSUME_NONNULL_END
