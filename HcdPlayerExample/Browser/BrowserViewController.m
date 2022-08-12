//
//  BrowserViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2019/1/19.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "BrowserViewController.h"
#import "SMBDeviceListViewController.h"
#import "SMBFileListViewController.h"
#import "HCDPlayerViewController.h"
#import "HcdActionSheet.h"
#import "NetworkServiceDao.h"
#import "FilesListTableViewCell.h"
#import "UITableView+Hcd.h"
#import "TOSMBClient.h"
#import "HcdAlertInputView.h"
#import "HcdFileManager.h"

@interface BrowserViewController ()<UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (nonatomic, strong) UITableView    *tableView;

@property (nonatomic, assign) NSInteger      selectedIndex;

@property (nonatomic, strong) HcdActionSheet *addActionSheet;

@property (nonatomic, strong) NSMutableArray *networkServerArray;

@property (nonatomic, strong, null_resettable) TOSMBSession *session;

@end

@implementation BrowserViewController

#pragma mark - Properties

- (TOSMBSession *)session {
    if (!_session) {
        _session = [[TOSMBSession alloc] init];
    }
    return _session;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = HcdLocalized(@"network", nil);
    self.view.backgroundColor = kMainBgColor;
    [self showBarButtonItemWithImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_add"] position:LEFT];
    
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(0);
        make.top.mas_equalTo(kNavHeight);
        make.bottom.mas_equalTo(-0);
    }];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0, *)) {
        // trait模式发生了变化
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            // 执行操作刷新列表
            [self.tableView reloadData];
        }
    } else {
        // Fallback on earlier versions
    }
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.emptyDataSetSource = self;
        _tableView.emptyDataSetDelegate = self;
        _tableView.allowsMultipleSelectionDuringEditing = YES;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [_tableView registerClass:[FilesListTableViewCell class] forCellReuseIdentifier:kCellIdFilesList];
    }
    return _tableView;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.networkServerArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FilesListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdFilesList forIndexPath:indexPath];
    [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:kBasePadding];
    
    NetworkService *service = [self.networkServerArray objectAtIndex:indexPath.row];
    [cell setNetworkService:service];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [FilesListTableViewCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NetworkService *service = [self.networkServerArray objectAtIndex:indexPath.row];
    if (service.type == NetworkServiceTypeSMB) {
        [self pushContentOfSMBRootDirectory:service];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *array = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;
    
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:HcdLocalized(@"delete", nil) handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [weakSelf tapRowAction:indexPath.row];
    }];
    deleteAction.backgroundColor = kMainColor;
    [array addObject:deleteAction];
    
    UITableViewRowAction *moreAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:HcdLocalized(@"edit", nil) handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [weakSelf tapEditRowAction:indexPath.row];
    }];
    [array addObject:moreAction];
    
    return array;
}

- (void)tapRowAction:(NSInteger)row {
    _selectedIndex = row;
    [self showDeleteActionSheet];
}

- (void)tapEditRowAction:(NSInteger)row {
    _selectedIndex = row;
    NetworkService *service = [self.networkServerArray objectAtIndex:_selectedIndex];
    SMBDeviceListViewController *vc = [[SMBDeviceListViewController alloc] init];
    vc.networkService = service;
    BaseNavigationController *nvc = [[BaseNavigationController alloc] initWithRootViewController:vc];
    nvc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nvc animated:YES completion:nil];
}

/**
 * 显示删除按钮
 */
- (void)showDeleteActionSheet {
    NetworkService *service = [self.networkServerArray objectAtIndex:_selectedIndex];
    NSString *fileNmae = service.title;
    
    HcdActionSheet *deleteSheet = [[HcdActionSheet alloc] initWithCancelStr:HcdLocalized(@"cancel", nil) otherButtonTitles:@[HcdLocalized(@"ok", nil)] attachTitle:[NSString stringWithFormat:HcdLocalized(@"sure_delete_network", nil), fileNmae]];
    
    __weak BrowserViewController *weakSelf = self;
    deleteSheet.seletedButtonIndex = ^(NSInteger index) {
        switch (index) {
            case 1:
            {
                BOOL success = [[NetworkServiceDao sharedNetworkServiceDao] deleteData:service];
                if (success) {
                    [weakSelf reloadNetworkServices];
                }
                break;
            }
            default:
                break;
        }
    };
    [[UIApplication sharedApplication].keyWindow addSubview:deleteSheet];
    [deleteSheet showHcdActionSheet];
}

- (void)viewWillAppear:(BOOL)animated {
    [self reloadNetworkServices];
}

- (void)leftNavBarButtonClicked {
    [self showAddActionSheet];
}

- (void)showAddActionSheet {
    [[UIApplication sharedApplication].keyWindow addSubview:self.addActionSheet];
    [self.addActionSheet showHcdActionSheet];
}

#pragma mark - private

