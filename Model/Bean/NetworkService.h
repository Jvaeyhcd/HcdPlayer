//
//  NetworkService.h
//  HcdPlayer
//
//  Created by Salvador on 2020/1/3.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    NetworkServiceTypeSMB = 1,
    NetworkServiceTypeFTP,
    NetworkServiceTypeSFTP,
    NetworkServiceTypeWebDAV
} NetworkServiceType;

NS_ASSUME_NONNULL_BEGIN

@interface NetworkService : NSObject

@property (nonatomic, strong) NSNumber *id;

@property (nonatomic, assign) NetworkServiceType type;

@property (nonatomic, copy) NSString *title;

@property (nonatomic, copy) NSString *host;

@property (nonatomic, copy) NSString *port;

@property (nonatomic, copy) NSString *path;

@property (nonatomic, copy) NSString *userName;

@property (nonatomic, copy) NSString *password;

@end

NS_ASSUME_NONNULL_END
