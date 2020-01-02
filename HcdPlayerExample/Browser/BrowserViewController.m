//
//  BrowserViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2019/1/19.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "BrowserViewController.h"
#import "SMBDeviceListViewController.h"
#import "HcdActionSheet.h"

@interface BrowserViewController ()

@property (nonatomic, strong) HcdActionSheet *addActionSheet;

@end

@implementation BrowserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = HcdLocalized(@"network", nil);
    self.view.backgroundColor = kMainBgColor;
    [self showBarButtonItemWithImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_add"] position:LEFT];
}

- (void)leftNavBarButtonClicked {
    [self showAddActionSheet];
}

- (void)showAddActionSheet {
    [[UIApplication sharedApplication].keyWindow addSubview:self.addActionSheet];
    [self.addActionSheet showHcdActionSheet];
}

- (HcdActionSheet *)addActionSheet {
    if (!_addActionSheet) {
        _addActionSheet = [[HcdActionSheet alloc] initWithCancelStr:HcdLocalized(@"cancel", nil) otherButtonTitles:@[HcdLocalized(@"server_smb", nil), HcdLocalized(@"server_ftp", nil), HcdLocalized(@"server_sftp", nil), HcdLocalized(@"server_webdav", nil)] attachTitle:nil];
        __weak BrowserViewController *weakSelf = self;
        _addActionSheet.seletedButtonIndex = ^(NSInteger index) {
            switch (index) {
                case 1: {
                    SMBDeviceListViewController *vc = [[SMBDeviceListViewController alloc] init];
                    BaseNavigationController *nvc = [[BaseNavigationController alloc] initWithRootViewController:vc];
                    nvc.modalPresentationStyle = UIModalPresentationFullScreen;
                    [weakSelf presentViewController:nvc animated:YES completion:nil];
                    break;
                }
                default:
                    break;
            }
        };
    }
    return _addActionSheet;
}

@end