- (void)reloadNetworkServices {
    
    self.networkServerArray = [NSMutableArray arrayWithArray:[[NetworkServiceDao sharedNetworkServiceDao] queryAll]];
    [self.tableView reloadData];
}

- (void)pushContentOfSMBRootDirectory:(NetworkService *)service {
    
    self.session.hostName = service.title;
    self.session.ipAddress = service.host;
    if (service.userName) {
        self.session.userName = service.userName;
    }
    if (service.password) {
        self.session.password = service.password;
    }
    
    [HHUDUtil showLoading];
    
    __weak typeof(self) weakSelf = self;
    [self.session requestContentsOfDirectoryAtFilePath:@"/" success:^(NSArray *files) {
        
        [HHUDUtil hideLoading];
        DLog(@"");
        SMBFileListViewController *vc = [[SMBFileListViewController alloc] initWithSession:self.session title:service.title];
        vc.files = files;
        vc.hidesBottomBarWhenPushed = YES;
        [weakSelf.navigationController pushViewController:vc animated:YES];
        
    } error:^(NSError *error) {
        [HHUDUtil hideLoading];
        if ([error.domain isEqualToString:TOSMBClientErrorDomain]) {
            if (error.code == TOSMBSessionErrorCodeAuthenticationFailed) {
                SMBDeviceListViewController *vc = [[SMBDeviceListViewController alloc] init];
                vc.networkService = service;
                BaseNavigationController *nvc = [[BaseNavigationController alloc] initWithRootViewController:vc];
                nvc.modalPresentationStyle = UIModalPresentationFullScreen;
                [weakSelf presentViewController:nvc animated:YES completion:nil];
            } else if (error.code == TOSMBSessionErrorCodeUnknown) {
                [HHUDUtil showToast:HcdLocalized(@"smb_unknown_error", nil)];
            } else if (error.code == TOSMBSessionErrorNotOnWiFi) {
                [HHUDUtil showToast:HcdLocalized(@"smb_not_on_wifi", nil)];
            } else if (error.code == TOSMBSessionErrorCodeUnableToResolveAddress) {
                [HHUDUtil showToast:HcdLocalized(@"smb_unable_address", nil)];
            } else if (error.code == TOSMBSessionErrorCodeUnableToConnect) {
                [HHUDUtil showToast:HcdLocalized(@"smb_unable_connect", nil)];
            }
            
        }
    }];
}

- (void)openFileByURLString:(NSString *)urlStr {
    
    if ([NSString isBlankString:urlStr]) {
        return;
    } else if (![urlStr isHttpRequestUrl]) {
        return;
    }
    NSString *suffix = [[urlStr pathExtension] lowercaseString];
    FileType fileType = [[HcdFileManager sharedHcdFileManager] getFileTypeBySuffix:suffix];
    switch (fileType) {
        case FileType_video:
        case FileType_music:
        {
            HCDPlayerViewController *vc = [[HCDPlayerViewController alloc] init];
            vc.url = [urlStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            vc.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:vc animated:YES completion:nil];
            break;
        }
        default:
            break;
    }
}

#pragma mark - DZNEmptyDataSetSource, DZNEmptyDataSetDelegate

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView {
    return YES;
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    return [UIImage imageNamed:@"hcdplayer.bundle/pic_no_data"];
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14], NSForegroundColorAttributeName: [UIColor color999]};
    return [[NSAttributedString alloc]initWithString:HcdLocalized(@"network_empty_tips", nil) attributes:attributes];
}

#pragma mark - lazy load

- (NSMutableArray *)networkServerArray {
    if (!_networkServerArray) {
        _networkServerArray = [NSMutableArray array];
    }
    return _networkServerArray;
}

- (HcdActionSheet *)addActionSheet {
    if (!_addActionSheet) {
        
        NSArray *titleArray = @[
            HcdLocalized(@"server_http", nil),
            HcdLocalized(@"server_smb", nil)
//            HcdLocalized(@"server_ftp", nil),
//            HcdLocalized(@"server_sftp", nil)
        ];
        
        _addActionSheet = [[HcdActionSheet alloc] initWithCancelStr:HcdLocalized(@"cancel", nil) otherButtonTitles:titleArray attachTitle:nil];
        __weak BrowserViewController *weakSelf = self;
        _addActionSheet.seletedButtonIndex = ^(NSInteger index) {
            switch (index) {
                case 1: {
                    HcdAlertInputView *newFolderView = [[HcdAlertInputView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
                    newFolderView.tips = HcdLocalized(@"server_http", nil);
                    newFolderView.placeHolder = HcdLocalized(@"placeholder_please_input_a_url", nil);
                    newFolderView.commitBlock = ^(NSString * _Nonnull content) {
                        [weakSelf openFileByURLString:content];
                    };
                    [newFolderView showReplyInView:[UIApplication sharedApplication].keyWindow];
                    break;
                }
                case 2: {
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
