//
//  MoveViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2019/1/23.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "MoveViewController.h"
#import "HcdFileManager.h"
#import "UITableView+Hcd.h"
#import "FilesListTableViewCell.h"
#import "HcdAlertInputView.h"
#import "HDownloadModel.h"
#import "HDownloadManager.h"

@interface MoveViewController () {
    BOOL                _isRoot;
    NSMutableArray      *_folderPathList;
    UITableView         *_tableView;
}

@property (nonatomic, strong) UIButton *okBtn;

@end

@implementation MoveViewController
@synthesize currentPath = _currentPath;
@synthesize fileList = _fileList;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initSubviews];
    [self initDatas];
    [self reloadDatas];
}

- (void)initDatas {
    _folderPathList = [[NSMutableArray alloc] init];
    _isRoot = YES;
}

- (void)initSubviews {
    [self.view setBackgroundColor:kMainBgColor];
    [self showBarButtonItemWithStr:HcdLocalized(@"cancel", nil) position:LEFT];
    [self showBarButtonItemWithImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_add"] position:RIGHT];
    if (!_tableView) {
        [self createTableView];
    }
    
    UIButton *okBtn = [[UIButton alloc] init];
    [okBtn setBackgroundColor:kMainColor];
    okBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [okBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [okBtn setTitle:HcdLocalized(@"move", nil) forState:UIControlStateNormal];
    [okBtn addTarget:self action:@selector(moveFile) forControlEvents:UIControlEventTouchUpInside];
    
    CGFloat bottomHeight = scaleFromiPhoneXDesign(50);
    if (iPhoneX) {
        okBtn.layer.cornerRadius = 4;
        bottomHeight = scaleFromiPhoneXDesign(50) + kBasePadding + kTabbarSafeBottomMargin;
        [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(0);
            make.left.mas_equalTo(0);
            make.right.mas_equalTo(0);
            make.bottom.mas_equalTo(-bottomHeight);
        }];
        
        UIView *bottomView = [[UIView alloc] init];
        bottomView.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:bottomView];
        [bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(0);
            make.right.mas_equalTo(0);
            make.bottom.mas_equalTo(0);
            make.height.mas_equalTo(bottomHeight);
        }];
        
        [bottomView addSubview:okBtn];
        [okBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(kBasePadding);
            make.top.mas_equalTo(kBasePadding);
            make.right.mas_equalTo(-kBasePadding);
            make.height.mas_equalTo(scaleFromiPhoneXDesign(50));
        }];
    } else {
        okBtn.layer.cornerRadius = 0;
        [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(0);
            make.left.mas_equalTo(0);
            make.right.mas_equalTo(0);
            make.bottom.mas_equalTo(-bottomHeight);
        }];
        [self.view addSubview:okBtn];
        [okBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(0);
            make.right.mas_equalTo(0);
            make.bottom.mas_equalTo(0);
            make.height.mas_equalTo(bottomHeight);
        }];
    }
    self.okBtn = okBtn;
    if (self.isDownload) {
        [self.okBtn setTitle:HcdLocalized(@"download", nil) forState:UIControlStateNormal];
    } else {
        [self.okBtn setTitle:HcdLocalized(@"move", nil) forState:UIControlStateNormal];
    }
}

- (void)reloadDatas {
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    if (_currentPath && [_currentPath isEqualToString:documentPath]) {
        self.title = @"Documents";
        _isRoot = YES;
    } else {
        NSString *name = [_currentPath lastPathComponent];
        self.title = name;
        _isRoot = NO;
    }
    _folderPathList = [[HcdFileManager sharedHcdFileManager] getAllFolderByPath:_currentPath];
    [_tableView reloadData];
}

- (void)createTableView {
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.emptyDataSetSource = self;
    _tableView.emptyDataSetDelegate = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_tableView registerClass:[FilesListTableViewCell class] forCellReuseIdentifier:kCellIdFilesList];
    
    [self.view addSubview:_tableView];
}

- (void)leftNavBarButtonClicked {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)rightNavBarButtonClicked {
    __weak MoveViewController *weakSelf = self;
    HcdAlertInputView *newFolderView = [[HcdAlertInputView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
    newFolderView.tips = HcdLocalized(@"new_folder", nil);
    newFolderView.commitBlock = ^(NSString * _Nonnull content) {
        [weakSelf createFolder:content];
    };
    [newFolderView showReplyInView:[UIApplication sharedApplication].keyWindow];
}

- (void)setIsDownload:(BOOL)isDownload {
    _isDownload = isDownload;
    if (isDownload) {
        [self.okBtn setTitle:HcdLocalized(@"download", nil) forState:UIControlStateNormal];
    } else {
        [self.okBtn setTitle:HcdLocalized(@"move", nil) forState:UIControlStateNormal];
    }
}

#pragma mark - private

- (void)createFolder:(NSString *)name {
    BOOL res = [[HcdFileManager sharedHcdFileManager] createDir:name inDir:_currentPath];
    if (res) {
        [self reloadDatas];
    }
}

- (void)moveFile {
    if (self.isDownload) {
        // 下载文件到本地
        if (!self.session) {
            return;
        }
        
        for (NSString *filePath in _fileList) {
            HDownloadModel *model = [[HDownloadModel alloc] init];
            model.ipAddress = self.session.ipAddress;
            model.hostName = self.session.hostName;
            model.password = self.session.password;
            model.username = self.session.userName;
            model.filePath = filePath;
            model.localPath = [NSString stringWithFormat:@"%@/%@", self.currentPath, [filePath lastPathComponent]];
            
            [[HDownloadManager shared] addDownloadModels:@[model]];
            [[HDownloadManager shared] startWithDownloadModel:model];
        }
        
    } else {
        // 本地文件移动
        for (NSString *file in _fileList) {
            NSString *fileName = [file lastPathComponent];
            BOOL res = [[HcdFileManager sharedHcdFileManager] cutFile:file toPath:[NSString stringWithFormat:@"%@/%@", _currentPath, fileName]];
            if (res) {
                NSLog(@"-------------------移动成功");
            }
        }
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!_isRoot) {
        return [_folderPathList count] + 1;
    }
    return [_folderPathList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FilesListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdFilesList forIndexPath:indexPath];
    [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:kBasePadding];
    
    if (!_isRoot) {
        if (indexPath.row == 0) {
            [cell setFaterFolder:_currentPath];
        } else {
            NSString *path = [_folderPathList objectAtIndex:indexPath.row - 1];
            if (path) {
                [cell setFilePath:path];
            }
        }
        
    } else {
        NSString *path = [_folderPathList objectAtIndex:indexPath.row];
        if (path) {
            [cell setFilePath:path];
        }
    }
    
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [FilesListTableViewCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (!_isRoot) {
        if (indexPath.row == 0) {
            _currentPath = [_currentPath stringByDeletingLastPathComponent];
        } else {
            NSString *path = [_folderPathList objectAtIndex:indexPath.row - 1];
            if (path) {
                _currentPath = path;
            }
        }
    } else {
        NSString *path = [_folderPathList objectAtIndex:indexPath.row];
        if (path) {
            _currentPath = path;
        }
    }
    [self reloadDatas];
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
