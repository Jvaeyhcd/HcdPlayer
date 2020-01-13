//
//  HDownloadModelDao.h
//  HcdPlayer
//
//  Created by Salvador on 2020/1/13.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import "BaseDao.h"
#import "HSingleton.h"
#import "HDownloadModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface HDownloadModelDao : BaseDao

SingletonH(HDownloadModelDao)

- (NSArray *)queryAll;

@end

NS_ASSUME_NONNULL_END
