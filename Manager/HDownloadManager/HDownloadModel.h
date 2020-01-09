//
//  HDownloadModel.h
//  HcdPlayer
//
//  Created by Salvador on 2020/1/9.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TOSMBClient.h"

@class HDownloadOperation;
@class HDownloadModel;

typedef NS_ENUM(NSInteger, HCDDownloadStatus) {
    HCDDownloadStatusNone = 0,       // 初始状态
    HCDDownloadStatusRunning = 1,    // 下载中
    HCDDownloadStatusSuspended = 2,  // 下载暂停
    HCDDownloadStatusCompleted = 3,  // 下载完成
    HCDDownloadStatusFailed  = 4,    // 下载失败
    HCDDownloadStatusWaiting = 5     // 等待下载
};

NS_ASSUME_NONNULL_BEGIN

typedef void(^HCDDownloadStatusChanged)(HDownloadModel *model);
typedef void(^HCDDownloadProgressChanged)(HDownloadModel *model);

@interface HDownloadModel : NSObject

/// 下载文件SMB服务器相关信息
@property (nonatomic, copy) NSString *hostName;
@property (nonatomic, copy) NSString *ipAddress;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *filePath;

/// 下载到本地的路径
@property (nonatomic, copy) NSString *localPath;

@property (nonatomic, assign) CGFloat progress;

@property (nonatomic, assign) HCDDownloadStatus status;
@property (nonatomic, strong) HDownloadOperation *operation;

@property (nonatomic, copy) HCDDownloadStatusChanged onStatusChanged;
@property (nonatomic, copy) HCDDownloadProgressChanged onProgressChanged;

@property (nonatomic, readonly, copy) NSString *statusText;

@end

NS_ASSUME_NONNULL_END
