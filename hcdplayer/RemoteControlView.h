//
//  RemoteControlView.h
//  HcdPlayer
//
//  Created by Salvador on 2019/9/15.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RemoteControlViewDelegate <NSObject>

@optional

/**
 点击切换设备
 */
- (void)didClickChangeDevice;

/**
 点击退出播放
 */
- (void)didClickQuitDLNAPlay;

@end

/**
 遥控板界面
 */
@interface RemoteControlView : UIView

/**
 设备名称UIlabel
 */
@property (nonatomic, strong) UILabel *deviceLbl;

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

@property (nonatomic, weak) id<RemoteControlViewDelegate> delegate;

- (void)show;

- (void)hide;

@end

NS_ASSUME_NONNULL_END
