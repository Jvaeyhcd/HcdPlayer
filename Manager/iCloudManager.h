//
//  iCloudManager.h
//  HcdPlayer
//
//  Created by Salvador on 2019/2/27.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^downloadBlock)(id obj);

@interface iCloudManager : NSObject

+ (BOOL)iCloudEnable;

+ (void)downloadWithDocumentURL:(NSURL*)url callBack:(downloadBlock)block;

@end

NS_ASSUME_NONNULL_END
