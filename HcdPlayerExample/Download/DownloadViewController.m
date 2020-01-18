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

- (void)viewDidAppear:(BOOL)animated {
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

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    HDownloadModel *downloadModel = [[HDownloadManager shared].downloadModels objectAtIndex:indexPath.row];
    if (downloadModel.status == HCDDownloadStatusRunning) {
        return NO;
    }
    
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *array = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;
    
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:HcdLocalized(@"delete", nil) handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
        HDownloadModel *downloadModel = [[HDownloadManager shared].downloadModels objectAtIndex:indexPath.row];
        [[HDownloadManager shared] deleteDownloadModel:downloadModel];
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
//        [self.tableView reloadData];
    }];
    deleteAction.backgroundColor = kMainColor;
    [array addObject:deleteAction];
    
    return array;
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

#pragma mark - private

- (void)rightNavBarButtonClicked {
    [self showClearActionSheet];
}

- (void)showClearActionSheet {
    
    HcdActionSheet *deleteSheet = [[HcdActionSheet alloc] initWithCancelStr:HcdLocalized(@"cancel", nil) otherButtonTitles:@[HcdLocalized(@"ok", nil)] attachTitle:HcdLocalized(@"confirm_clear_all_download_list", nil)];
    
    __weak typeof(self) weakSelf = self;
    deleteSheet.seletedButtonIndex = ^(NSInteger index) {
        switch (index) {
            case 1:
            {
                [[HDownloadManager shared] deleteAllDownloadModels];
                [weakSelf.tableView reloadData];
                break;
            }
            default:
                break;
        }
    };
    [[UIApplication sharedApplication].keyWindow addSubview:deleteSheet];
    [deleteSheet showHcdActionSheet];
}

@end
