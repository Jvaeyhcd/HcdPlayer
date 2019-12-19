//
//  HcdDeviceManager.m
//  HcdPlayer
//
//  Created by Salvador on 2019/3/19.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "HcdAppManager.h"
#import "HcdFileManager.h"

#define PLAYLIST @"playlist"

@implementation HcdAppManager

+ (HcdAppManager *)sharedInstance {
    static HcdAppManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[HcdAppManager alloc] init];
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
        _mainVc = [[MainViewController alloc] init];
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
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@synthesize playList = _playList;
- (void)setPlayList:(NSArray *)playList {
    _playList = playList;
    [[NSUserDefaults standardUserDefaults] setObject:_playList forKey:PLAYLIST];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray *)playList {
    NSArray *playList = [[NSUserDefaults standardUserDefaults] arrayForKey:PLAYLIST];
    NSMutableArray *array = [NSMutableArray array];
    
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    
    if (playList && [playList count] > 0) {
        for (NSString *path in playList) {
            NSString *fullPath = [NSString stringWithFormat:@"%@%@", documentPath, path];
            if ([[HcdFileManager defaultManager] fileExists:fullPath]) {
                [array addObject:path];
            }
        }
    }
    _playList = [NSArray arrayWithArray:array];
    [[NSUserDefaults standardUserDefaults] setObject:_playList forKey:PLAYLIST];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return _playList;
}

/**
 * 将播放路径添加到播放列表
 * @param path 文件路径
 */
- (void)addPathToPlaylist:(NSString *)path {
    NSMutableArray *list = [NSMutableArray arrayWithArray:self.playList];
    for (NSInteger i = 0; i < list.count; i++) {
        NSString *str = [list objectAtIndex:i];
        if ([str isEqualToString:path]) {
            [list removeObjectAtIndex:i];
            break;
        }
    }
    [list insertObject:path atIndex:0];
    self.playList = [[NSArray alloc] initWithArray:list];
}

@end
