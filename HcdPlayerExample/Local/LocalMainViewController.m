//
//  LocalMainViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2019/1/19.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "LocalMainViewController.h"
#import "WifiTransferViewController.h"
#import "HcdFileManager.h"
#import "FilesListTableViewCell.h"
#import "UITableView+Hcd.h"
#import "FolderViewController.h"
#import "HcdActionSheet.h"

typedef enum : NSUInteger {
    ActionTypeDelete,
    ActionTypeMore
} ActionType;

@interface LocalMainViewController () {
    UITableView         *_tableView;
    NSString            *_currentPath;
    NSMutableArray      *_pathChidren;
    HcdActionSheet      *_navMoreActionSheet;
    HcdActionSheet      *_cellMoreActionSheet;
}

@end

@implementation LocalMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initData];
    [self initSubViews];
}

- (void)viewDidAppear:(BOOL)animated {
    [self reloadDatas];
}

- (void)initData {
    _currentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    _pathChidren = [[NSMutableArray alloc]initWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:_currentPath error:nil]];
    for (NSString *str in _pathChidren) {
        NSLog(@"%@", str);
        float size = [[HcdFileManager defaultManager] sizeOfPath:[NSString stringWithFormat:@"%@/%@", _currentPath, str]];
        NSLog(@"%lf", size);
    }
}

- (void)initSubViews {
    self.title = HcdLocalized(@"local", nil);
    [self showBarButtonItemWithImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_more"] position:RIGHT];
    [self showBarButtonItemWithImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_wifi"] position:LEFT];
    
    if (!_tableView) {
        [self createTableView];
    }
    
    if (!_navMoreActionSheet) {
        NSArray *otherButtonTitles = @[HcdLocalized(@"new_folder", nil), HcdLocalized(@"import", nil), HcdLocalized(@"select", nil), HcdLocalized(@"sort", nil)];
        _navMoreActionSheet = [[HcdActionSheet alloc] initWithCancelStr:HcdLocalized(@"cancel", nil) otherButtonTitles:otherButtonTitles attachTitle:nil];
        _navMoreActionSheet.selectButtonAtIndex = ^(NSInteger index) {
            
        };
    }
    
    if (!_cellMoreActionSheet) {
        NSArray *otherButtonTitles = @[HcdLocalized(@"new_folder", nil), HcdLocalized(@"import", nil), HcdLocalized(@"select", nil), HcdLocalized(@"sort", nil)];
        _cellMoreActionSheet = [[HcdActionSheet alloc] initWithCancelStr:HcdLocalized(@"cancel", nil) otherButtonTitles:otherButtonTitles attachTitle:nil];
        _cellMoreActionSheet.selectButtonAtIndex = ^(NSInteger index) {
            
        };
    }
}

- (void)reloadDatas {
    _currentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    _pathChidren = [[NSMutableArray alloc] initWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:_currentPath error:nil]];
    [_tableView reloadData];
}

- (void)createTableView {
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth |UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_tableView registerClass:[FilesListTableViewCell class] forCellReuseIdentifier:kCellIdFilesList];
    
    [self.view addSubview:_tableView];
}

- (void)leftNavBarButtonClicked {
    BaseNavigationController *nav = [[BaseNavigationController alloc] initWithRootViewController:[WifiTransferViewController new]];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)rightNavBarButtonClicked {
    if (_navMoreActionSheet) {
        [[UIApplication sharedApplication].keyWindow addSubview:_navMoreActionSheet];
        [_navMoreActionSheet showHcdActionSheet];
    }
}

- (void)showCellMoreActionSheet:(NSInteger)index {
    if (index >= [_currentPath length]) {
        return;
    }
    
    NSArray *otherButtonTitles = @[HcdLocalized(@"move", nil), HcdLocalized(@"rename", nil), HcdLocalized(@"delete", nil)];
    
    NSString *path = [NSString stringWithFormat:@"%@/%@", _currentPath, [_pathChidren objectAtIndex:index]];
    FileType fileType = [[HcdFileManager defaultManager] getFileTypeByPath:path];
    NSString *fileName = [path lastPathComponent];
    
    switch (fileType) {
        case FileType_file_dir:
            otherButtonTitles = @[HcdLocalized(@"lock", nil), HcdLocalized(@"move", nil), HcdLocalized(@"rename", nil), HcdLocalized(@"delete", nil)];
            break;
            
        default:
            break;
    }
    
    _cellMoreActionSheet = [[HcdActionSheet alloc] initWithCancelStr:HcdLocalized(@"cancel", nil) otherButtonTitles:otherButtonTitles attachTitle:fileName];
    _cellMoreActionSheet.selectButtonAtIndex = ^(NSInteger index) {
        
    };
    
    [[UIApplication sharedApplication].keyWindow addSubview:_cellMoreActionSheet];
    [_cellMoreActionSheet showHcdActionSheet];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_pathChidren count];
}

- (id)makeCell: (NSString *)cellIdentifier withStyle: (UITableViewCellStyle) style {
    FilesListTableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[FilesListTableViewCell alloc] initWithStyle:style reuseIdentifier:cellIdentifier];
    }
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FilesListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdFilesList forIndexPath:indexPath];
    [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:kBasePadding];
    
    NSString *path = [_pathChidren objectAtIndex:indexPath.row];
    if (path) {
        [cell setFilePath:[NSString stringWithFormat:@"%@/%@", _currentPath, path]];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [FilesListTableViewCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *path = [_pathChidren objectAtIndex:indexPath.row];
    if (path) {
        path = [NSString stringWithFormat:@"%@/%@", _currentPath, path];
    }
    FileType fileType = [[HcdFileManager defaultManager] getFileTypeByPath:path];
    switch (fileType) {
        case FileType_file_dir: {
            FolderViewController *vc = [[FolderViewController alloc] init];
            vc.hidesBottomBarWhenPushed = YES;
            vc.currentPath = path;
            vc.title = [path lastPathComponent];
            [self pushViewController:vc animated:YES];
            break;
        }
            
        default:
            break;
    }
    
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
        [weakSelf tapRowAction:indexPath.row type:ActionTypeDelete];
    }];
    deleteAction.backgroundColor = kMainColor;
    [array addObject:deleteAction];
    
    UITableViewRowAction *moreAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:HcdLocalized(@"more", nil) handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [self tapRowAction:indexPath.row type:ActionTypeMore];
    }];
    [array addObject:moreAction];
    
    return array;
}

- (void)tapRowAction:(NSInteger)row type:(ActionType)type {
    switch (type) {
        case ActionTypeDelete:
        {
            // delete file or file dir
            NSString * fileName = [_pathChidren objectAtIndex:row];
            if (fileName) {
                NSString *filePath = [NSString stringWithFormat:@"%@/%@", _currentPath, fileName];
                BOOL res = [[HcdFileManager defaultManager] deleteFileByPath:filePath];
                if (res) {
                    [_pathChidren removeObjectAtIndex:row];
                    [_tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                } else {
                    
                }
            }
            
            break;
        }
        case ActionTypeMore:
        {
            // more actions
            [self showCellMoreActionSheet:row];
            break;
        }
            
        default:
            break;
    }
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
