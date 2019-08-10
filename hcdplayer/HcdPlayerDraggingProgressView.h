//
//  HcdPlayerDraggingProgressView.h
//  HcdPlayer
//
//  Created by Salvador on 2019/3/10.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HcdPlayerDraggingProgressView : UIView

@property (nonatomic, strong) UILabel *shiftTimeLabel;
@property (nonatomic, strong) UILabel *separatorLabel;    // `/`
@property (nonatomic, strong) UILabel *durationTimeLabel;

@property (nonatomic, strong) UIImageView *directionImageView;

@property (nonatomic) NSTimeInterval progressTime;

- (void)setProgressTimeStr:(NSString *)shiftTimeStr;
- (void)setProgressTimeStr:(NSString *)shiftTimeStr totalTimeStr:(NSString *)totalTimeStr;

- (void)show;

@end

NS_ASSUME_NONNULL_END
