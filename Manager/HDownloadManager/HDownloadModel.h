//
//  HDownloadModel.h
//  HcdPlayer
//
//  Created by Salvador on 2020/1/9.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TOSMBClient.h"
#import "DownloadModel.h"

@class HDownloadOperation;
@class HDownloadModel;

NS_ASSUME_NONNULL_BEGIN

typedef void(^HCDDownloadStatusChanged)(HDownloadModel *model);
typedef void(^HCDDownloadProgressChanged)(HDownloadModel *model);

@interface HDownloadModel : DownloadModel

@property (nonatomic, strong) HDownloadOperation *operation;

@property (nonatomic, copy) HCDDownloadStatusChanged onStatusChanged;
@property (nonatomic, copy) HCDDownloadProgressChanged onProgressChanged;

@property (nonatomic, readonly, copy) NSString *statusText;

@end

NS_ASSUME_NONNULL_END
