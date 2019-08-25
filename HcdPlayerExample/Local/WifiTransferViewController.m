//
//  WifiTransferViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2019/1/21.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "WifiTransferViewController.h"
#import "WiFiTransferTableViewCell.h"
#import "FilesListTableViewCell.h"
#import "UITableView+Hcd.h"

@interface WifiTransferViewController () {
    
    UITableView         *_tableView;
    NSString            *_serverURL;
    Reachability        *_status;
    Boolean             _notWiFi;
    NSMutableArray      *_fileList;
}

@property (nonatomic, retain) GCDWebUploader *webServer;

@end

@implementation WifiTransferViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initDatas];
    [self initSubviews];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void)initDatas {
    _fileList = [[NSMutableArray alloc] init];
}

- (void)initSubviews {
    [self.view setBackgroundColor:kMainBgColor];
    self.title =  HcdLocalized(@"wifi_transfer", nil);
    [self showBarButtonItemWithImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_close"] position:LEFT];
    
    // 获取Documents目录路径
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    _webServer = [[GCDWebUploader alloc] initWithUploadDirectory:documentsPath];
    _webServer.delegate = self;
    _webServer.allowHiddenItems = YES;
    if ([_webServer start]) {
        NSLog(@"GCDWebServer running locally on port %lu", (unsigned long)_webServer.serverURL);
        _serverURL = [_webServer.serverURL absoluteString];
        [_tableView reloadData];
    } else {
        NSLog(@"GCDWebServer not running!");
    };
    if (!_tableView) {
        [self createTableView];
    }
    
    _status = [Reachability reachabilityWithHostName:@"www.apple.com"];
    switch ([_status currentReachabilityStatus]) {
        case NotReachable:
            _notWiFi = YES;
            break;
        case ReachableViaWWAN:
            _notWiFi = YES;
            break;
        case ReachableViaWiFi:
            _notWiFi = NO;
            break;
        default:
            _notWiFi = YES;
            break;
    }
    [_tableView reloadData];
}

- (void)createTableView {
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth |UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_tableView registerClass:[WiFiTransferTableViewCell class] forCellReuseIdentifier:kCellIdWiFiTransfer];
    [_tableView registerClass:[FilesListTableViewCell class] forCellReuseIdentifier:kCellIdFilesList];
    
    [self.view addSubview:_tableView];
}

- (void)leftNavBarButtonClicked {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (_webServer != nil) {
        [_webServer stop];
        _webServer = nil;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else {
        return [_fileList count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        WiFiTransferTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdWiFiTransfer forIndexPath:indexPath];
        if (_serverURL && !_notWiFi) {
            cell.addressLbl.text = _serverURL;
        } else {
            cell.addressLbl.text = HcdLocalized(@"noWiFi", nil);
        }
        return cell;
    } else {
        FilesListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdFilesList forIndexPath:indexPath];
        [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:kBasePadding];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        NSString *path = [_fileList objectAtIndex:indexPath.row];
        if (path) {
            [cell setFilePath: path];
        }
        
        return cell;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kHeaderHeight)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kBasePadding, 0, kScreenWidth - 2 * kBasePadding, kHeaderHeight)];
    label.font = [UIFont systemFontOfSize:14];
    label.textColor = [UIColor color666];
    view.backgroundColor = kCellHeaderBgColor;
    [view addSubview:label];
    
    NSString *header = HcdLocalized(@"transferStatus", nil);
    label.text = header;
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return kHeaderHeight;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return [WiFiTransferTableViewCell cellHeight];
    } else {
        return [FilesListTableViewCell cellHeight];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - GCDWebUploaderDelegate

- (void)webUploader:(GCDWebUploader *)uploader didDeleteItemAtPath:(NSString *)path {
    
}

- (void)webUploader:(GCDWebUploader *)uploader didUploadFileAtPath:(NSString *)path {
    if (path) {
        [_fileList addObject:path];
    }
    [_tableView reloadData];
}

- (void)webUploader:(GCDWebUploader *)uploader didDownloadFileAtPath:(NSString *)path {
    
}

- (void)webUploader:(GCDWebUploader *)uploader didMoveItemFromPath:(NSString *)fromPath toPath:(NSString *)toPath {
    
}

- (void)webUploader:(GCDWebUploader *)uploader didCreateDirectoryAtPath:(NSString *)path {
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
