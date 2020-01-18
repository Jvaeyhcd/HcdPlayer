//
//  HDownloadManager.m
//  HcdPlayer
//
//  Created by Salvador on 2020/1/9.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import "HDownloadManager.h"
#import "HDownloadModel.h"
#import "HDownloadOperation.h"
#import "TOSMBClient.h"
#import "HDownloadModelDao.h"

static HDownloadManager *_h_downloadManager = nil;

@interface HDownloadManager() {
    NSMutableArray *_downloadModels;
}

@property (nonatomic, strong) NSOperationQueue *queue;

@end

@implementation HDownloadManager

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _h_downloadManager = [[self alloc] init];
    });
    return _h_downloadManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _downloadModels = [[NSMutableArray alloc] init];
        
        NSArray *historyArray = [[HDownloadModelDao sharedHDownloadModelDao] queryAll];
        if (historyArray && historyArray.count > 0) {
            [_downloadModels addObjectsFromArray:historyArray];
        }

        self.queue = [[NSOperationQueue alloc] init];
        self.queue.maxConcurrentOperationCount = 4;
    }
    return self;
}

- (NSArray *)downloadModels {
    return _downloadModels;
}

- (void)addDownloadModels:(NSArray<HDownloadModel *> *)downloadModels {
    if ([downloadModels isKindOfClass:[NSArray class]]) {
        NSIndexSet *indexSet = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(0, downloadModels.count)];
        [_downloadModels insertObjects:downloadModels atIndexes:indexSet];
    }
}

- (void)addDownloadModel:(HDownloadModel *)downloadModel {
    [_downloadModels insertObject:downloadModel atIndex:0];
}

- (void)startWithDownloadModel:(HDownloadModel *)downloadModel {
    if (downloadModel.status != HCDDownloadStatusCompleted) {
        downloadModel.status = HCDDownloadStatusRunning;
        
        if (downloadModel.operation == nil) {
            downloadModel.operation = [[HDownloadOperation alloc] initWithModel:downloadModel];
            [downloadModel.operation start];
        } else {
            [downloadModel.operation resume];
        }
    }
}

- (void)suspendWithDownloadModel:(HDownloadModel *)downloadModel {
    if (downloadModel.status != HCDDownloadStatusCompleted) {
        [downloadModel.operation suspend];
    }
}

- (void)resumeWithDownloadModel:(HDownloadModel *)downloadModel {
    if (downloadModel.status != HCDDownloadStatusCompleted) {
        [downloadModel.operation resume];
    }
}

- (void)stopWithDownloadModel:(HDownloadModel *)downloadModel {
    if (downloadModel.operation) {
        [downloadModel.operation cancel];
    }
}

- (void)deleteDownloadModel:(HDownloadModel *)downloadModel {
    if (downloadModel.operation) {
        [downloadModel.operation cancel];
    }
    if (downloadModel.id) {
        [[HDownloadModelDao sharedHDownloadModelDao] deleteData:downloadModel];
    }
    [_downloadModels removeObject:downloadModel];
}

- (void)deleteAllDownloadModels {
    NSMutableArray *tempArr = _downloadModels;
    NSArray *array = [NSArray arrayWithArray:tempArr];
    for (HDownloadModel *model in array) {
        [self deleteDownloadModel:model];
    }
}

@end
