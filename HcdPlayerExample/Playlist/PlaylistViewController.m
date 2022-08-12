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
#import "HCDPlayerViewController.h"
#import "HcdActionSheet.h"
#import "CDFFmpegViewController.h"
#import "playlistModelDao.h"

@interface PlaylistViewController ()<UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (nonatomic, strong) UITableView    *tableView;
@property (nonatomic, assign) NSInteger      selectedIndex;
@property (nonatomic, strong) NSMutableArray *playlistArray;

@end

@implementation PlaylistViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = HcdLocalized(@"playlist", nil);
    self.view.backgroundColor = kMainBgColor;
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(0);
        make.top.mas_equalTo(kNavHeight);
        make.bottom.mas_equalTo(-0);
    }];
    [self updateButtonItem];
}

- (void)rightNavBarButtonClicked {
    [self showClearActionSheet];
}

- (void)updateButtonItem {
    if ([self.playlistArray count] > 0) {
        [self showBarButtonItemWithStr:HcdLocalized(@"clear", nil) position:RIGHT];
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self getPlaylistArray];
}

- (void)viewDidAppear:(BOOL)animated {
    [self.tableView reloadData];
    [self updateButtonItem];
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

- (NSMutableArray *)playlistArray {
    if (!_playlistArray) {
        _playlistArray = [NSMutableArray array];
    }
    return _playlistArray;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.playlistArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FilesListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdFilesList forIndexPath:indexPath];
    [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:kBasePadding];
    
    PlaylistModel *playlist = [self.playlistArray objectAtIndex:indexPath.row];
    if (playlist.path) {
        [cell setFilePath:playlist.path];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [FilesListTableViewCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    PlaylistModel *playlist = [self.playlistArray objectAtIndex:indexPath.row];
    
    CDFFmpegViewController *vc = [[CDFFmpegViewController alloc] init];
    vc.path = [playlist.path stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    vc.playlistModel = playlist;
    
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:vc animated:YES completion:nil];
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
    PlaylistModel *playlistModel = [self.playlistArray objectAtIndex:_selectedIndex];
    
    HcdActionSheet *deleteSheet = [[HcdActionSheet alloc] initWithCancelStr:HcdLocalized(@"cancel", nil) otherButtonTitles:@[HcdLocalized(@"ok", nil)] attachTitle:[NSString stringWithFormat:HcdLocalized(@"sure_delete_play_history", nil), [playlistModel.path lastPathComponent]]];
    
    __weak PlaylistViewController *weakSelf = self;
    deleteSheet.seletedButtonIndex = ^(NSInteger index) {
        switch (index) {
            case 1:
            {
                if (weakSelf.selectedIndex < [weakSelf.playlistArray count]) {
                    dispatch_async(dispatch_get_global_queue(0, 0), ^{
                        [[PlaylistModelDao sharedPlaylistModelDao] deleteData:[weakSelf.playlistArray objectAtIndex:weakSelf.selectedIndex]];
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            [weakSelf.playlistArray removeObjectAtIndex:weakSelf.selectedIndex];
                            [weakSelf.tableView reloadData];
                            [weakSelf updateButtonItem];
                        });
                    });
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

- (void)showClearActionSheet {
    
    HcdActionSheet *deleteSheet = [[HcdActionSheet alloc] initWithCancelStr:HcdLocalized(@"cancel", nil)
                                                          otherButtonTitles:@[HcdLocalized(@"ok", nil)]
                                                                attachTitle:HcdLocalized(@"confirm_clear_playlist", nil)];
    
    __weak PlaylistViewController *weakSelf = self;
    deleteSheet.seletedButtonIndex = ^(NSInteger index) {
        switch (index) {
            case 1: {
                [[PlaylistModelDao sharedPlaylistModelDao] clearAll];
                [weakSelf.playlistArray removeAllObjects];
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

#pragma mark - private

- (void)getPlaylistArray {
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *playlistArray = [[PlaylistModelDao sharedPlaylistModelDao] queryAll];
        dispatch_sync(dispatch_get_main_queue(), ^{
            weakSelf.playlistArray = [NSMutableArray arrayWithArray:playlistArray];
            [weakSelf.tableView reloadData];
            [weakSelf updateButtonItem];
        });
    });
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
