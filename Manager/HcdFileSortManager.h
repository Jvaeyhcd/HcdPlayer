//
//  HcdFileSortManager.h
//  HcdPlayer
//
//  Created by Salvador on 2019/2/27.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kFileSortType @"FileSortType"
#define kFileOrderType @"FileOrderType"

enum {
    SortInfoSectionSort,
    SortInfoSectionOrder,
    SortInfoSectionCount,
};

typedef NS_ENUM(NSInteger, SortType) {
    SortTypeName,
    SortTypeSize,
    SortTypeDate,
    SortTypeCount,
};

typedef NS_ENUM(NSInteger, OrderType){
    OrderTypeAscending,
    OrderTypeDescending,
    OrderTypeCount,
};

NS_ASSUME_NONNULL_BEGIN

@interface HcdFileSortManager : NSObject

@property (nonatomic, assign) SortType sortType;
@property (nonatomic, assign) OrderType orderType;

+ (HcdFileSortManager *)sharedInstance;

- (void)setSortType:(SortType)sortType orderType:(OrderType)orderType;

- (NSMutableArray *)sortArray:(NSMutableArray *)array inPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
