//
//  NetworkServiceDao.m
//  HcdPlayer
//
//  Created by Salvador on 2020/1/3.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import "NetworkServiceDao.h"
#import "MJExtension.h"

@implementation NetworkServiceDao

SingletonM(NetworkServiceDao)

- (BOOL)createOrUpgradeTable {
    
    __block BOOL isSuccess = NO;
    
    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        if (![db open]) {
#if DEBUG
            NSLog(@"open db failed!");
#endif
            return ;
        };
        NSMutableString *sql = [[NSMutableString alloc]init];
        
        if ([db tableExists:@"NetworkService"]) {
            
        } else {
            [sql appendString:@"CREATE TABLE NetworkService (id integer PRIMARY KEY autoincrement, type integer, title varchar(200), host varchar(200), port varchar(20), path varchar(20), userName varchar, password varchar(20));"];
        }
        
        if(sql.length > 0 && [db executeStatements:sql]){
            isSuccess = YES;
        }
    }];
    
    return isSuccess;
}

- (NSArray *)queryAll {
    
    __block NSMutableArray *array = [NSMutableArray array];
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM NetworkService"];
        FMResultSet *rs = [db executeQuery:sql];
     
        while ([rs next]) {

            NetworkService *service = [NetworkService mj_objectWithKeyValues:[rs resultDictionary]];
 
            [array addObject:service];
        }
    }];
    
    return array;
}

@end
