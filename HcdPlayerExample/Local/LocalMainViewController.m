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
#import "MoveViewController.h"
#import "EditBottomView.h"

#define kEditBottomViewHeight 50

typedef enum : NSUInteger {
    ActionTypeDelete,
    ActionTypeMore
} ActionType;

@interface LocalMainViewController () {
    NSString            *_currentPath;
    NSMutableArray      *_pathChidren;
    NSMutableArray      *_selectedArr;
    HcdActionSheet      *_navMoreActionSheet;
    HcdActionSheet      *_fileCellMoreActionSheet;
    HcdActionSheet      *_folderCellMoreActionSheet;
    NSInteger           _selectedIndex;
    BOOL                _isEdit;
    BOOL                _selectedAll;
}
@property (nonatomic, strong) EditBottomView *bottomView;
@property (nonatomic, strong) UITableView    *tableView;
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
    _isEdit = NO;
    _selectedAll = NO;
    _currentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    _pathChidren = [[NSMutableArray alloc]initWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:_currentPath error:nil]];
    _selectedArr = [[NSMutableArray alloc] init];
    for (NSString *str in _pathChidren) {
        NSLog(@"%@", str);
        float size = [[HcdFileManager defaultManager] sizeOfPath:[NSString stringWithFormat:@"%@/%@", _currentPath, str]];
        NSLog(@"%lf", size);
    }
    [self loadDataWithSelected:NO];
}

- (void)loadDataWithSelected:(BOOL)selected {
    _selectedArr = [[NSMutableArray alloc] init];
//    for (NSInteger i = 0; i < [_pathChidren count]; i++) {
//        [_selectedArr addObject:@(YES)];
//        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
//        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
//    }
    [_pathChidren enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
    }];
}

