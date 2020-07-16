//
//  CDMovieGLView.h
//  HcdPlayer
//
//  Created by Salvador on 2020/7/10.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CDVideoFrame;
@class CDPlayerDecoder;

NS_ASSUME_NONNULL_BEGIN

@interface CDMovieGLView : UIView

- (id)initWithFrame:(CGRect)frame decoder:(CDPlayerDecoder *)decoder;

- (void)render:(CDVideoFrame *)frame;

@end

NS_ASSUME_NONNULL_END
