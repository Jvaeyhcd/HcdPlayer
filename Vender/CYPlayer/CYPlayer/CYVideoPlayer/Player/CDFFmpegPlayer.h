//
//  CDFFmpegPlayer.h
//  CYPlayer
//
//  Created by 黄威 on 2018/7/19.
//  Copyright © 2018年 Sutan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CYPlayerGestureControl.h"
#import "CYPlayerDecoder.h"
#import "CYVideoPlayerSettings.h"
#import "CYPlayerGLView.h"
#import "CYFFmpegMetalView.h"

@class
CYPlayerDecoder,
CYVideoPlayerSettings,
CYPrompt,
CYVideoFrame,
CYVideoPlayerMoreSetting;

typedef void(^LockScreen)(BOOL isLock);

typedef NS_ENUM(NSUInteger, CDFFmpegPlayerPlayState) {
    CDFFmpegPlayerPlayState_Unknown = 0,
    CDFFmpegPlayerPlayState_Prepare,
    CDFFmpegPlayerPlayState_Playing,
    CDFFmpegPlayerPlayState_Buffing,
    CDFFmpegPlayerPlayState_Pause,
    CDFFmpegPlayerPlayState_PlayEnd,
    CDFFmpegPlayerPlayState_PlayFailed,
    CDFFmpegPlayerPlayState_Ready
};


typedef void (^CYPlayerImageGeneratorCompletionHandler)(NSMutableArray<CYVideoFrame *> * _Nullable frames, NSError * _Nullable error);

typedef void (^CYPlayerSelectionsHandler)(NSInteger selectionsNumber);


extern NSString * _Nullable const CDPlayerParameterMinBufferedDuration;    // Float
extern NSString * _Nullable const CDPlayerParameterMaxBufferedDuration;    // Float
extern NSString * _Nullable const CDPlayerParameterDisableDeinterlacing;   // BOOL

# pragma mark - CDFFmpegPlayer

@class CDFFmpegPlayer,
CYLoadingView,
CYVolBrigControl;

@protocol CDFFmpegPlayerDelegate <NSObject>

- (void)cdFFmpegPlayer:(CDFFmpegPlayer *_Nullable)player onShareBtnCick:(UIButton *_Nullable)btn;

- (void)cdFFmpegPlayerStartAutoPlaying:(CDFFmpegPlayer *_Nullable)player;

- (void)cdFFmpegPlayer:(CDFFmpegPlayer *_Nullable)player changeStatus:(CDFFmpegPlayerPlayState)state;

- (void)cdFFmpegPlayer:(CDFFmpegPlayer *_Nullable)player updatePosition:(CGFloat)position duration:(CGFloat)duration isDrag:(BOOL)isdrag;

- (void)cdFFmpegPlayer:(CDFFmpegPlayer *_Nullable)player controlViewDisplayStatus:(BOOL)isHidden;

- (void)cdFFmpegPlayer:(CDFFmpegPlayer *_Nullable)player changeDefinition:(CYFFmpegPlayerDefinitionType)definition;

- (void)cdFFmpegPlayer:(CDFFmpegPlayer *_Nullable)player setSelectionsNumber:(CYPlayerSelectionsHandler _Nullable )setNumHandler;

- (void)cdFFmpegPlayer:(CDFFmpegPlayer *_Nullable)player changeSelections:(NSInteger)selectionsNum;

@end

@interface CDFFmpegPlayer : NSObject

+ (instancetype _Nullable )sharedPlayer;

+ (id _Nullable ) movieViewWithContentPath: (NSString *_Nullable) path
                                parameters: (NSDictionary *_Nullable) parameters;

- (void)setupPlayerWithPath:(NSString *_Nullable)path;

- (void)setupPlayerWithPath:(NSString *_Nullable)path parameters: (NSDictionary *_Nullable) parameters;

- (void)changeDefinitionPath:(NSString *_Nullable)path;
- (void)changeSelectionsPath:(NSString *_Nullable)path;
- (void)changeLiveDefinitionPath:(NSString *_Nullable)path;


@property (nonatomic, strong) CYPlayerDecoder * _Nullable decoder;

@property (nonatomic, weak) id<CDFFmpegPlayerDelegate> _Nullable delegate;

/*!
 *  present View. support autoLayout.
 *
 *  播放器视图
 */
@property (nonatomic, strong) UIView * _Nullable view;
@property (nonatomic, strong) UIView * _Nullable presentView;
@property (nonatomic, strong) CYPlayerGLView * _Nullable glView;
@property (nonatomic, strong) CYFFmpegMetalView * _Nullable metalView;
@property (nonatomic, strong) CYLoadingView * _Nullable loadingView;
@property (nonatomic, strong) CYPlayerGestureControl * _Nullable gestureControl;

@property (readonly) BOOL playing;

@property (nonatomic, assign, readonly) CDFFmpegPlayerPlayState state;

@property (nonatomic, assign, readwrite) BOOL generatPreviewImages;

/// 页面显示
- (void)viewDidAppear;

/// 页面隐藏
- (void)viewWillDisappear;

/// 生成预览图
/// @param imagesCount 预览图个数
/// @param handler 生成预览图完成后的回调
- (void)generatedPreviewImagesWithCount:(NSInteger)imagesCount
                      completionHandler:(CYPlayerImageGeneratorCompletionHandler _Nullable )handler;

