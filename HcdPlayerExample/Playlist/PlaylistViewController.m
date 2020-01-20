//
//  NetworkMainViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2019/1/19.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "PlaylistViewController.h"
#import "FilesListTableViewCell.h"
#import "UITableView+Hcd.h"
#import "HcdAppManager.h"
#import "HCDPlayerViewController.h"
#import "HcdActionSheet.h"

@interface PlaylistViewController ()<UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (nonatomic, strong) UITableView    *tableView;
@property (nonatomic, assign) NSInteger      selectedIndex;

@end

@implementation PlaylistViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = HcdLocalized(@"playlist", nil);
    self.view.backgroundColor = kMainBgColor;
    [self.view addSubview:self.tableView];
    [self updateButtonItem];
}

- (void)rightNavBarButtonClicked {
    [self showClearActionSheet];
}

- (void)updateButtonItem {
    NSArray *playList = [HcdAppManager sharedInstance].playList;
    if (playList && [playList count] > 0) {
        [self showBarButtonItemWithStr:HcdLocalized(@"clear", nil) position:RIGHT];
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [self.tableView reloadData];
    [self updateButtonItem];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[HcdAppManager sharedInstance].playList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FilesListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdFilesList forIndexPath:indexPath];
    [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:kBasePadding];
    
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *path = [[HcdAppManager sharedInstance].playList objectAtIndex:indexPath.row];
    if (path) {
        if ([path isHttpRequestUrl]) {
            [cell setFileUrlPath:path];
        } else {
            [cell setFilePath:[NSString stringWithFormat:@"%@%@", documentPath, path]];
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [FilesListTableViewCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *path = [[HcdAppManager sharedInstance].playList objectAtIndex:indexPath.row];
    
    HCDPlayerViewController *vc = [[HCDPlayerViewController alloc] init];
    if ([path isHttpRequestUrl]) {
        vc.url = path;
    } else {
        vc.url = [NSString stringWithFormat:@"file://%@%@", documentPath, path];
    }
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:vc animated:YES completion:nil];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
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
        [weakSelf tapRowAction:indexPath.row];
    }];
    deleteAction.backgroundColor = kMainColor;
    [array addObject:deleteAction];
    return array;
}

- (void)tapRowAction:(NSInteger)row {
    _selectedIndex = row;
    [self showDeleteActionSheet];
}

/**
 * 显示删除按钮
 */
- (void)showDeleteActionSheet {
    NSString *fileNmae = [[HcdAppManager sharedInstance].playList objectAtIndex:_selectedIndex];
    
    HcdActionSheet *deleteSheet = [[HcdActionSheet alloc] initWithCancelStr:HcdLocalized(@"cancel", nil) otherButtonTitles:@[HcdLocalized(@"ok", nil)] attachTitle:[NSString stringWithFormat:HcdLocalized(@"sure_delete_play_history", nil), fileNmae]];
    
    __weak PlaylistViewController *weakSelf = self;
    deleteSheet.seletedButtonIndex = ^(NSInteger index) {
        switch (index) {
            case 1:
            {
                NSMutableArray *playlist = [[NSMutableArray alloc] initWithArray:[HcdAppManager sharedInstance].playList];
                if (weakSelf.selectedIndex < [playlist count]) {
                    [playlist removeObjectAtIndex:weakSelf.selectedIndex];
                }
                [HcdAppManager sharedInstance].playList = playlist;
                [weakSelf.tableView reloadData];
                [weakSelf updateButtonItem];
                break;
            }
            default:
                break;
        }
    };
    [[UIApplication sharedApplication].keyWindow addSubview:deleteSheet];
    [deleteSheet showHcdActionSheet];
}

- (void)showClearActionSheet {
    
    HcdActionSheet *deleteSheet = [[HcdActionSheet alloc] initWithCancelStr:HcdLocalized(@"cancel", nil) otherButtonTitles:@[HcdLocalized(@"ok", nil)] attachTitle:HcdLocalized(@"confirm_clear_playlist", nil)];
    
    __weak PlaylistViewController *weakSelf = self;
    deleteSheet.seletedButtonIndex = ^(NSInteger index) {
        switch (index) {
            case 1:
            {
                NSMutableArray *playlist = [[NSMutableArray alloc] initWithArray:[HcdAppManager sharedInstance].playList];
                [playlist removeAllObjects];
                [HcdAppManager sharedInstance].playList = playlist;
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


#pragma mark - DZNEmptyDataSetSource, DZNEmptyDataSetDelegate

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView {
    return YES;
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    return [UIImage imageNamed:@"hcdplayer.bundle/pic_no_data"];
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14], NSForegroundColorAttributeName: [UIColor color999]};
    return [[NSAttributedString alloc]initWithString:HcdLocalized(@"playlist_empty_tips", nil) attributes:attributes];
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
