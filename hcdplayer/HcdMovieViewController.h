//
//  HcdMovieViewController.h
//  HcdPlayer
//
//  Created by Salvador on 2019/1/15.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class HcdMovieDecoder;

extern NSString * const HcdMovieParameterMinBufferedDuration;    // Float
extern NSString * const HcdMovieParameterMaxBufferedDuration;    // Float
extern NSString * const HcdMovieParameterDisableDeinterlacing;   // BOOL

@interface HcdMovieViewController : BaseViewController<UITableViewDataSource, UITableViewDelegate>

+ (id) movieViewControllerWithContentPath: (NSString *) path
                               parameters: (NSDictionary *) parameters;

/**
 * 视频的播放状态
 */
@property (readonly) BOOL playing;

/**
 * 开始播放
 */
- (void) play;

/**
 * 暂停播放
 */
- (void) pause;

@end

NS_ASSUME_NONNULL_END
