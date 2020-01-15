//
//  DownloadModel.h
//  HcdPlayer
//
//  Created by Salvador on 2020/1/13.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, HCDDownloadStatus) {
    HCDDownloadStatusNone = 0,       // 初始状态
    HCDDownloadStatusRunning = 1,    // 下载中
    HCDDownloadStatusSuspended = 2,  // 下载暂停
    HCDDownloadStatusCompleted = 3,  // 下载完成
    HCDDownloadStatusFailed  = 4,    // 下载失败
    HCDDownloadStatusWaiting = 5     // 等待下载
};

typedef NS_ENUM(NSInteger, HCDDownloadType) {
    HCDDownloadTypeHTTP = 0,
    HCDDownloadTypeSMB = 1,
    HCDDownloadTypeFTP = 2,
    HCDDownloadTypeSFTP = 3
};

NS_ASSUME_NONNULL_BEGIN

@interface DownloadModel : NSObject

@property (nonatomic, strong) NSNumber *id;

/// 下载的类型
@property (nonatomic, assign) HCDDownloadType type;
/// 下载文件SMB服务器相关信息
@property (nonatomic, copy) NSString *hostName;
@property (nonatomic, copy) NSString *ipAddress;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *filePath;

/// 下载到本地的路径
@property (nonatomic, copy) NSString *localPath;

@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) CGFloat size;

@property (nonatomic, assign) HCDDownloadStatus status;

@end

NS_ASSUME_NONNULL_END
