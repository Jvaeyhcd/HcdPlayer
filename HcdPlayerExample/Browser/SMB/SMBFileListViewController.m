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
#import "HcdFileManager.h"
#import "HCDPlayerViewController.h"
#import "DocumentViewController.h"
#import "YBImageBrowser.h"
#import "EditBottomView.h"
#import "MoveViewController.h"
#import "NSString+Hcd.h"

#define kEditBottomViewHeight (50 + kTabbarSafeBottomMargin)

typedef enum : NSUInteger {
    ActionTypeDelete,
    ActionTypeMore
} ActionType;

@interface SMBFileListViewController ()<UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate> {
    NSInteger           _selectedIndex;
    BOOL                _isEdit;
    BOOL                _selectedAll;
}

@property (nonatomic, strong) EditBottomView *bottomView;

@property (nonatomic, assign) NSInteger   selectedIndex;

@property (nonatomic, strong) NSMutableArray *selectedArr;

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
        _selectedArr = [NSMutableArray array];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = kMainBgColor;
    [self showBarButtonItemWithImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_back"] position:LEFT];
    
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.bottomView];
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
            make.top.mas_equalTo(0);
            make.right.mas_equalTo(0);
            make.bottom.mas_equalTo(-kEditBottomViewHeight);
            make.left.mas_equalTo(0);
        }];
    } else {
        [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(0);
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
    [cell addLongGes:self action:@selector(longGes:)];
    
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
        TOSMBSessionFile *file = self.files[indexPath.row];
        if (file.directory == YES) {
            __weak typeof(self) weakSelf = self;
            [self.session requestContentsOfDirectoryAtFilePath:file.filePath success:^(NSArray *files) {
                
                DLog(@"");
                SMBFileListViewController *controller = [[SMBFileListViewController alloc] initWithSession:self.session title:file.name];
                controller.files = files;
                [weakSelf.navigationController pushViewController:controller animated:YES];
                
            } error:^(NSError *error) {
                
            }];
        } else {
            NSString *suffix = [[file.filePath pathExtension] lowercaseString];
            FileType fileType = [[HcdFileManager sharedHcdFileManager] getFileTypeBySuffix:suffix];
            
            // smb://{user}:{password}@{host}/{path}
            NSString *path = [self smbFilePath:file];
            
            switch (fileType) {
                case FileType_music:
                case FileType_video: {
                    HCDPlayerViewController *vc = [[HCDPlayerViewController alloc] init];
                    vc.url = [NSString stringWithFormat:@"%@", path];//@"http://image.govlan.com/Flutter%20Go%20%E5%AE%98%E6%96%B9.mp4";
                    vc.modalPresentationStyle = UIModalPresentationFullScreen;
                    [self presentViewController:vc animated:YES completion:nil];
                    break;
                }
                case FileType_doc:
                case FileType_pdf:
                case FileType_txt:
                case FileType_xls:
                case FileType_ppt:
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
                    NSMutableArray *dataSourceArray = [NSMutableArray array];
                    NSInteger currentPage = 0;
                    NSInteger j = 0;
                    if (self.files && [self.files count] > 0) {
                        for (int i = 0; i < self.files.count; i++) {
                            TOSMBSessionFile *file = [self.files objectAtIndex:i];
                            NSString *suffix = [[file.filePath pathExtension] lowercaseString];
                            FileType fileType = [[HcdFileManager sharedHcdFileManager] getFileTypeBySuffix:suffix];
                            if (fileType == FileType_img) {
                                NSString *p = [self smbFilePath:file];
                                YBIBImageData *data = [YBIBImageData new];
                                data.imageURL = [NSURL URLWithString:p];
                                [dataSourceArray addObject:data];
                                if ([p isEqualToString:path]) {
                                    currentPage = j;
                                }
                                j++;
                            }
    //                        data1.imagePath = [self.files objectAtIndex:i];
    //                        [dataSourceArray addObject:data1];
    //                        if ([path isEqualToString:[array objectAtIndex:i]]) {
    //                            currentPage = i;
    //                        }
                        }
                    }
                    
                    
                    YBImageBrowser *browser = [YBImageBrowser new];
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
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.isEditing) {
        [self updateEditSelectedCell:indexPath.row];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    TOSMBSessionFile *file = self.files[indexPath.row];
    if (file.directory == YES) {
        return NO;
    }
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
    return [UIImage imageNamed:@"hcdplayer.bundle/pic_no_data"];
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14], NSForegroundColorAttributeName: [UIColor color999]};
    return [[NSAttributedString alloc]initWithString:HcdLocalized(@"filelist_empty_tips", nil) attributes:attributes];
}

#pragma mark - YBImageBrowserDelegate

- (void)yb_imageBrowser:(YBImageBrowser *)imageBrowser respondsToLongPressWithData:(id<YBIBDataProtocol>)data {
    
}

- (void)setFiles:(NSArray <TOSMBSessionFile *> *)files {
    _files = files;
    self.navigationItem.title = self.directoryTitle;
}

- (void)leftNavBarButtonClicked {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)rightNavBarButtonClicked {
    if (self.tableView.isEditing) {
        _isEdit = NO;
        self.navigationItem.rightBarButtonItem = nil;
        [self.tableView setEditing:_isEdit animated:YES];
        [self hideEditTableView];
    } else {
        
    }
}

#pragma mark - 长按事件
- (void)longGes:(UILongPressGestureRecognizer *)longGes{
    if (longGes.state == UIGestureRecognizerStateBegan) {//手势开始
        CGPoint point = [longGes locationInView:self.tableView];
        NSIndexPath *index = [self.tableView indexPathForRowAtPoint:point]; // 可以获取我们在哪个cell上长按
        self.selectedIndex = index.row;
    }
    if (longGes.state == UIGestureRecognizerStateEnded){//手势结束
        [self showCellMoreActionSheet:self.selectedIndex];
    }
}

#pragma mark - private

- (NSString *)smbFilePath:(TOSMBSessionFile *)file {
    
    // smb://{user}:{password}@{host}/{path}
//    NSMutableString *path = [NSMutableString stringWithString:@"smb://"];
//    if (self.session.userName) {
//        [path appendString:self.session.userName];
//        if (self.session.password) {
//            [path appendString:@":"];
//            [path appendString:self.session.password];
//        }
//        [path appendString:@"@"];
//    }
//    [path appendString:self.session.ipAddress];
//    [path appendString:file.filePath];
//
//    return [NSString stringWithFormat:@"%@", path];
    //两次URL编码
    NSMutableString *path = [[NSMutableString alloc] initWithString:@"smb://"];
    if (self.session.userName.length && self.session.password.length) {
        [path appendFormat:@"%@:%@@", [[self.session.userName stringByURLEncode] stringByURLEncode], [[self.session.password stringByURLEncode] stringByURLEncode]];
    }
    else if (self.session.userName.length && self.session.password.length == 0) {
        [path appendFormat:@"%@@", [[self.session.userName stringByURLEncode] stringByURLEncode]];
    }
    
    if (self.session.ipAddress.length) {
        [path appendString:self.session.ipAddress];
    }
    
    [path appendFormat:@"%@", [[file.filePath stringByURLEncode] stringByURLEncode]];
    
    return path;
}

// 显示删除按钮
- (void)showDeleteActionSheet {
    TOSMBSessionFile *file = [self.files objectAtIndex:_selectedIndex];
    NSString *fileNmae = [file.filePath lastPathComponent];
    
    HcdActionSheet *deleteSheet = [[HcdActionSheet alloc] initWithCancelStr:HcdLocalized(@"cancel", nil) otherButtonTitles:@[HcdLocalized(@"ok", nil)] attachTitle:[NSString stringWithFormat:HcdLocalized(@"sureDelete", nil), fileNmae]];
    
    __weak typeof(self) weakSelf = self;
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

- (void)showCellMoreActionSheet:(NSInteger)index {
    
    if (_selectedIndex != index) {
        _selectedIndex = index;
    }
    
    NSArray *otherButtonTitles = @[HcdLocalized(@"select", nil), HcdLocalized(@"download", nil)];
    HcdActionSheet *deleteSheet = [[HcdActionSheet alloc] initWithCancelStr:HcdLocalized(@"cancel", nil) otherButtonTitles:otherButtonTitles attachTitle:nil];
        
        __weak typeof(self) weakSelf = self;
        deleteSheet.seletedButtonIndex = ^(NSInteger index) {
            switch (index) {
                case 1:
                {
                    [weakSelf setTableViewEdit:YES];
                    [weakSelf updateEditSelectedCell:weakSelf.selectedIndex];
                    break;
                }
                case 2:
                {
                    [weakSelf downloadCurrentFileToPath];
                }
            default:
                break;
        }
    };
    [[UIApplication sharedApplication].keyWindow addSubview:deleteSheet];
    [deleteSheet showHcdActionSheet];
}

- (void)showEditTableView {
    _isEdit = YES;
    [UIView animateWithDuration:0.5 animations:^{
        [self.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.mas_equalTo(0);
            make.height.mas_equalTo(kEditBottomViewHeight);
            make.bottom.mas_equalTo(0);
        }];
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
    _selectedAll = NO;
    [self.selectedArr removeAllObjects];
    [UIView animateWithDuration:0.5 animations:^{
        [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(0);
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

- (void)deleteFileIndex {
    TOSMBSessionFile *file = [self.files objectAtIndex:_selectedIndex];
    
}

- (void)selectAllEdit {
    _selectedAll = !_selectedAll;
    [self.bottomView.allBtn setSelected:_selectedAll];
    [self loadDataWithSelected:_selectedAll];
}

- (void)loadDataWithSelected:(BOOL)selected {
    [self.selectedArr removeAllObjects];
    if (selected) {
        [self.files enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
        }];
        [self.selectedArr addObjectsFromArray:self.files];
    } else {
        [self.tableView reloadData];
    }
    
}

- (void)setTableViewEdit:(BOOL)edit {
    if (!self.files || self.files.count == 0) {
        return;
    }
    _isEdit = edit;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    [self.tableView setEditing:edit animated:YES];
    if (_isEdit) {
        [self showBarButtonItemWithStr:HcdLocalized(@"done", nil) position:RIGHT];
        [self showEditTableView];
    } else {
        self.navigationItem.rightBarButtonItem = nil;
        [self hideEditTableView];
    }
}

- (void)updateEditSelectedCell:(NSUInteger)index {
//    [self.tableView reloadData];
    BOOL add = YES;
    TOSMBSessionFile *file = [self.files objectAtIndex:index];
    for (TOSMBSessionFile *ff in self.selectedArr) {
        if ([ff.filePath isEqualToString:file.filePath]) {
            add = NO;
            break;
        }
    }
    if (add) {
        [self.selectedArr addObject:file];
    } else {
        [self.selectedArr removeObject:file];
    }
    if ([self.selectedArr count] == [self.files count]) {
        _selectedAll = YES;
    } else {
        _selectedAll = NO;
    }
    [self.bottomView.allBtn setSelected:_selectedAll];
    [self.selectedArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger index = [self getSelectedCellIndex:self.selectedArr[idx]];
        if (index >=0 && index < [self.files count]) {
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }];
//    [self.tableView reloadData];
}

- (BOOL)isFileSelected:(TOSMBSessionFile *)file{
    BOOL res = NO;
    
    for (TOSMBSessionFile *ff in self.selectedArr) {
        if ([ff.filePath isEqualToString:file.filePath]) {
            res = YES;
            break;
        }
    }
    
    return res;
}

- (NSInteger)getSelectedCellIndex:(TOSMBSessionFile *)smbFile {
    NSInteger index = -1;
    for (NSInteger i = 0; i < [self.files count]; i++) {
        TOSMBSessionFile *file = [self.files objectAtIndex:i];
        if ([smbFile.filePath isEqualToString:file.filePath]) {
            index = i;
            break;
        }
    }
    return index;
}

- (void)downloadToPath {
    NSMutableArray *fileList = [[NSMutableArray alloc] init];
    for (TOSMBSessionFile *file in self.selectedArr) {
        if (!file.directory) {
            [fileList addObject:file.filePath];
        }
    }
    
    MoveViewController *vc = [[MoveViewController alloc] init];
    vc.currentPath = [HSandbox docPath];
    vc.fileList = fileList;
    vc.isDownload = YES;
    vc.session = self.session;
    BaseNavigationController *nav = [[BaseNavigationController alloc] initWithRootViewController: vc];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)downloadCurrentFileToPath {
    
    TOSMBSessionFile *file = [self.files objectAtIndex:_selectedIndex];
    if (!file) {
        return;
    }
    NSMutableArray *fileList = [[NSMutableArray alloc] init];
    if (![NSString isBlankString:file.filePath]) {
        [fileList addObject:file.filePath];
    }
    
    MoveViewController *vc = [[MoveViewController alloc] init];
    vc.currentPath = [HSandbox docPath];
    vc.fileList = fileList;
    vc.isDownload = YES;
    vc.session = self.session;
    BaseNavigationController *nav = [[BaseNavigationController alloc] initWithRootViewController: vc];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

#pragma mark - lazy load

- (EditBottomView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[EditBottomView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height, kScreenWidth, kEditBottomViewHeight)];
        _bottomView.backgroundColor = [UIColor colorRGBHex:0xffffff darkColorRGBHex:0x1C1C1E];
        [_bottomView.allBtn addTarget:self action:@selector(selectAllEdit) forControlEvents:UIControlEventTouchUpInside];
        _bottomView.moveBtn.hidden = YES;
        
        NSString *text = HcdLocalized(@"download", nil);
        CGFloat width = [text widthWithConstainedWidth:SCREEN_WIDTH font:[UIFont systemFontOfSize:14]] + 32;
        
        [_bottomView.deleteBtn addTarget:self action:@selector(downloadToPath) forControlEvents:UIControlEventTouchUpInside];
        [_bottomView.deleteBtn setTitle:text forState:UIControlStateNormal];
        [_bottomView.deleteBtn mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(width);
        }];
    }
    return _bottomView;
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

@end
