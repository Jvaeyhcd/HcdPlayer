//
//  DNLAViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2021/2/28.
//  Copyright © 2021 Salvador. All rights reserved.
//

#import "DNLAViewController.h"
#import "RemoteControlView.h"
#import "HcdPopSelectView.h"

@interface DNLAViewController ()<DLNADelegate, RemoteControlViewDelegate>

@property (nonatomic, strong) RemoteControlView *dlnaControlView;

/**
 * DLNA manager
 */
@property (nonatomic, strong) MRDLNA *dlnaManager;

/**
 * 附近支持DLNA的设备
 */
@property (nonatomic, strong) NSArray *deviceArr;

@end

@implementation DNLAViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.dlnaControlView];
    [self startDLNAWithDevice:self.device playUrl:self.playUrl];
}

- (void)dealloc
{
    [self.dlnaManager endDLNA];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = YES;
    // 不自动锁屏
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    // 不自动锁屏
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

#pragma mark - Getter

- (RemoteControlView *)dlnaControlView {
    if (!_dlnaControlView) {
        _dlnaControlView = [[RemoteControlView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
        _dlnaControlView.userInteractionEnabled = YES;
        _dlnaControlView.delegate = self;
    }
    return _dlnaControlView;
}

- (MRDLNA *)dlnaManager {
    if (!_dlnaManager) {
        _dlnaManager = [MRDLNA sharedMRDLNAManager];
        _dlnaManager.delegate = self;
        [_dlnaManager startSearch];
    }
    return _dlnaManager;
}

- (NSArray *)deviceArr {
    if (!_deviceArr) {
        _deviceArr = [NSArray array];
    }
    return _deviceArr;
}

#pragma mark - private

- (void)showDeviceListView {
    
    if (!self.deviceArr || self.deviceArr.count == 0) {
        [self.dlnaManager startSearch];
    }

    NSMutableArray *deviceNameArr = [NSMutableArray array];
    for (CLUPnPDevice *device in self.deviceArr) {
        [deviceNameArr addObject:device.friendlyName];
    }

    HcdPopSelectView *selectDeviceView = [[HcdPopSelectView alloc] initWithDataArray:deviceNameArr title:@"请选择要投屏的设备"];

    selectDeviceView.seletedIndex = ^(NSInteger index) {
        CLUPnPDevice *device = [self.deviceArr objectAtIndex:index];
        [self startDLNAWithDevice:device playUrl:self.playUrl];
    };

    [[UIApplication sharedApplication].keyWindow addSubview:selectDeviceView];
    [selectDeviceView show];
}

- (void)startDLNAWithDevice:(CLUPnPDevice *)device playUrl:(NSString *)playUrl {
    self.dlnaControlView.deviceLbl.text = device.friendlyName;
    [self.dlnaManager endDLNA];
    self.dlnaManager.device = device;
    self.dlnaManager.playUrl = playUrl;
    [self.dlnaManager startDLNA];
}

#pragma mark - RemoteControlViewDelegate

- (void)didClickChangeDevice {
    
}

- (void)didClickQuitDLNAPlay {
    // 停止endDLNA播放
    [self.dlnaManager endDLNA];
    // 退出界面
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - DLNADelegate

- (void)searchDLNAResult:(NSArray *)devicesArray {
    self.deviceArr = [[NSArray alloc] initWithArray:devicesArray];
}

- (void)dlnaStartPlay {
    
}

@end
