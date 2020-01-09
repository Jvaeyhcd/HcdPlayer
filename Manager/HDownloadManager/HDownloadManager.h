//
//  HDownloadManager.h
//  HcdPlayer
//
//  Created by Salvador on 2020/1/9.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HDownloadModel;

NS_ASSUME_NONNULL_BEGIN

@interface HDownloadManager : NSObject

@property (nonatomic, readonly, strong) NSArray *downloadModels;

+ (instancetype)shared;

- (void)addDownloadModels:(NSArray<HDownloadModel *> *)downloadModels;

- (void)startWithDownloadModel:(HDownloadModel *)downloadModel;

- (void)suspendWithDownloadModel:(HDownloadModel *)downloadModel;

- (void)resumeWithDownloadModel:(HDownloadModel *)downloadModel;

- (void)stopWithDownloadModel:(HDownloadModel *)downloadModel;

@end

NS_ASSUME_NONNULL_END
