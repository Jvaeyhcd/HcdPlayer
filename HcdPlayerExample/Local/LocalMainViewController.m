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
#import "HcdAlertInputView.h"
#import "SortViewController.h"

typedef enum : NSUInteger {
    ActionTypeDelete,
    ActionTypeMore
} ActionType;

@interface LocalMainViewController () {
    UITableView         *_tableView;
    NSString            *_currentPath;
    NSMutableArray      *_pathChidren;
    HcdActionSheet      *_navMoreActionSheet;
    HcdActionSheet      *_fileCellMoreActionSheet;
    HcdActionSheet      *_folderCellMoreActionSheet;
    NSInteger           _selectedIndex;
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
        __weak LocalMainViewController *weakSelf = self;
        _navMoreActionSheet.selectButtonAtIndex = ^(NSInteger index) {
            switch (index) {
                    case 1: {
                        // create new folder
                        HcdAlertInputView *newFolderView = [[HcdAlertInputView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
                        newFolderView.tips = HcdLocalized(@"rename", nil);
                        newFolderView.commitBlock = ^(NSString * _Nonnull content) {
                            [weakSelf createFolder:content];
                        };
                        [newFolderView showReplyInView:[UIApplication sharedApplication].keyWindow];
                        break;
                    }
                    case 2: {
                        break;
                    }
                    case 3: {
                        break;
                    }
                    case 4: {
                        SortViewController *vc = [[SortViewController alloc] init];
                        BaseNavigationController *nvc = [[BaseNavigationController alloc] initWithRootViewController:vc];
                        [weakSelf presentViewController:nvc animated:YES completion:^{
                            
                        }];
                        break;
                    }
                    
                    
                default:
                    break;
            }
        };
    }
    
    if (!_fileCellMoreActionSheet) {
        NSArray *otherButtonTitles = @[HcdLocalized(@"move", nil), HcdLocalized(@"rename", nil), HcdLocalized(@"delete", nil)];
        _fileCellMoreActionSheet = [[HcdActionSheet alloc] initWithCancelStr:HcdLocalized(@"cancel", nil) otherButtonTitles:otherButtonTitles attachTitle:nil];
        
        __weak LocalMainViewController *weakSelf = self;
        _fileCellMoreActionSheet.selectButtonAtIndex = ^(NSInteger index) {
            switch (index) {
                case 1:
                    
                    break;
                
                case 2: {
                    [weakSelf showRenameAlterView];
                    break;
                }
                case 3:
                    break;
                default:
                    break;
            }
        };
    }
    
    if (!_folderCellMoreActionSheet) {
        NSArray *otherButtonTitles = @[HcdLocalized(@"lock", nil), HcdLocalized(@"move", nil), HcdLocalized(@"rename", nil), HcdLocalized(@"delete", nil)];
        _folderCellMoreActionSheet = [[HcdActionSheet alloc] initWithCancelStr:HcdLocalized(@"cancel", nil) otherButtonTitles:otherButtonTitles attachTitle:nil];
        
        __weak LocalMainViewController *weakSelf = self;
        _folderCellMoreActionSheet.selectButtonAtIndex = ^(NSInteger index) {
            switch (index) {
                case 1:
                    
                    break;
                    
                case 2:
                    break;
                case 3: {
                    [weakSelf showRenameAlterView];
                    break;
                }
                case 4:
                    break;
                default:
                    break;
            }
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
    _tableView.emptyDataSetSource = self;
    _tableView.emptyDataSetDelegate = self;
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
    
    if (_selectedIndex != index) {
        _selectedIndex = index;
    }
    
    if (index >= [_currentPath length]) {
        return;
    }
    
    NSString *path = [NSString stringWithFormat:@"%@/%@", _currentPath, [_pathChidren objectAtIndex:index]];
    FileType fileType = [[HcdFileManager defaultManager] getFileTypeByPath:path];
    
    switch (fileType) {
        case FileType_file_dir:
            
            [[UIApplication sharedApplication].keyWindow addSubview:_folderCellMoreActionSheet];
            [_folderCellMoreActionSheet showHcdActionSheet];
            break;
            
        default:
            [[UIApplication sharedApplication].keyWindow addSubview:_fileCellMoreActionSheet];
            [_fileCellMoreActionSheet showHcdActionSheet];
            break;
    }
    
    
}

- (void)showRenameAlterView {
    
    NSString *fileNmae = [_pathChidren objectAtIndex:_selectedIndex];
    
    HcdAlertInputView *newFolderView = [[HcdAlertInputView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
    newFolderView.tips = [NSString stringWithFormat:@"%@(%@)", HcdLocalized(@"rename", nil), fileNmae];
    
    __weak LocalMainViewController *weakSelf = self;
    newFolderView.commitBlock = ^(NSString * _Nonnull content) {
        [weakSelf renamePath:content];
    };
    [newFolderView showReplyInView:[UIApplication sharedApplication].keyWindow];
}

#pragma mark - private function

- (void)createFolder:(NSString *)name {
    BOOL res = [[HcdFileManager defaultManager] createDir:name inDir:_currentPath];
    if (res) {
        [self reloadDatas];
    }
}

- (void)renamePath:(NSString *)newName {
    NSString *oldPath = [_pathChidren objectAtIndex:_selectedIndex];
    [self renamePath:oldPath newPath:newName];
}

- (void)renamePath:(NSString *)path newPath:(NSString *)newPath {
    
    NSString *fullPath = [NSString stringWithFormat:@"%@/%@", _currentPath, path];
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:NULL];
    NSString *type = [attributes fileType];
    if ([type isEqualToString:NSFileTypeDirectory]) {
        BOOL res = [[HcdFileManager defaultManager] renameFileName:path newName:newPath inPath:_currentPath];
        if (res) {
            [self reloadCellAtRow:_selectedIndex newName:newPath];
        }
    } else {
        NSString *suffix = [fullPath pathExtension];
        newPath = [NSString stringWithFormat:@"%@.%@", newPath, suffix];
        BOOL res = [[HcdFileManager defaultManager] renameFileName:path newName:newPath inPath:_currentPath];
        if (res) {
            [self reloadCellAtRow:_selectedIndex newName:newPath];
        }
    }
}

- (void)reloadCellAtRow:(NSInteger)row newName:(NSString *)newName {
    [_pathChidren replaceObjectAtIndex:row withObject:newName];
    [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
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

#pragma mark - DZNEmptyDataSetSource, DZNEmptyDataSetDelegate

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView {
    return YES;
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    return [UIImage imageNamed:@"hcdplayer.bundle/pic_post_null"];
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:16], NSForegroundColorAttributeName: [UIColor colorWithRGBHex:0xBBD4F3]};
    return [[NSAttributedString alloc]initWithString:HcdLocalized(@"listEmptyTips", nil) attributes:attributes];
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
