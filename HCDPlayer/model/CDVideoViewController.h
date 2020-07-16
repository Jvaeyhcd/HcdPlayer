//
//  CDVideoViewController.h
//  HcdPlayer
//
//  Created by Salvador on 2020/7/10.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CDPlayerDecoder;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const CDMovieParameterMinBufferedDuration;    // Float
extern NSString * const CDMovieParameterMaxBufferedDuration;    // Float
extern NSString * const CDMovieParameterDisableDeinterlacing;   // BOOL

@interface CDVideoViewController : BaseViewController

+ (id)movieViewControllerWithContentPath:(NSString *)path
                              parameters:(NSDictionary *)parameters;

@property (readonly) BOOL playing;

- (void)play;
- (void)pause;

@end

NS_ASSUME_NONNULL_END
