//
//   PlaylistModelDap.m
//   HcdPlayer
//
//   Created  by Jvaeyhcd (https://github.com/Jvaeyhcd) on 2022/8/9
//   Copyright © 2022 Salvador. All rights reserved.
//
   

#import "PlaylistModelDao.h"
#import "MJExtension.h"

@implementation PlaylistModelDao

SingletonM(PlaylistModelDao)

- (BOOL)createOrUpgradeTable {
    __block BOOL isSuccess = NO;
    
    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        if (![db open]) {
            DLog(@"open db failed!");
            return ;
        };
        NSMutableString *sql = [[NSMutableString alloc]init];
        
        if ([db tableExists:@"PlaylistModel"]) {
            
        } else {
            [sql appendString:@"CREATE TABLE PlaylistModel (id integer PRIMARY KEY autoincrement, path varchar(200), position float);"];
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
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM PlaylistModel ORDER BY id DESC"];
        FMResultSet *rs = [db executeQuery:sql];
     
        while ([rs next]) {

            PlaylistModel *playlist = [PlaylistModel mj_objectWithKeyValues:[rs resultDictionary]];
 
            [array addObject:playlist];
        }
    }];
    
    return array;
}

- (BOOL)clearAll {
    __block BOOL isRollBack = NO;
    
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        
        [db beginTransaction];
        
        @try {
            NSMutableString *sql = [[NSMutableString alloc] initWithString:@"DELETE FROM PlaylistModel"];
            if(![db executeUpdate:sql]){
                
            }
        } @catch (NSException *exception) {
            isRollBack = YES;
            [db rollback];
        } @finally {
            if (!isRollBack) {
                [db commit];
            }
        }
       
    }];
    return !isRollBack;
}

- (PlaylistModel *)findPlaylistByPath:(NSString *)path {
    __block NSMutableArray *array = [NSMutableArray array];
    
    [self.dbQueue inDatabase:^(FMDatabase *db) {
       
        NSMutableString *sql = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"SELECT * FROM PlaylistModel WHERE path = '%@'", path]];
        FMResultSet *rs = [db executeQuery:sql];
        
        while ([rs next]) {
            
            id instanceOfNewClass = [[PlaylistModel alloc]init];
            
            for (NSString *propertyName in [self getClassProperty:[PlaylistModel class]]) {
                [instanceOfNewClass setValue:[rs objectForColumn:propertyName] forKey:propertyName];
            }
            [array addObject:instanceOfNewClass];
        }

    }];
    if ([array count] > 0) {
        return [array objectAtIndex:0];
    }
    return nil;
}

- (NSArray *)getClassProperty:(Class)cls {
    if (!cls) return @[];
    
    NSMutableArray * all_p = [NSMutableArray array];
    unsigned int a;
    
    objc_property_t * result = class_copyPropertyList(cls, &a);
    
    for (unsigned int i = 0; i < a; i++) {
        objc_property_t o_t =  result[i];
        [all_p addObject:[NSString stringWithFormat:@"%s", property_getName(o_t)]];
    }
    
    free(result);
    return [all_p copy];
}

@end
