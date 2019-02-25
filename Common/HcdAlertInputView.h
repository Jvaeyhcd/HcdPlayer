//
//  HcdAlertInputView.h
//  HcdPlayer
//
//  Created by Salvador on 2019/1/24.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIPlaceHolderTextView.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^CommitBlock)(NSString *content);

@interface HcdAlertInputView : UIView

@property (nonatomic, weak) NSString *placeHolder;
@property (nonatomic, weak) NSString *tips;
@property (nonatomic, strong) CommitBlock commitBlock;

- (void)showReplyInView:(UIView *)view;
- (void)hideReplayView;

@end


NS_ASSUME_NONNULL_END
