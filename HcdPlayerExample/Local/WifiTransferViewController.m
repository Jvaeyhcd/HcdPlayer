//
//  WifiTransferViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2019/1/21.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "WifiTransferViewController.h"
#import "WiFiTransferTableViewCell.h"

@interface WifiTransferViewController () {
    
    UITableView         *_tableView;
}

@property (nonatomic, retain) GCDWebUploader *webServer;

@end

@implementation WifiTransferViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initSubviews];
}

- (void)initSubviews {
    [self.view setBackgroundColor:kMainBgColor];
    self.title =  HcdLocalized(@"wifi_transfer", nil);
    [self showBarButtonItemWithStr:HcdLocalized(@"done", nil) position:RIGHT];
    
    // 获取Documents目录路径
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    _webServer = [[GCDWebUploader alloc] initWithUploadDirectory:documentsPath];
    _webServer.delegate = self;
    _webServer.allowHiddenItems = YES;
    if ([_webServer start]) {
        NSLog(@"GCDWebServer running locally on port %lu", (unsigned long)_webServer.port);
    } else {
        NSLog(@"GCDWebServer not running!");
    };
    if (!_tableView) {
        [self createTableView];
    }
}

- (void)createTableView {
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth |UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_tableView registerClass:[WiFiTransferTableViewCell class] forCellReuseIdentifier:kCellIdWiFiTransfer];
    
    [self.view addSubview:_tableView];
}

- (void)rightNavBarButtonClicked {
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WiFiTransferTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdWiFiTransfer forIndexPath:indexPath];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [WiFiTransferTableViewCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - GCDWebUploaderDelegate

- (void)webUploader:(GCDWebUploader *)uploader didDeleteItemAtPath:(NSString *)path {
    
}

- (void)webUploader:(GCDWebUploader *)uploader didUploadFileAtPath:(NSString *)path {
    
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
