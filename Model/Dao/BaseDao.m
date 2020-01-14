//
//  BaseDao.m
//  HcdPlayer
//
//  Created by Salvador on 2020/1/3.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import "BaseDao.h"
#import <objc/runtime.h>

@implementation BaseDao

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentDirectory = [paths objectAtIndex:0];
        NSString *dbPath = [documentDirectory stringByAppendingPathComponent:@"HcdPlayer.db"];
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    }
    return self;
}

- (BOOL)createOrUpgradeTable {
    return YES;
}

- (BOOL)insertData:(id)object {
    return [self insertData:object only:YES];
}

- (BOOL)insertOrUpdateData:(id)object {
    return [self insertData:object only:NO];
}

- (BOOL)updateData:(id)object {
    return [self insertData:object only:NO];
}

- (NSMutableArray *)queryData:(id)object {
    
    __block NSMutableArray *array = [NSMutableArray array];
    
    [self.dbQueue inDatabase:^(FMDatabase *db) {
       
        [self getObjectPropertiesAndValues:^(NSMutableArray *propertyArray, NSMutableArray *valueArray) {
            
            NSMutableArray *allPropertyArray = [self getObjectProperties:object];
            
            NSMutableString *sql = [[NSMutableString alloc] initWithString:@"SELECT * FROM "];
            [sql appendString:[NSString stringWithUTF8String:object_getClassName(object)]];
            
            NSInteger pCount = propertyArray.count;
            if (pCount > 0) {
                [sql appendString:@" WHERE "];
                for (int i = 0; i < pCount; i++) {
                    
                    id value = valueArray[i];
                    if ([value isKindOfClass:[NSString class]]) {
                        value = [NSString stringWithFormat:@"'%@'",value];
                    }
                    if (i == (pCount - 1)) {
                        [sql appendFormat:@"%@ = %@", propertyArray[i], value];
                    }else{
                        [sql appendFormat:@"%@ = %@ AND ", propertyArray[i],value];
                    }
                    
                }
            }
            
            FMResultSet *rs = [db executeQuery:sql];
            
            while ([rs next]) {
                
                id instanceOfNewClass = [[[object class] alloc]init];
                
                for (NSString *propertyName in allPropertyArray) {
                    [instanceOfNewClass setValue:[rs objectForColumn:propertyName] forKey:propertyName];
                }
                [array addObject:instanceOfNewClass];
            }
            
        } obj:object];

    }];
    return array;
}

