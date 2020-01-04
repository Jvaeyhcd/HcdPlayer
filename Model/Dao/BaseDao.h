//
//  BaseDao.h
//  HcdPlayer
//
//  Created by Salvador on 2020/1/3.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "FMDatabaseAdditions.h"

NS_ASSUME_NONNULL_BEGIN

@interface BaseDao : NSObject

@property (atomic,strong) FMDatabaseQueue *dbQueue;

-(BOOL)createOrUpgradeTable;

-(BOOL)insertData:(id)object;

-(BOOL)insertOrUpdateData:(id)object;

-(BOOL)updateData:(id)object;

-(BOOL)deleteData:(id)object;

-(NSMutableArray *)queryData:(id)object;

@end

NS_ASSUME_NONNULL_END
