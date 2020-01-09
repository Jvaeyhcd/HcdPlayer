//
//  HDownloadOperation.h
//  HcdPlayer
//
//  Created by Salvador on 2020/1/9.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TOSMBClient.h"

@class HDownloadModel;

NS_ASSUME_NONNULL_BEGIN

@interface TOSMBSessionTask(HDownloadModel)

@property (nonatomic, weak) HDownloadModel *hcd_downloadModel;

@end

@interface HDownloadOperation : NSOperation

- (instancetype)initWithModel:(HDownloadModel *)model;

@property (nonatomic, weak) HDownloadModel *model;

@property (nonatomic, strong, readonly) TOSMBSessionDownloadTask *downloadTask;

- (void)suspend;

- (void)resume;

- (void)downloadFinished;

@end

NS_ASSUME_NONNULL_END
