//
//  HcdFileSortManager.m
//  HcdPlayer
//
//  Created by Salvador on 2019/2/27.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "HcdFileSortManager.h"
#import "HcdFileManager.h"

@implementation HcdFileSortManager

+ (HcdFileSortManager *)sharedInstance {
    static HcdFileSortManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[HcdFileSortManager alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initSortAndOrderType];
    }
    return self;
}

- (void)initSortAndOrderType {
    NSInteger sortType = [[NSUserDefaults standardUserDefaults] integerForKey:kFileSortType];
    NSInteger orderType = [[NSUserDefaults standardUserDefaults] integerForKey:kFileOrderType];
    _orderType = orderType;
    _sortType = sortType;
}

- (void)setSortType:(SortType)sortType orderType:(OrderType)orderType {
//    [[NSUserDefaults standardUserDefaults] ]
    _orderType = orderType;
    _sortType = sortType;
    [[NSUserDefaults standardUserDefaults] setInteger:sortType forKey:kFileSortType];
    [[NSUserDefaults standardUserDefaults] setInteger:orderType forKey:kFileOrderType];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSMutableArray *)sortArray:(NSMutableArray *)array inPath:(NSString *)path {
    switch (_sortType) {
        case SortTypeName:
            return [self sortByNameArray:array inPath:path];
        case SortTypeDate:
            return [self sortByDateArray:array inPath:path];
        case SortTypeSize:
            return [self sortBySizeArray:array inPath:path];
        default:
            return array;
    }
}

NSInteger nameSort(id string1, id string2, void *reverse)
{
    if (*(BOOL *)reverse == YES) {
        
        return [string2 localizedCaseInsensitiveCompare:string1];
    }
    return [string1 localizedCaseInsensitiveCompare:string2];
}


- (NSMutableArray *)sortByNameArray:(NSMutableArray *)array inPath:(NSString *)path {
    BOOL reverseSort = NO;
    if (_orderType == OrderTypeDescending) {
        reverseSort = YES;
    }
    NSArray *sortedArray = [array sortedArrayUsingFunction:nameSort context:&reverseSort];
    if (sortedArray) {
        return [sortedArray mutableCopy];
    }
    return array;
}

- (NSMutableArray *)sortByDateArray:(NSMutableArray *)array inPath:(NSString *)path {
    BOOL reverseSort = NO;
    if (_orderType == OrderTypeDescending) {
        reverseSort = YES;
    }
    NSArray *sortedArray = [array sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSString *file1 = (NSString *)obj1;
        NSString *file2 = (NSString *)obj2;
        NSDictionary *fileInfo1 = [[HcdFileManager defaultManager] getFileInfoByPath:[NSString stringWithFormat:@"%@/%@", path, file1]];
        NSDictionary *fileInfo2 = [[HcdFileManager defaultManager] getFileInfoByPath:[NSString stringWithFormat:@"%@/%@", path, file2]];
        if ([[fileInfo1 fileCreationDate] timeIntervalSince1970] < [[fileInfo2 fileCreationDate] timeIntervalSince1970]) {
            return reverseSort ? NSOrderedDescending : NSOrderedAscending;
        } else if ([[fileInfo1 fileCreationDate] timeIntervalSince1970] > [[fileInfo2 fileCreationDate] timeIntervalSince1970]) {
            return reverseSort ? NSOrderedAscending : NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
    if (sortedArray) {
        return [sortedArray mutableCopy];
    }
    return array;
}

- (NSMutableArray *)sortBySizeArray:(NSMutableArray *)array inPath:(NSString *)path {
    BOOL reverseSort = NO;
    if (_orderType == OrderTypeDescending) {
        reverseSort = YES;
    }
    NSArray *sortedArray = [array sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSString *file1 = (NSString *)obj1;
        NSString *file2 = (NSString *)obj2;
        float fileSize1 = [[HcdFileManager defaultManager] sizeOfPath:[NSString stringWithFormat:@"%@/%@", path, file1]];
        float fileSize2 = [[HcdFileManager defaultManager] sizeOfPath:[NSString stringWithFormat:@"%@/%@", path, file2]];
        if (fileSize1 < fileSize2) {
            return reverseSort ? NSOrderedDescending : NSOrderedAscending;
        } else if (fileSize1 > fileSize2) {
            return reverseSort ? NSOrderedAscending : NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
    if (sortedArray) {
        return [sortedArray mutableCopy];
    }
    return array;
}


@end
