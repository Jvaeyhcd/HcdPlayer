//
//  FolderViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2019/1/19.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import "FolderViewController.h"
#import "HcdFileManager.h"
#import "FilesListTableViewCell.h"
#import "UITableView+Hcd.h"
#import "FolderViewController.h"
#import "HcdActionSheet.h"
#import "HcdAlertInputView.h"
#import "SortViewController.h"
#import "MoveViewController.h"
#import "EditBottomView.h"
#import "iCloudManager.h"
#import "HcdImagePickerViewController.h"
#import "HcdFileSortManager.h"
#import "WifiTransferViewController.h"
#import "HCDPlayerViewController.h"
#import "DocumentViewController.h"
#import <YBImageBrowser/YBImageBrowser.h>

#define kEditBottomViewHeight (50 + kTabbarSafeBottomMargin)

typedef enum : NSUInteger {
    ActionTypeDelete,
    ActionTypeMore
} ActionType;

@interface FolderViewController ()<UIDocumentPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, YBImageBrowserDelegate> {
    BOOL                _isEdit;
    BOOL                _selectedAll;
}

@property (nonatomic, assign) NSInteger      selectedIndex;

@property (nonatomic, strong) EditBottomView *bottomView;
@property (nonatomic, strong) UITableView    *tableView;
@property (nonatomic, strong) NSMutableArray *pathChidren;
@property (nonatomic, strong) NSMutableArray *selectedArr;
@property (nonatomic, strong) HcdActionSheet *importActionSheet;
@property (nonatomic, strong) HcdActionSheet *navMoreActionSheet;
@property (nonatomic, strong) HcdActionSheet *fileCellMoreActionSheet;
@property (nonatomic, strong) HcdActionSheet *folderCellMoreActionSheet;
@end

@implementation FolderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initData];
    [self initSubViews];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if (_isEdit) {
        [self.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.mas_equalTo(0);
            make.height.mas_equalTo(kEditBottomViewHeight);
            make.bottom.mas_equalTo(0);
        }];
        [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(kNavHeight);
            make.right.mas_equalTo(0);
            make.bottom.mas_equalTo(-kEditBottomViewHeight);
            make.left.mas_equalTo(0);
        }];
    } else {
        [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(kNavHeight);
            make.right.mas_equalTo(0);
            make.bottom.mas_equalTo(0);
            make.left.mas_equalTo(0);
        }];
        [self.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.mas_equalTo(0);
            make.height.mas_equalTo(kEditBottomViewHeight);
            make.top.mas_equalTo(self.view.bounds.size.height);
        }];
    }
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

- (void)viewDidAppear:(BOOL)animated {
    if (!_isEdit) {
        [self reloadDatas];
    } else {
        [self reloadSelectedEditCell];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    
    [self setNavigationBarBackgroundColor:kNavBgColor titleColor:kNavTitleColor];
}

- (void)initData {
    _isEdit = NO;
    _selectedAll = NO;
    
    self.pathChidren = [[NSMutableArray alloc]initWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:_currentPath error:nil]];
    self.pathChidren = [[HcdFileSortManager sharedInstance] sortArray:self.pathChidren inPath:_currentPath];
    self.selectedArr = [[NSMutableArray alloc] init];
#if DEBUG
    for (NSString *str in self.pathChidren) {
        NSLog(@"%@", str);
        float size = [[HcdFileManager sharedHcdFileManager] sizeOfPath:[NSString stringWithFormat:@"%@/%@", _currentPath, str]];
        NSLog(@"%lf", size);
    }
#endif
    [self loadDataWithSelected:NO];
}

- (void)loadDataWithSelected:(BOOL)selected {
    [self.selectedArr removeAllObjects];
    if (selected) {
        [self.pathChidren enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
        }];
        [self.selectedArr addObjectsFromArray:self.pathChidren];
    } else {
        [self.tableView reloadData];
    }
    
}

- (void)initSubViews {
    if (self.titleStr) {
        self.title = self.titleStr;
    } else {
        self.title = HcdLocalized(@"local", nil);
    }
    [self showBarButtonItemWithImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_more"] position:RIGHT];
    [self showBarButtonItemWithImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_back"] position:LEFT];
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.bottomView];
}

- (void)reloadDatas {
    
    self.pathChidren = [[NSMutableArray alloc] initWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:_currentPath error:nil]];
    self.pathChidren = [[HcdFileSortManager sharedInstance] sortArray:self.pathChidren inPath:_currentPath];
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
    [self popViewController:YES];
}