- (BOOL)deleteData:(id)object {
    
    __block BOOL isRollBack = NO;
    
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        
        [db beginTransaction];
        
        @try {
            NSMutableArray *array = [NSMutableArray array];
            if ([object isKindOfClass:[NSArray class]]) {
                array = object;
            }else{
                [array addObject:object];
            }
            
            id tempObj = array[0];
            NSString *tableName = [NSString stringWithUTF8String:object_getClassName(tempObj)];
            
            for (NSObject *obj in array) {
                
                [self getObjectPropertiesAndValues:^(NSMutableArray *propertyArray, NSMutableArray *valueArray) {
                    
                    NSMutableString *sql = [[NSMutableString alloc] initWithString:@"DELETE FROM "];
                    [sql appendString:tableName];
                    
                    NSInteger pCount = propertyArray.count;
                    if (pCount > 0) {
                        [sql appendString:@" WHERE "];
                        for (int i = 0; i < pCount; i++) {
                            
                            id value = valueArray[i];
                            if ([value isKindOfClass:[NSString class]]) {
                                value = [NSString stringWithFormat:@"'%@'",value];
                            }
                            if (i == (pCount - 1)) {
                                [sql appendFormat:@"%@ = %@", propertyArray[i], value];
                            }else{
                                [sql appendFormat:@"%@ = %@ AND ", propertyArray[i],value];
                            }
                            
                        }
                    }
                    
                    if(![db executeUpdate:sql]){
                        
                    }
                    
                } obj:obj];
                
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

- (BOOL)insertData:(id)object only:(BOOL)only {
    if (!object) {
        return NO;
    }
    __block BOOL isRollBack = NO;
    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        
        [db beginTransaction];
        
        @try {
            
            NSMutableArray *array = [NSMutableArray array];
            
            if ([object isKindOfClass:[NSArray class]]) {
                array = object;
            } else {
                [array addObject:object];
            }
            
            if (array.count == 0) {
                return;
            }
            
            id tempObj = array[0];
            NSString *tableName = [NSString stringWithUTF8String:object_getClassName(tempObj)];
            
            for (NSObject *obj in array) {
                [self getObjectPropertiesAndValues:^(NSMutableArray *propertyArray, NSMutableArray *valueArray) {
                    
                    NSMutableString *sql = [[NSMutableString alloc] initWithString:@"INSERT OR REPLACE INTO "];
                    if (only) {
                        sql = [[NSMutableString alloc] initWithString:@"INSERT OR REPLACE INTO "];
                    }
                    [sql appendFormat:@"%@ (",tableName];
                    
                    // append keys
                    NSInteger pCount = propertyArray.count;
                    for (int i = 0; i < pCount; i++) {
                        if (i == (pCount-1)) {
                            [sql appendFormat:@"%@) VALUES (",propertyArray[i]];
                        } else {
                            [sql appendFormat:@"%@, ",propertyArray[i]];
                        }
                    }
                    
                    // append values
                    NSInteger vCount = valueArray.count;
                    for (int i = 0; i < vCount; i++) {
                        id value = valueArray[i];
                        if ([value isKindOfClass:[NSString class]]) {
                            value = [NSString stringWithFormat:@"'%@'", value];
                        }
                        if (i == (vCount-1)) {
                            [sql appendFormat:@"%@)", value];
                        } else {
                            [sql appendFormat:@"%@, ", value];
                        }
                    }
                    
                    if(![db executeUpdate:sql]){
#if DEBUG
                        NSLog(@"inster or update data failed!");
#endif
                    }
                } obj:obj];
            }
        } @catch (NSException *exception) {
            // roll back
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


/// 获取对象的属性键和值
/// @param block 获取成功后的回调
/// @param obj 指定对象
-(void)getObjectPropertiesAndValues:(void (^)(NSMutableArray *propertyArray, NSMutableArray *valueArray))block obj:(NSObject *)obj{
    
    NSMutableArray *propertyArray = [NSMutableArray array];
    NSMutableArray *valueArray = [NSMutableArray array];
    
    NSArray *all_p = [self getAllProperty:[obj class]];
    NSLog(@"%ld", all_p.count);
    
    NSUInteger propsCount = all_p.count;
    for(int i = 0;i < propsCount; i++) {
        
        NSString *propertyName = [all_p objectAtIndex:i];
        id value = [obj valueForKey:propertyName];
        
        if (value != nil && value != NULL && ![value isKindOfClass:[NSNull class]]) {
            [propertyArray addObject:propertyName];
            [valueArray addObject:value];
        }
    }
    block(propertyArray,valueArray);
}

/// 获取对象属性值
/// @param obj 对象
-(NSMutableArray *)getObjectProperties:(NSObject *)obj{
    
    NSMutableArray *propertyArray = [NSMutableArray array];
    
    unsigned int propsCount;
    objc_property_t *props = class_copyPropertyList([obj class], &propsCount);
    for(int i = 0;i < propsCount; i++) {
        objc_property_t prop = props[i];
        
        [propertyArray addObject:[NSString stringWithUTF8String:property_getName(prop)]];
    }
    free(props);
    return propertyArray;
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

- (NSArray *)getAllProperty:(Class)cls {
    
    Class stop_class = [NSObject class];
    
    if (cls == stop_class) return @[];
    
    NSMutableArray * all_p = [NSMutableArray array];
    
    [all_p addObjectsFromArray:[self getClassProperty:cls]];
    
    if (class_getSuperclass(cls) == stop_class) {
        return [all_p copy];
    } else {
        [all_p addObjectsFromArray:[self getAllProperty:[cls superclass]]];
    }
    
    return [all_p copy];
}

@end
