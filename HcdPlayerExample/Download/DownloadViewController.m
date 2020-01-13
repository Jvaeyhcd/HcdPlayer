//
//  DownloadViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2020/1/6.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import "DownloadViewController.h"
#import "HDownloadCell.h"
#import "HDownloadManager.h"

@interface DownloadViewController ()<UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (nonatomic, strong) UITableView    *tableView;
@property (nonatomic, assign) NSInteger      selectedIndex;

@end


@implementation DownloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.title = HcdLocalized(@"download", nil);
    self.view.backgroundColor = kMainBgColor;
    [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.tableView reloadData];
    [self updateButtonItem];
}

- (void)updateButtonItem {
    NSArray *downloadList = [HDownloadManager shared].downloadModels;
    if (downloadList && [downloadList count] > 0) {
        [self showBarButtonItemWithStr:HcdLocalized(@"clear", nil) position:RIGHT];
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
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
        [_tableView registerClass:[HDownloadCell class] forCellReuseIdentifier:kCellIdHDownloadCell];
    }
    return _tableView;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [HDownloadManager shared].downloadModels.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HDownloadCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdHDownloadCell forIndexPath:indexPath];
    [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:kBasePadding];
    
    HDownloadModel *downloadModel = [[HDownloadManager shared].downloadModels objectAtIndex:indexPath.row];
    cell.model = downloadModel;
    
    downloadModel.onProgressChanged = ^(HDownloadModel * _Nonnull model) {
        cell.model = model;
    };
    
    downloadModel.onStatusChanged = ^(HDownloadModel * _Nonnull model) {
        cell.model = model;
    };

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [HDownloadCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
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
    return [[NSAttributedString alloc]initWithString:HcdLocalized(@"download_empty_tips", nil) attributes:attributes];
}

@end