- (void)rightNavBarButtonClicked {
    if (self.tableView.isEditing) {
        _isEdit = NO;
        [self showBarButtonItemWithImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_more"] position:RIGHT];
        [self.tableView setEditing:_isEdit animated:YES];
        [self hideEditTableView];
    } else {
        [[UIApplication sharedApplication].keyWindow addSubview:self.navMoreActionSheet];
        [self.navMoreActionSheet showHcdActionSheet];
    }
}

- (void)showEditTableView {
    [UIView animateWithDuration:0.5 animations:^{
        [self.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.mas_equalTo(0);
            make.height.mas_equalTo(kEditBottomViewHeight);
            make.bottom.mas_equalTo(0);
        }];
    } completion:^(BOOL finished) {
        
        [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(kNavHeight);
            make.right.mas_equalTo(0);
            make.bottom.mas_equalTo(-kEditBottomViewHeight);
            make.left.mas_equalTo(0);
        }];
    }];
}

- (void)hideEditTableView {
    _selectedAll = NO;
    [self.selectedArr removeAllObjects];
    [UIView animateWithDuration:0.5 animations:^{
        [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(kNavHeight);
            make.right.mas_equalTo(0);
            make.bottom.mas_equalTo(0);
            make.left.mas_equalTo(0);
        }];
        [self.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.mas_equalTo(0);
            make.height.mas_equalTo(kEditBottomViewHeight);
            make.top.mas_equalTo(self.view.bounds.size.height);
        }];
    } completion:^(BOOL finished) {
//        [self.bottomView removeFromSuperview];
        [self.bottomView.allBtn setSelected:NO];
    }];
}

- (void)showCellMoreActionSheet:(NSInteger)index {
    
    if (_selectedIndex != index) {
        _selectedIndex = index;
    }
    
    [[UIApplication sharedApplication].keyWindow addSubview:self.fileCellMoreActionSheet];
    [self.fileCellMoreActionSheet showHcdActionSheet];
    
    //    NSString *path = [NSString stringWithFormat:@"%@/%@", _currentPath, [self.pathChidren objectAtIndex:index]];
    //    FileType fileType = [[HcdFileManager sharedHcdFileManager] getFileTypeByPath:path];
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
    
    NSString *fileName = [self.pathChidren objectAtIndex:_selectedIndex];
    
    HcdAlertInputView *newFolderView = [[HcdAlertInputView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
    newFolderView.tips = [NSString stringWithFormat:@"%@(%@)", HcdLocalized(@"rename", nil), fileName];
    newFolderView.placeHolder = [fileName stringByDeletingPathExtension];
    __weak FolderViewController *weakSelf = self;
    newFolderView.commitBlock = ^(NSString * _Nonnull content) {
        [weakSelf renamePath:content];
    };
    [newFolderView showReplyInView:[UIApplication sharedApplication].keyWindow];
}

#pragma mark - getter

- (EditBottomView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[EditBottomView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height, kScreenWidth, kEditBottomViewHeight)];
        _bottomView.backgroundColor = [UIColor colorRGBHex:0xffffff darkColorRGBHex:0x1C1C1E];
        [_bottomView.allBtn addTarget:self action:@selector(selectAllEdit) forControlEvents:UIControlEventTouchUpInside];
        [_bottomView.moveBtn addTarget:self action:@selector(moveSelectedPath) forControlEvents:UIControlEventTouchUpInside];
        [_bottomView.deleteBtn addTarget:self action:@selector(showDeleteMultipleSelectActionSheet) forControlEvents:UIControlEventTouchUpInside];
    }
    return _bottomView;
}

- (HcdActionSheet *)importActionSheet {
    if (!_importActionSheet) {
        _importActionSheet = [[HcdActionSheet alloc] initWithCancelStr:HcdLocalized(@"cancel", nil) otherButtonTitles:@[HcdLocalized(@"icloud", nil), HcdLocalized(@"wifi_transfer", nil)] attachTitle:HcdLocalized(@"import_tips", nil)];
        __weak FolderViewController *weakSelf = self;
        _importActionSheet.seletedButtonIndex = ^(NSInteger index) {
            switch (index) {
                case 1:
                    [weakSelf showiCloudDocumentPicker];
                    break;
                case 2:
                    [weakSelf showWiFiTransferViewController];
                    break;
                default:
                    break;
            }
        };
    }
    return _importActionSheet;
}

