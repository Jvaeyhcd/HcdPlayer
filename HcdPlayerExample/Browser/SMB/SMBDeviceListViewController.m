//
//  SMBDeviceListViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2020/1/2.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import "SMBDeviceListViewController.h"
#import "HcdValueTableViewCell.h"
#import "HcdInputTableViewCell.h"
#import "UITableView+Hcd.h"

@interface SMBDeviceListViewController ()<NSNetServiceBrowserDelegate, NSNetServiceDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSNetServiceBrowser *serviceBrowser;
@property (nonatomic, strong) NSMutableArray *nameServiceEntries;
@property (nonatomic, strong) TONetBIOSNameService *netbiosService;
@property (nonatomic, strong) UITableView *tableView;

- (void)beginServiceBrowser;

@end

@implementation SMBDeviceListViewController

#pragma mark - Object Lifecycle

- (void)dealloc
{
    if (self.netbiosService)
        [self.netbiosService stopDiscovery];
}

#pragma mark - Properties

- (TOSMBSession *)session {
    if (!_session) {
        _session = [[TOSMBSession alloc] init];
    }
    return _session;
}

- (NetworkService *)networkService {
    if (!_networkService) {
        _networkService = [[NetworkService alloc] init];
        _networkService.type = NetworkServiceTypeSMB;
    }
    return _networkService;
}

#pragma mark - View Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = HcdLocalized(@"smb_devices", nil);
    self.view.backgroundColor = kMainBgColor;
    [self showBarButtonItemWithStr:HcdLocalized(@"cancel", nil) position:LEFT];
    [self showBarButtonItemWithStr:HcdLocalized(@"save", nil) position:RIGHT];
    
    [self createTableView];
    
    if (self.nameServiceEntries == nil) {
        self.nameServiceEntries = [NSMutableArray array];
    }
    
    [self beginServiceBrowser];
    
    if (self.session.connected) {
//        [self pushContentOfRootDirectory];
    }
}

- (void)createTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth |UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[HcdValueTableViewCell class] forCellReuseIdentifier:kCellIdValueCell];
    [self.tableView registerClass:[HcdInputTableViewCell class] forCellReuseIdentifier:kCellIdInputCell];
    self.tableView.hidden = NO;
    
    [self.view addSubview:self.tableView];
}

#pragma mark - NetBios Service -
- (void)beginServiceBrowser
{
    if (self.netbiosService)
        return;
    
    self.netbiosService = [[TONetBIOSNameService alloc] init];
    [self.netbiosService startDiscoveryWithTimeOut:4.0f added:^(TONetBIOSNameServiceEntry *entry) {
        [self.nameServiceEntries addObject:entry];
        [self.tableView reloadData];
    } removed:^(TONetBIOSNameServiceEntry *entry) {
        [self.nameServiceEntries removeObject:entry];
        [self.tableView reloadData];
    }];
}

#pragma mark - UITableViewDelegate, UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 6;
    }
    return self.nameServiceEntries.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return [HcdInputTableViewCell cellHeight];
    }
    return [HcdValueTableViewCell cellHeight];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        HcdInputTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdInputCell forIndexPath:indexPath];
        __weak typeof(self) weakSelf = self;
        if (indexPath.row == 0) {
            cell.titleLbl.text = HcdLocalized(@"title", nil);
            cell.required = NO;
            cell.inputTF.text = self.networkService.title ? self.networkService.title : @"";
            cell.textChanged = ^(NSString * _Nullable text) {
                weakSelf.networkService.title = [text copy];
            };
        } else if (indexPath.row == 1) {
            cell.titleLbl.text = HcdLocalized(@"host", nil);
            cell.required = YES;
            cell.inputTF.text = self.networkService.host ? self.networkService.host : @"";
            cell.textChanged = ^(NSString * _Nullable text) {
                weakSelf.networkService.host = [text copy];
            };
        } else if (indexPath.row == 2) {
            cell.titleLbl.text = HcdLocalized(@"port", nil);
            cell.required = NO;
            cell.inputTF.text = self.networkService.port ? self.networkService.port : @"";
            cell.textChanged = ^(NSString * _Nullable text) {
                weakSelf.networkService.port = [text copy];
            };
        } else if (indexPath.row == 3) {
            cell.titleLbl.text = HcdLocalized(@"path", nil);
            cell.required = NO;
            cell.inputTF.text = self.networkService.path ? self.networkService.path : @"";
            cell.textChanged = ^(NSString * _Nullable text) {
                weakSelf.networkService.path = [text copy];
            };
        } else if (indexPath.row == 4) {
            cell.titleLbl.text = HcdLocalized(@"user_name", nil);
            cell.required = NO;
            cell.inputTF.text = self.networkService.userName ? self.networkService.userName : @"";
            cell.textChanged = ^(NSString * _Nullable text) {
                weakSelf.networkService.userName = [text copy];
            };
        } else if (indexPath.row == 5) {
            cell.titleLbl.text = HcdLocalized(@"password", nil);
            cell.required = NO;
            cell.inputTF.text = self.networkService.password ? self.networkService.password : @"";
            cell.textChanged = ^(NSString * _Nullable text) {
                weakSelf.networkService.password = [text copy];
            };
        }
        [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:kBasePadding];
        
        return cell;
    }
    HcdValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdValueCell forIndexPath:indexPath];
    cell.titleLbl.text = [self.nameServiceEntries[indexPath.row] name];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:kBasePadding];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (!self.nameServiceEntries || self.nameServiceEntries.count <= indexPath.row) {
        return;
    }
    if (indexPath.section == 0) {
        return;
    }
    
    TONetBIOSNameServiceEntry *entry = [self.nameServiceEntries objectAtIndex:indexPath.row];
    self.networkService.host = [self longToIp:entry.ipAddress];
    self.networkService.title = [entry.name copy];
    
    [self.tableView reloadData];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return kHeaderHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kHeaderHeight)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kBasePadding, 0, kScreenWidth - 2 * kBasePadding, kHeaderHeight)];
    label.font = [UIFont systemFontOfSize:14];
    label.textColor = [UIColor color666];
    view.backgroundColor = kCellHeaderBgColor;
    [view addSubview:label];

    NSString *header = @"";
    switch (section) {
        case 0:
            header = HcdLocalized(@"smb_information", nil);
            break;
//        case HcdSettingSectionGesture:
//            header = HcdLocalized(@"gesture", nil);
//            break;
        case 1:
            header = HcdLocalized(@"nearby_smb_devices", nil);
            break;
        default:
            break;
    }
    label.text = header;
    
    return view;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}

#pragma mark - private

- (NSString *)longToIp:(uint32_t)ipAddress {
    uint32_t ip_long = ipAddress;
    uint32_t i_1 = (ip_long >> 24);
    uint32_t i_2 = (ip_long & 0X00FFFFFF) >> 16;
    uint32_t i_3 = (ip_long & 0X0000FFFF) >> 8;
    uint32_t i_4 = (ip_long & 0X000000FF);
    
    return [NSString stringWithFormat:@"%d.%d.%d.%d", i_4, i_3, i_2, i_1];
}

- (void)rightNavBarButtonClicked {
    
    if ([NSString isBlankString:self.networkService.host]) {
        [HToastUtil showToast:HcdLocalized(@"toast_no_host", nil)];
        return;
    }
    
    if ([NSString isBlankString:self.networkService.title]) {
        self.networkService.title = self.networkService.host;
    }
    
    // 保存SMB设备连接
    BOOL success = [[NetworkServiceDao sharedNetworkServiceDao] insertOrUpdateData:self.networkService];
    if (success) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)leftNavBarButtonClicked {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
