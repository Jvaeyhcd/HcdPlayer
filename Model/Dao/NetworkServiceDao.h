//
//  NetworkServiceDao.h
//  HcdPlayer
//
//  Created by Salvador on 2020/1/3.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import "BaseDao.h"
#import "HSingleton.h"
#import "NetworkService.h"

NS_ASSUME_NONNULL_BEGIN

@interface NetworkServiceDao : BaseDao

SingletonH(NetworkServiceDao)

- (NSArray *)queryAll;

@end

NS_ASSUME_NONNULL_END
