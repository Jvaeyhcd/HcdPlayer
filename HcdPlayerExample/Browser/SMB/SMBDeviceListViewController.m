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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.nameServiceEntries.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [HcdValueTableViewCell cellHeight];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HcdValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdValueCell forIndexPath:indexPath];
    cell.titleLbl.text = [self.nameServiceEntries[indexPath.row] name];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:kBasePadding];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)rightNavBarButtonClicked {
    
}

- (void)leftNavBarButtonClicked {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