/// 设置播放的位置
/// @param position 播放的位置
/// @param playMode 是否立即播放
- (void)setMoviePosition:(CGFloat)position playMode:(BOOL)playMode;

/// 视频当前播放到的时间
- (double)currentTime;

/// 视频的总时长
- (NSTimeInterval)totalTime;

@end

# pragma mark -

@interface CDFFmpegPlayer (State)


@property (nonatomic, assign, readwrite, getter=isHiddenControl) BOOL hideControl;

@property (nonatomic, assign, readwrite, getter=isLockedScrren) BOOL lockScreen;


- (void)_cancelDelayHiddenControl;

- (void)_delayHiddenControl;

- (void)_prepareState;

- (void)_readyState;

- (void)_playState;

- (void)_pauseState;

- (void)_playEndState;

- (void)_playFailedState;

- (void)_unknownState;

@end

# pragma mark -

@interface CDFFmpegPlayer (Setting)

/*!
 *  clicked back btn exe block.
 *
 *  点击返回按钮的回调.
 */
@property (nonatomic, copy, readwrite) void(^ _Nullable clickedBackEvent)(CDFFmpegPlayer * _Nullable player);

/*!
 *  Whether screen rotation is disabled. default is NO.
 *
 *  是否禁用屏幕旋转, 默认是NO.
 */
@property (nonatomic, assign, readwrite) BOOL disableRotation;

@property (nonatomic, assign, readwrite) float rate; /// 0.5 .. 1.5

@property (nonatomic, copy, readwrite, nullable) void(^rotatedScreen)(CDFFmpegPlayer * _Nullable player, BOOL isFullScreen);

@property (nonatomic, copy, readwrite, nullable) void(^controlViewDisplayStatus)(CDFFmpegPlayer * _Nullable player, BOOL displayed);

/*!
 *  Call when the rate changes.
 *
 *  调速时调用.
 *  当滑动内部的`rate slider`时候调用. 外部改变`rate`不会调用.
 **/
@property (nonatomic, copy, readwrite, nullable) void(^internallyChangedRate)(CDFFmpegPlayer * _Nullable player, float rate);

/*!
 *  配置播放器, 注意: 这个`block`在子线程运行.
 **/
- (void)settingPlayer:(void(^_Nullable)(CYVideoPlayerSettings * _Nullable settings))block;

/// 重置配置
- (void)resetSetting;

- (CYVideoPlayerSettings *_Nullable)settings;


/*!
 *  Call when the rate changes.
 *
 *  调速时调用.
 **/
@property (nonatomic, copy, readwrite, nullable) void(^rateChanged)(CDFFmpegPlayer * _Nullable player);

/*!
 *  default is YES.
 *
 *  是否自动播放, 默认是 YES.
 */
@property (nonatomic, assign, readwrite, getter=isAutoplay) BOOL autoplay;

/*!
 *  clicked More button to display items.
 *
 * _Nullable 点击更多按钮, 弹出来的选项.
 **/
@property (nonatomic, strong, readwrite, nullable) NSArray<CYVideoPlayerMoreSetting *> *moreSettings;

@end


#pragma mark - CYVideoPlayer (Control)
@protocol CYFFmpegControlDelegate <NSObject>

@optional

- (BOOL)cdFFmpegPlayer:(CDFFmpegPlayer *_Nullable)player
      triggerCondition:(CYPlayerGestureControl *_Nullable)control
               gesture:(UIGestureRecognizer *_Nullable)gesture;

- (void)cdFFmpegPlayer:(CDFFmpegPlayer *_Nullable)player
          singleTapped:(CYPlayerGestureControl *_Nullable)control;

- (void)cdFFmpegPlayer:(CDFFmpegPlayer *_Nullable)player
          doubleTapped:(CYPlayerGestureControl *_Nullable)control;

- (void)cdFFmpegPlayer:(CDFFmpegPlayer *_Nullable)player
              beganPan:(CYPlayerGestureControl *_Nullable)control
             direction:(CYPanDirection)direction location:(CYPanLocation)location;

- (void)cdFFmpegPlayer:(CDFFmpegPlayer *_Nullable)player
            changedPan:(CYPlayerGestureControl *_Nullable)control
             direction:(CYPanDirection)direction
              location:(CYPanLocation)location;

- (void)cdFFmpegPlayer:(CDFFmpegPlayer *_Nullable)player
              endedPan:(CYPlayerGestureControl *_Nullable)control
             direction:(CYPanDirection)direction
              location:(CYPanLocation)location;

@end



@interface CDFFmpegPlayer (Control)



- (BOOL)play;

- (BOOL)pause;

- (void)stop;

- (void)hideBackBtn;

- (void)showBackBtn;

@property (nonatomic, copy) LockScreen _Nullable lockscreen;

@property (nonatomic, weak) id<CYFFmpegControlDelegate> _Nullable control_delegate;

@end

#pragma mark -

@interface CDFFmpegPlayer (Prompt)

@property (nonatomic, strong, readonly) CYPrompt * _Nullable prompt;

/*!
 *  duration default is 1.0
 */
- (void)showTitle:(NSString *_Nullable)title;

/*!
 *  duration if value set -1, promptView will always show.
 */
- (void)showTitle:(NSString *_Nullable)title duration:(NSTimeInterval)duration;

- (void)hiddenTitle;

@end
