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

@interface HcdMovieViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

+ (id) movieViewControllerWithContentPath: (NSString *) path
                               parameters: (NSDictionary *) parameters;

@property (readonly) BOOL playing;

- (void) play;
- (void) pause;

@end

NS_ASSUME_NONNULL_END
