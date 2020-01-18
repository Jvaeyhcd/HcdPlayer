//
//  HDownloadModelDao.m
//  HcdPlayer
//
//  Created by Salvador on 2020/1/13.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import "HDownloadModelDao.h"
#import "MJExtension.h"

@implementation HDownloadModelDao

SingletonM(HDownloadModelDao)

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
        
        if ([db tableExists:@"HDownloadModel"]) {
            
        } else {
            [sql appendString:@"CREATE TABLE HDownloadModel (id integer PRIMARY KEY autoincrement, type integer, hostName varchar(200), ipAddress varchar(200), username varchar(200), password varchar(200), filePath varchar(200), localPath varchar(200), progress float, size double, status integer, statusText varchar(200));"];
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
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM HDownloadModel ORDER BY id DESC"];
        FMResultSet *rs = [db executeQuery:sql];
     
        while ([rs next]) {

            HDownloadModel *download = [HDownloadModel mj_objectWithKeyValues:[rs resultDictionary]];
 
            [array addObject:download];
        }
    }];
    
    return array;
}

@end
