//
//  CDFFmpegViewController.h
//  HcdPlayer
//
//  Created by Salvador on 2020/7/10.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CDFFmpegPlayer.h"
#import "PlaylistModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CDFFmpegViewController : BaseViewController

@property (nonatomic, copy) NSString *path;

@property (nonatomic, strong) PlaylistModel *playlistModel;

@end

NS_ASSUME_NONNULL_END
