//
//  iCloudManager.m
//  HcdPlayer
//
//  Created by Salvador on 2019/2/27.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "iCloudManager.h"
#import "HcdDocument.h"

@implementation iCloudManager

+ (BOOL)iCloudEnable {
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSURL *url = [manager URLForUbiquityContainerIdentifier:nil];
    
    if (url != nil) {
        
        return YES;
    }
    
    DLog(@"iCloud 不可用");
    return NO;
}

+ (void)downloadWithDocumentURL:(NSURL*)url callBack:(downloadBlock)block {
    
    HcdDocument *iCloudDoc = [[HcdDocument alloc] initWithFileURL:url];
    
    [iCloudDoc openWithCompletionHandler:^(BOOL success) {
        if (success) {
            [iCloudDoc closeWithCompletionHandler:^(BOOL success) {
                DLog(@"关闭成功");
            }];
            
            if (block) {
                block(iCloudDoc.data);
            }
            
        }
    }];
}

@end
