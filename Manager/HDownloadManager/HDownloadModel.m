//
//  HDownloadModel.m
//  HcdPlayer
//
//  Created by Salvador on 2020/1/9.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import "HDownloadModel.h"

@implementation HDownloadModel

@synthesize progress = _progress;
- (void)setProgress:(CGFloat)progress {
    if (_progress != progress) {
        _progress = progress;
        
        if (self.onProgressChanged) {
            self.onProgressChanged(self);
        } else {
            DLog(@"progress changed block is empty");
        }
    }
}

@synthesize status = _status;
- (void)setStatus:(HCDDownloadStatus)status {
    if (_status != status) {
        _status = status;
        
        if (self.onStatusChanged) {
            self.onStatusChanged(self);
        }
    }
}

- (NSString *)statusText {
    NSString *text = @"";
    switch (self.status) {
        case HCDDownloadStatusFailed:
            text = HcdLocalized(@"download_failed", nil);
            break;
        case HCDDownloadStatusRunning:
            text = HcdLocalized(@"download_ing", nil);
            break;
        case HCDDownloadStatusWaiting:
            text = HcdLocalized(@"download_wait", nil);
            break;
        case HCDDownloadStatusCompleted:
            text = HcdLocalized(@"download_done", nil);
            break;
        case HCDDownloadStatusSuspended:
            text = HcdLocalized(@"download_suspended", nil);
            break;
        default:
            text = @"";
            break;
    }
    return text;
}

@end
