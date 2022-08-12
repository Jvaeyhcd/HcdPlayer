//
//   PlaylistModel.h
//   HcdPlayer
//
//   Created  by Jvaeyhcd (https://github.com/Jvaeyhcd) on 2022/8/9
//   Copyright © 2022 Salvador. All rights reserved.
//
   

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlaylistModel : NSObject

@property (nonatomic, strong) NSNumber *id;

@property (nonatomic, copy) NSString *path;

@property (nonatomic, assign) CGFloat position;

@end

NS_ASSUME_NONNULL_END
