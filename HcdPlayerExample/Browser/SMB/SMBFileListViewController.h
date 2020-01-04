//
//  SMBFileListViewController.h
//  HcdPlayer
//
//  Created by Salvador on 2020/1/4.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import "BaseViewController.h"
#import "TOSMBClient.h"

NS_ASSUME_NONNULL_BEGIN

@class TOSMBSession;
@class TOSMBSessionFile;

@interface SMBFileListViewController : BaseViewController

@property (nonatomic, copy) NSString *path;
@property (nonatomic, strong) NSArray <TOSMBSessionFile *> *files;

- (instancetype)initWithSession:(TOSMBSession *)session title:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
