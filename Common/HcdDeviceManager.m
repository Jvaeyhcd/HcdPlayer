//
//  HcdDeviceManager.m
//  HcdPlayer
//
//  Created by Salvador on 2019/3/19.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "HcdDeviceManager.h"

@implementation HcdDeviceManager

+ (HcdDeviceManager *)sharedInstance {
    static HcdDeviceManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[HcdDeviceManager alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _supportedInterfaceOrientationsForWindow = UIInterfaceOrientationMaskPortrait;
        _isLocked = NO;
        _isAllowAutorotate = NO;
    }
    return self;
}

@synthesize supportedInterfaceOrientationsForWindow = _supportedInterfaceOrientationsForWindow;
- (void)setSupportedInterfaceOrientationsForWindow:(UIInterfaceOrientationMask)supportedInterfaceOrientationsForWindow {
    _supportedInterfaceOrientationsForWindow = supportedInterfaceOrientationsForWindow;
}

@synthesize isLocked = _isLocked;
- (void)setIsLocked:(BOOL)isLocked {
    _isLocked = isLocked;
}

@synthesize isAllowAutorotate = _isAllowAutorotate;
- (void)setIsAllowAutorotate:(BOOL)isAllowAutorotate {
    _isAllowAutorotate = isAllowAutorotate;
}

- (NSString *)passcode {
    NSString *passcode = [[NSUserDefaults standardUserDefaults] stringForKey:@"passcode"];
    if (passcode) {
        return passcode;
    }
    return @"";
}

@synthesize passcode = _passcode;
- (void)setPasscode:(NSString *)passcode {
    _passcode = passcode;
    [[NSUserDefaults standardUserDefaults] setObject:_passcode forKey:@"passcode"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"needPasscode"];
}

- (BOOL)needPasscode {
    return ![[self passcode] isEqualToString:@""] && [[NSUserDefaults standardUserDefaults] boolForKey:@"needPasscode"];
}

- (void)setNeedPasscode:(BOOL)needPasscode {
    if (!needPasscode) {
        [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"passcode"];
    }
    [[NSUserDefaults standardUserDefaults] setBool:needPasscode forKey:@"needPasscode"];
}

@end
