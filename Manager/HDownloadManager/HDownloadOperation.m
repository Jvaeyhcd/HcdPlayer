//
//  HDownloadOperation.m
//  HcdPlayer
//
//  Created by Salvador on 2020/1/9.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import "HDownloadOperation.h"
#import "HDownloadModel.h"
#import <objc/runtime.h>

#define kKVOBlock(KEYPATH, BLOCK) \
[self willChangeValueForKey:KEYPATH]; \
BLOCK(); \
[self didChangeValueForKey:KEYPATH];

@interface HDownloadOperation ()<TOSMBSessionDownloadTaskDelegate> {
    BOOL _finished;
    BOOL _executing;
}

@property (nonatomic, strong) TOSMBSessionDownloadTask *task;

@property (nonatomic, strong) TOSMBSession *session;

@end

@implementation HDownloadOperation

- (instancetype)initWithModel:(HDownloadModel *)model {
    if (self = [super init]) {
        self.model = model;
    }
    return self;
}

- (void)dealloc
{
    self.task = nil;
}

- (void)start {
    
    [self statRequest];
}

- (void)statRequest {
    
    self.session = [[TOSMBSession alloc] init];
    if (![NSString isBlankString:self.model.hostName]) {
        self.session.hostName = self.model.hostName;
    }
    if (![NSString isBlankString:self.model.ipAddress]) {
        self.session.ipAddress = self.model.ipAddress;
    }
    if (![NSString isBlankString:self.model.username]) {
        self.session.userName = self.model.username;
    }
    if (![NSString isBlankString:self.model.password]) {
        self.session.password = self.model.password;
    }
    
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        strongSelf.task = [self.session downloadTaskForFileAtPath:self.model.filePath destinationPath:self.model.localPath delegate:self];
        
        [strongSelf.task resume];
    });
    
    [self configTask];
}

- (void)configTask {
    self.task.hcd_downloadModel = self.model;
}

#pragma mark - TOSMBSessionDownloadTaskDelegate

- (void)downloadTask:(TOSMBSessionDownloadTask *)downloadTask didWriteBytes:(uint64_t)bytesWritten totalBytesReceived:(uint64_t)totalBytesReceived totalBytesExpectedToReceive:(int64_t)totalBytesToReceive
{
    CGFloat progress = totalBytesReceived / (float)totalBytesToReceive;
    NSLog(@"download progress:%.2f", progress);
    self.model.progress = progress;
    self.model.status = HCDDownloadStatusRunning;
}

- (void)downloadTask:(TOSMBSessionDownloadTask *)downloadTask didFinishDownloadingToPath:(NSString *)destinationPath
{
    self.model.status = HCDDownloadStatusCompleted;
}

- (void)downloadFinished {
    
}

- (void)resume {
    
}

- (void)suspend {
    
}

@end

static const void *s_hcd_downloadModelKey = "s_hcd_downloadModelKey";

@implementation TOSMBSessionTask(HDownloadModel)

- (void)setHcd_downloadModel:(HDownloadModel *)hcd_downloadModel {
    objc_setAssociatedObject(self, s_hcd_downloadModelKey, hcd_downloadModel, OBJC_ASSOCIATION_ASSIGN);
}

- (HDownloadModel *)hcd_downloadModel {
    return objc_getAssociatedObject(self, s_hcd_downloadModelKey);
}

@end