- (void)initSubViews {
    self.title = HcdLocalized(@"local", nil);
    [self showBarButtonItemWithImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_more"] position:RIGHT];
    [self showBarButtonItemWithImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_wifi"] position:LEFT];
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.bottomView];
    
    if (!_navMoreActionSheet) {
        NSArray *otherButtonTitles = @[HcdLocalized(@"new_folder", nil), HcdLocalized(@"import", nil), HcdLocalized(@"select", nil), HcdLocalized(@"sort", nil)];
        _navMoreActionSheet = [[HcdActionSheet alloc] initWithCancelStr:HcdLocalized(@"cancel", nil) otherButtonTitles:otherButtonTitles attachTitle:nil];
        __weak LocalMainViewController *weakSelf = self;
        _navMoreActionSheet.selectButtonAtIndex = ^(NSInteger index) {
            switch (index) {
                    case 1: {
                        // create new folder
                        HcdAlertInputView *newFolderView = [[HcdAlertInputView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
                        newFolderView.tips = HcdLocalized(@"new_folder", nil);
                        newFolderView.placeHolder = HcdLocalized(@"new_folder_placeholder", nil);
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
                        [weakSelf setTableViewEdit:YES];
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
                    [weakSelf showMoveViewController];
                    break;
                case 2: {
                    [weakSelf showRenameAlterView];
                    break;
                }
                case 3:
                    [weakSelf showDeleteActionSheet];
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
                    [weakSelf showMoveViewController];
                    break;
                case 3: {
                    [weakSelf showRenameAlterView];
                    break;
                }
                case 4:
                    [weakSelf showDeleteActionSheet];
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
    [self.tableView reloadData];
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

- (void)leftNavBarButtonClicked {
    BaseNavigationController *nav = [[BaseNavigationController alloc] initWithRootViewController:[WifiTransferViewController new]];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)rightNavBarButtonClicked {
    if (self.tableView.isEditing) {
        _isEdit = NO;
        [self showBarButtonItemWithImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_more"] position:RIGHT];
        [self.tableView setEditing:_isEdit animated:YES];
        [self hideEditTableView];
    } else {
        if (_navMoreActionSheet) {
            [[UIApplication sharedApplication].keyWindow addSubview:_navMoreActionSheet];
            [_navMoreActionSheet showHcdActionSheet];
        }
    }
}

- (void)showEditTableView {
    [UIView animateWithDuration:0.5 animations:^{
        self.bottomView.frame = CGRectMake(0, self.view.bounds.size.height - kEditBottomViewHeight, kScreenWidth, kEditBottomViewHeight);
    } completion:^(BOOL finished) {
        [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(0);
            make.right.mas_equalTo(0);
            make.bottom.mas_equalTo(-kEditBottomViewHeight);
            make.left.mas_equalTo(0);
        }];
    }];
}

- (void)hideEditTableView {
    [UIView animateWithDuration:0.5 animations:^{
        [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(0);
            make.right.mas_equalTo(0);
            make.bottom.mas_equalTo(0);
            make.left.mas_equalTo(0);
        }];
        self.bottomView.frame = CGRectMake(0, self.view.bounds.size.height, kScreenWidth, kEditBottomViewHeight);
    } completion:^(BOOL finished) {
//        [self.bottomView removeFromSuperview];
    }];
}

- (void)showCellMoreActionSheet:(NSInteger)index {
    
    if (_selectedIndex != index) {
        _selectedIndex = index;
    }
    
    if (index >= [_currentPath length]) {
        return;
    }
    
    [[UIApplication sharedApplication].keyWindow addSubview:_fileCellMoreActionSheet];
    [_fileCellMoreActionSheet showHcdActionSheet];
    
//    NSString *path = [NSString stringWithFormat:@"%@/%@", _currentPath, [_pathChidren objectAtIndex:index]];
//    FileType fileType = [[HcdFileManager defaultManager] getFileTypeByPath:path];
//
//    switch (fileType) {
//        case FileType_file_dir:
//
//            [[UIApplication sharedApplication].keyWindow addSubview:_folderCellMoreActionSheet];
//            [_folderCellMoreActionSheet showHcdActionSheet];
//            break;
//
//        default:
//            [[UIApplication sharedApplication].keyWindow addSubview:_fileCellMoreActionSheet];
//            [_fileCellMoreActionSheet showHcdActionSheet];
//            break;
//    }
}

- (void)showRenameAlterView {
    
    NSString *fileName = [_pathChidren objectAtIndex:_selectedIndex];
    
    HcdAlertInputView *newFolderView = [[HcdAlertInputView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
    newFolderView.tips = [NSString stringWithFormat:@"%@(%@)", HcdLocalized(@"rename", nil), fileName];
    newFolderView.placeHolder = [fileName stringByDeletingPathExtension];
    __weak LocalMainViewController *weakSelf = self;
    newFolderView.commitBlock = ^(NSString * _Nonnull content) {
        [weakSelf renamePath:content];
    };
    [newFolderView showReplyInView:[UIApplication sharedApplication].keyWindow];
}

#pragma mark - getter

- (EditBottomView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[EditBottomView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height, kScreenWidth, kEditBottomViewHeight)];
        _bottomView.backgroundColor = [UIColor whiteColor];
        [_bottomView.allBtn addTarget:self action:@selector(selectAllEdit:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _bottomView;
}

#pragma mark - private function

- (void)selectAllEdit:(UIButton *)btn {
    _selectedAll = !_selectedAll;
    [self.bottomView.allBtn setSelected:_selectedAll];
    [self loadDataWithSelected:_selectedAll];
    [self.tableView reloadData];
}

- (void)setTableViewEdit: (BOOL)edit {
    _isEdit = edit;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    [self.tableView setEditing:edit animated:YES];
    if (_isEdit) {
        [self showBarButtonItemWithStr:HcdLocalized(@"done", nil) position:RIGHT];
        [self showEditTableView];
    } else {
        [self showBarButtonItemWithImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_more"] position:RIGHT];
        [self hideEditTableView];
    }
}

- (void)showMoveViewController {
    
    NSString *fileNmae = [_pathChidren objectAtIndex:_selectedIndex];
    
    MoveViewController *vc = [[MoveViewController alloc] init];
    vc.currentPath = _currentPath;
    vc.fileList = [[NSMutableArray alloc] initWithObjects:[NSString stringWithFormat:@"%@/%@", _currentPath, fileNmae], nil];
    BaseNavigationController *nav = [[BaseNavigationController alloc] initWithRootViewController: vc];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)showDeleteActionSheet {
    NSString *fileNmae = [_pathChidren objectAtIndex:_selectedIndex];
    
    HcdActionSheet *deleteSheet = [[HcdActionSheet alloc] initWithCancelStr:HcdLocalized(@"cancel", nil) otherButtonTitles:@[HcdLocalized(@"ok", nil)] attachTitle:[NSString stringWithFormat:HcdLocalized(@"sureDelete", nil), fileNmae]];
    
    __weak LocalMainViewController *weakSelf = self;
    deleteSheet.selectButtonAtIndex = ^(NSInteger index) {
        switch (index) {
            case 1:
                [weakSelf deleteFileIndex];
                break;
            default:
                break;
        }
    };
    [[UIApplication sharedApplication].keyWindow addSubview:deleteSheet];
    [deleteSheet showHcdActionSheet];
}

- (void)deleteFileIndex {
    NSString * fileName = [_pathChidren objectAtIndex:_selectedIndex];
    if (fileName) {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", _currentPath, fileName];
        BOOL res = [[HcdFileManager defaultManager] deleteFileByPath:filePath];
        if (res) {
            [_pathChidren removeObjectAtIndex:_selectedIndex];
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_selectedIndex inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        } else {

        }
    }
}

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
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_pathChidren count];
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
    
    if (tableView.isEditing) {
        
    } else {
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
            if (_selectedIndex != row) {
                _selectedIndex = row;
            }
            [self showDeleteActionSheet];
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