-(HcdActionSheet *)navMoreActionSheet {
    if (!_navMoreActionSheet) {
        NSArray *otherButtonTitles = @[HcdLocalized(@"new_folder", nil), HcdLocalized(@"import", nil), HcdLocalized(@"select", nil), HcdLocalized(@"sort", nil)];
        _navMoreActionSheet = [[HcdActionSheet alloc] initWithCancelStr:HcdLocalized(@"cancel", nil) otherButtonTitles:otherButtonTitles attachTitle:nil];
        __weak FolderViewController *weakSelf = self;
        _navMoreActionSheet.seletedButtonIndex = ^(NSInteger index) {
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
//                    [weakSelf showiCloudDocumentPicker];
                    [weakSelf showImportActionSheet];
                    break;
                }
                case 3: {
                    [weakSelf setTableViewEdit:YES];
                    break;
                }
                case 4: {
                    SortViewController *vc = [[SortViewController alloc] init];
                    BaseNavigationController *nvc = [[BaseNavigationController alloc] initWithRootViewController:vc];
                    nvc.modalPresentationStyle = UIModalPresentationFullScreen;
                    [weakSelf presentViewController:nvc animated:YES completion:^{
                        
                    }];
                    break;
                }
                    
                    
                default:
                    break;
            }
        };
    }
    return _navMoreActionSheet;
}

