//
//   PlaylistModelDap.h
//   HcdPlayer
//
//   Created  by Jvaeyhcd (https://github.com/Jvaeyhcd) on 2022/8/9
//   Copyright © 2022 Salvador. All rights reserved.
//
   

#import "BaseDao.h"
#import "HSingleton.h"
#import "PlaylistModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface PlaylistModelDao : BaseDao

SingletonH(PlaylistModelDao)

// 查询所有数据
- (NSArray *)queryAll;

// 删除所有数据
- (BOOL)clearAll;

// 根据播放路径查找播放记录
- (PlaylistModel *)findPlaylistByPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
