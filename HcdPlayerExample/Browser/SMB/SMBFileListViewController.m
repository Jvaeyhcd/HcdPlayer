//
//  SMBFileListViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2020/1/4.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import "SMBFileListViewController.h"
#import "UITableView+Hcd.h"
#import "FilesListTableViewCell.h"

@interface SMBFileListViewController ()<UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, copy) NSString *directoryTitle;

@property (nonatomic, strong) TOSMBSession *session;

@end

@implementation SMBFileListViewController

- (instancetype)initWithSession:(TOSMBSession *)session title:(NSString *)title
{
    if (self = [super init]) {
        _directoryTitle = title;
        _session = session;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = kMainBgColor;
    [self showBarButtonItemWithImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_back"] position:LEFT];
    
    [self.view addSubview:self.tableView];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.files.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FilesListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdFilesList forIndexPath:indexPath];
    [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:kBasePadding];
    
//    NetworkService *service = [self.networkServerArray objectAtIndex:indexPath.row];
//    [cell setNetworkService:service];
    
    TOSMBSessionFile *file = self.files[indexPath.row];
    [cell setTOSMBSessionFile:file];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [FilesListTableViewCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    TOSMBSessionFile *file = self.files[indexPath.row];
    if (file.directory == NO) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.session requestContentsOfDirectoryAtFilePath:file.filePath success:^(NSArray *files) {
        
        NSLog(@"");
        SMBFileListViewController *controller = [[SMBFileListViewController alloc] initWithSession:self.session title:file.name];
        controller.files = files;
        [weakSelf.navigationController pushViewController:controller animated:YES];
        
    } error:^(NSError *error) {
        
    }];
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth |UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
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

- (void)setFiles:(NSArray <TOSMBSessionFile *> *)files {
    _files = files;
    self.navigationItem.title = self.directoryTitle;
    
    [self.tableView reloadData];
}

- (void)leftNavBarButtonClicked {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