-(HcdActionSheet *)fileCellMoreActionSheet {
    if (!_fileCellMoreActionSheet) {
        NSArray *otherButtonTitles = @[HcdLocalized(@"move", nil), HcdLocalized(@"rename", nil), HcdLocalized(@"select", nil), HcdLocalized(@"delete", nil)];
        _fileCellMoreActionSheet = [[HcdActionSheet alloc] initWithCancelStr:HcdLocalized(@"cancel", nil) otherButtonTitles:otherButtonTitles attachTitle:nil];
        
        __weak FolderViewController *weakSelf = self;
        _fileCellMoreActionSheet.seletedButtonIndex = ^(NSInteger index) {
            switch (index) {
                case 1:
                    [weakSelf showMoveViewController];
                    break;
                case 2: {
                    [weakSelf showRenameAlterView];
                    break;
                }
                case 3: {
                    [weakSelf setTableViewEdit:YES];
                    [weakSelf updateEditSelectedCell:weakSelf.selectedIndex];
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
    return _fileCellMoreActionSheet;
}

- (HcdActionSheet *)folderCellMoreActionSheet {
    if (!_folderCellMoreActionSheet) {
        NSArray *otherButtonTitles = @[HcdLocalized(@"lock", nil), HcdLocalized(@"move", nil), HcdLocalized(@"rename", nil), HcdLocalized(@"delete", nil)];
        _folderCellMoreActionSheet = [[HcdActionSheet alloc] initWithCancelStr:HcdLocalized(@"cancel", nil) otherButtonTitles:otherButtonTitles attachTitle:nil];
        
        __weak FolderViewController *weakSelf = self;
        _folderCellMoreActionSheet.seletedButtonIndex = ^(NSInteger index) {
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
    return _folderCellMoreActionSheet;
}

#pragma mark - private function

- (void)selectAllEdit {
    _selectedAll = !_selectedAll;
    [self.bottomView.allBtn setSelected:_selectedAll];
    [self loadDataWithSelected:_selectedAll];
}

- (void)moveSelectedPath {
    NSMutableArray *fileList = [[NSMutableArray alloc] init];
    for (NSString *path in self.selectedArr) {
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@", _currentPath, path];
        [fileList addObject:fullPath];
    }
    
    MoveViewController *vc = [[MoveViewController alloc] init];
    vc.currentPath = _currentPath;
    vc.fileList = fileList;
    BaseNavigationController *nav = [[BaseNavigationController alloc] initWithRootViewController: vc];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)updateEditSelectedCell:(NSUInteger)index {
    
    BOOL add = YES;
    NSString *fileName = [self.pathChidren objectAtIndex:index];
    for (NSString *file in self.selectedArr) {
        if ([file isEqualToString:fileName]) {
            add = NO;
            break;
        }
    }
    if (add) {
        [self.selectedArr addObject:fileName];
    } else {
        [self.selectedArr removeObject:fileName];
    }
    if ([self.selectedArr count] == [self.pathChidren count]) {
        _selectedAll = YES;
    } else {
        _selectedAll = NO;
    }
    [self.bottomView.allBtn setSelected:_selectedAll];
    [self.selectedArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger index = [self getSelectedCellIndex:self.selectedArr[idx]];
        if (index >=0 && index < [self.pathChidren count]) {
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }];
}

- (void)reloadSelectedEditCell {
    
    self.pathChidren = [[NSMutableArray alloc] initWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:_currentPath error:nil]];
    [self.tableView reloadData];
    [self.selectedArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger index = [self getSelectedCellIndex:self.selectedArr[idx]];
        if (index >=0 && index < [self.pathChidren count]) {
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }];
}

- (NSInteger)getSelectedCellIndex:(NSString *)fileName {
    NSInteger index = -1;
    for (NSInteger i = 0; i < [self.pathChidren count]; i++) {
        NSString *file = [self.pathChidren objectAtIndex:i];
        if ([fileName isEqualToString:file]) {
            index = i;
            break;
        }
    }
    return index;
}

- (void)setTableViewEdit: (BOOL)edit {
    if (!self.pathChidren || self.pathChidren.count == 0) {
        return;
    }
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
    
    NSString *fileNmae = [self.pathChidren objectAtIndex:_selectedIndex];
    
    MoveViewController *vc = [[MoveViewController alloc] init];
    vc.currentPath = _currentPath;
    vc.fileList = [[NSMutableArray alloc] initWithObjects:[NSString stringWithFormat:@"%@/%@", _currentPath, fileNmae], nil];
    BaseNavigationController *nav = [[BaseNavigationController alloc] initWithRootViewController: vc];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

// 显示删除按钮
- (void)showDeleteActionSheet {
    NSString *fileNmae = [self.pathChidren objectAtIndex:_selectedIndex];
    
    HcdActionSheet *deleteSheet = [[HcdActionSheet alloc] initWithCancelStr:HcdLocalized(@"cancel", nil) otherButtonTitles:@[HcdLocalized(@"ok", nil)] attachTitle:[NSString stringWithFormat:HcdLocalized(@"sureDelete", nil), fileNmae]];
    
    __weak FolderViewController *weakSelf = self;
    deleteSheet.seletedButtonIndex = ^(NSInteger index) {
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
    NSString * fileName = [self.pathChidren objectAtIndex:_selectedIndex];
    if (fileName) {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", _currentPath, fileName];
        BOOL res = [[HcdFileManager sharedHcdFileManager] deleteFileByPath:filePath];
        if (res) {
            [self.pathChidren removeObjectAtIndex:_selectedIndex];
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_selectedIndex inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView reloadData];
        } else {
            
        }
    }
}

- (void)showDeleteMultipleSelectActionSheet {
    
    HcdActionSheet *deleteSheet = [[HcdActionSheet alloc] initWithCancelStr:HcdLocalized(@"cancel", nil) otherButtonTitles:@[HcdLocalized(@"ok", nil)] attachTitle:HcdLocalized(@"sure_delete_selected", nil)];
    
    __weak FolderViewController *weakSelf = self;
    deleteSheet.seletedButtonIndex = ^(NSInteger index) {
        switch (index) {
            case 1:
                [weakSelf deleteSelectedCell];
                break;
            default:
                break;
        }
    };
    [[UIApplication sharedApplication].keyWindow addSubview:deleteSheet];
    [deleteSheet showHcdActionSheet];
}

- (void)deleteSelectedCell {
    NSMutableArray *deleteIndexList = [[NSMutableArray alloc] init];
    NSMutableArray *selectArr = [[NSMutableArray alloc] initWithArray:self.selectedArr];
    NSMutableArray *successArr = [[NSMutableArray alloc] init];
    for (NSString *fileName in selectArr) {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", _currentPath, fileName];
        BOOL res = [[HcdFileManager sharedHcdFileManager] deleteFileByPath:filePath];
        if (res) {
            NSInteger index = [self getSelectedCellIndex:fileName];
            [successArr addObject:fileName];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            [deleteIndexList addObject:indexPath];
        }
    }
    for (NSString *fileName in successArr) {
        [self.selectedArr removeObject:fileName];
        [self.pathChidren removeObject:fileName];
    }
    [self.tableView deleteRowsAtIndexPaths:deleteIndexList withRowAnimation:UITableViewRowAnimationFade];
}

- (void)showImportActionSheet {
    [[UIApplication sharedApplication].keyWindow addSubview:self.importActionSheet];
    [self.importActionSheet showHcdActionSheet];
}

- (void)showiCloudDocumentPicker {
    
    [self setNavigationBarBackgroundColor:[UIColor whiteColor] titleColor:[UIColor blackColor]];
    
    NSArray *documentTypes = @[@"public.content", @"public.text", @"public.source-code ", @"public.image", @"public.audiovisual-content", @"com.adobe.pdf", @"com.apple.keynote.key", @"com.microsoft.word.doc", @"com.microsoft.excel.xls", @"com.microsoft.powerpoint.ppt", @"public.avi", @"public.3gpp", @"public.mpeg-4", @"public.jpeg", @"public.png"];
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:documentTypes inMode:UIDocumentPickerModeOpen];
    picker.delegate = self;
    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)showWiFiTransferViewController {
    BaseNavigationController *nav = [[BaseNavigationController alloc] initWithRootViewController:[WifiTransferViewController new]];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)showImagePicker {
    [UINavigationBar appearance].tintColor = [UIColor whiteColor];
    //    UIImagePickerController *picker = [[UIImagePickerController alloc] ]
    HcdImagePickerViewController *picker = [[HcdImagePickerViewController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.navigationController presentViewController:picker animated:YES completion:nil];
}

- (void)createFolder:(NSString *)name {
    BOOL res = [[HcdFileManager sharedHcdFileManager] createDir:name inDir:_currentPath];
    if (res) {
        [self reloadDatas];
    }
}

- (void)renamePath:(NSString *)newName {
    NSString *oldPath = [self.pathChidren objectAtIndex:_selectedIndex];
    [self renamePath:oldPath newPath:newName];
}

- (void)renamePath:(NSString *)path newPath:(NSString *)newPath {
    
    NSString *fullPath = [NSString stringWithFormat:@"%@/%@", _currentPath, path];
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:NULL];
    NSString *type = [attributes fileType];
    if ([type isEqualToString:NSFileTypeDirectory]) {
        BOOL res = [[HcdFileManager sharedHcdFileManager] renameFileName:path newName:newPath inPath:_currentPath];
        if (res) {
            [self reloadCellAtRow:_selectedIndex newName:newPath];
        }
    } else {
        NSString *suffix = [fullPath pathExtension];
        newPath = [NSString stringWithFormat:@"%@.%@", newPath, suffix];
        BOOL res = [[HcdFileManager sharedHcdFileManager] renameFileName:path newName:newPath inPath:_currentPath];
        if (res) {
            [self reloadCellAtRow:_selectedIndex newName:newPath];
        }
    }
}

- (void)reloadCellAtRow:(NSInteger)row newName:(NSString *)newName {
    [self.pathChidren replaceObjectAtIndex:row withObject:newName];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.pathChidren count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FilesListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdFilesList forIndexPath:indexPath];
    [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:kBasePadding];
    
    NSString *path = [self.pathChidren objectAtIndex:indexPath.row];
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
        [self updateEditSelectedCell:indexPath.row];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        NSString *path = [self.pathChidren objectAtIndex:indexPath.row];
        if (path) {
            path = [NSString stringWithFormat:@"%@/%@", _currentPath, path];
        }
        FileType fileType = [[HcdFileManager sharedHcdFileManager] getFileTypeByPath:path];
        switch (fileType) {
            case FileType_file_dir: {
                NSString *folder = [path lastPathComponent];
                FolderViewController *vc = [[FolderViewController alloc] init];
                vc.titleStr = folder;
                vc.hidesBottomBarWhenPushed = YES;
                vc.currentPath = path;
                vc.title = [path lastPathComponent];
                [self pushViewController:vc animated:YES];
                break;
            }
            case FileType_music:
            case FileType_video: {
//                NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
//                if ([path.pathExtension isEqualToString:@"wmv"]) {
//                    parameters[HcdMovieParameterMinBufferedDuration] = @(5.0);
//                }
//                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
//                    parameters[HcdMovieParameterDisableDeinterlacing] = @(YES);
//                }
//                HcdMovieViewController *movieVc = [HcdMovieViewController movieViewControllerWithContentPath:path parameters:parameters];
//                movieVc.modalPresentationStyle = UIModalPresentationFullScreen;
//                [self presentViewController:movieVc animated:YES completion:nil];
                HCDPlayerViewController *vc = [[HCDPlayerViewController alloc] init];
                vc.url = [NSString stringWithFormat:@"file://%@", path];
                vc.modalPresentationStyle = UIModalPresentationFullScreen;
                [self presentViewController:vc animated:YES completion:nil];
                break;
            }
            case FileType_doc:
            case FileType_pdf:
            case FileType_txt:
            case FileType_xls:
            {
                DocumentViewController *vc = [[DocumentViewController alloc] init];
                vc.documentPath = path;
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                nav.modalPresentationStyle = UIModalPresentationFullScreen;
                [self presentViewController:nav animated:YES completion:nil];
                break;
            }
            case FileType_img:
            {
                NSMutableArray *array = [[HcdFileManager sharedHcdFileManager] getAllImagesInPathArray:self.pathChidren withPath:_currentPath];
                NSLog(@"%@", array);
                NSMutableArray *dataSourceArray = [NSMutableArray array];
                NSInteger currentPage = 0;
                if (array && [array count] > 0) {
                    for (int i = 0; i < array.count; i++) {
                        YBIBImageData *data1 = [YBIBImageData new];
                        data1.imagePath = [array objectAtIndex:i];
                        [dataSourceArray addObject:data1];
                        if ([path isEqualToString:[array objectAtIndex:i]]) {
                            currentPage = i;
                        }
                    }
                }
                YBImageBrowser *browser = [YBImageBrowser new];
                browser.delegate = self;
                browser.supportedOrientations = UIInterfaceOrientationMaskPortrait;
                browser.dataSourceArray = dataSourceArray;
                browser.currentPage = currentPage;
                browser.defaultToolViewHandler.topView.operationType = YBIBTopViewOperationTypeSave;
                [browser show];
                browser.defaultToolViewHandler.topView.frame = CGRectMake(0, kStatusBarHeight, kScreenWidth, kNavHeight - kStatusBarHeight);
                break;
            }
            default:
                break;
        }
    }
    
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.isEditing) {
        [self updateEditSelectedCell:indexPath.row];
    }
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

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    [self saveFileByURL:url];
    
    [self setNavigationBarBackgroundColor:kNavBgColor titleColor:kNavTitleColor];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    if (urls && [urls count] > 0) {
        for (NSURL *url in urls) {
            [self saveFileByURL:url];
        }
    }
    
    [self setNavigationBarBackgroundColor:kNavBgColor titleColor:kNavTitleColor];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    
    [self setNavigationBarBackgroundColor:kNavBgColor titleColor:kNavTitleColor];
}

- (void)saveFileByURL:(NSURL *)url {
    NSString *path = [[url absoluteString] stringByRemovingPercentEncoding];
    NSString *fileName = [path lastPathComponent];
    NSString *currentPath = _currentPath;
    
    NSString *fullPath = [NSString stringWithFormat:@"%@/%@", currentPath, fileName];
    if (![[HcdFileManager sharedHcdFileManager] fileExists:fullPath]) {
        __weak FolderViewController *weakSelf = self;
        [iCloudManager downloadWithDocumentURL:url callBack:^(id  _Nonnull obj) {
            NSData *data = obj;
            [data writeToFile:fullPath atomically:YES];
            [weakSelf reloadDatas];
        }];
    } else {
        // 文件已经存在
        NSLog(@"文件已经存在");
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    
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
    return [[NSAttributedString alloc]initWithString:HcdLocalized(@"listEmptyTips", nil) attributes:attributes];
}

#pragma mark - YBImageBrowserDelegate

- (void)yb_imageBrowser:(YBImageBrowser *)imageBrowser respondsToLongPressWithData:(id<YBIBDataProtocol>)data {
    
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
