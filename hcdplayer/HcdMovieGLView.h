//
//  HcdMovieGLView.h
//  HcdPlayer
//
//  Created by Salvador on 2019/1/15.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class HcdVideoFrame;
@class HcdMovieDecoder;

@interface HcdMovieGLView : UIView

- (id) initWithFrame:(CGRect)frame
             decoder: (HcdMovieDecoder *) decoder;

- (void) render: (HcdVideoFrame *) frame;

@end

NS_ASSUME_NONNULL_END
