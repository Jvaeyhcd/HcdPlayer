//
//  HCDPlayerUtils.h
//  HCDPlayer
//
//  Created by Jvaeyhcd on 05/12/2019.
//  Copyright © 2016 Jvaeyhcd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HCDPlayerUtils : NSObject

+ (BOOL)createError:(NSError **)error withDomain:(NSString *)domain andCode:(NSInteger)code andMessage:(NSString *)message;
+ (BOOL)createError:(NSError **)error withDomain:(NSString *)domain andCode:(NSInteger)code andMessage:(NSString *)message andRawError:(NSError *)rawError;
+ (NSString *)localizedString:(NSString *)name;
+ (NSString *)durationStringFromSeconds:(int)seconds;

@end
