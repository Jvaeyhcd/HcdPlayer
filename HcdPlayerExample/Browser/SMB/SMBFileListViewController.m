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

@interface SMBFileListViewController ()<UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

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
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = kMainBgColor;
    [self showBarButtonItemWithImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_back"] position:LEFT];
    
    [self.view addSubview:self.tableView];
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
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [FilesListTableViewCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    TOSMBSessionFile *file = self.files[indexPath.row];
    if (file.directory == YES) {
        __weak typeof(self) weakSelf = self;
        [self.session requestContentsOfDirectoryAtFilePath:file.filePath success:^(NSArray *files) {
            
            NSLog(@"");
            SMBFileListViewController *controller = [[SMBFileListViewController alloc] initWithSession:self.session title:file.name];
            controller.files = files;
            [weakSelf.navigationController pushViewController:controller animated:YES];
            
        } error:^(NSError *error) {
            
        }];
    } else {
        NSString *suffix = [[file.filePath pathExtension] lowercaseString];
        FileType fileType = [[HcdFileManager defaultManager] getFileTypeBySuffix:suffix];
        switch (fileType) {
            case FileType_music:
            case FileType_video: {
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
                NSMutableArray *array = [[HcdFileManager defaultManager] getAllImagesInPathArray:self.pathChidren withPath:_currentPath];
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

#pragma mark - DZNEmptyDataSetSource, DZNEmptyDataSetDelegate

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView {
    return YES;
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    return [UIImage imageNamed:@"hcdplayer.bundle/pic_post_null"];
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:16], NSForegroundColorAttributeName: [UIColor colorWithRGBHex:0xBBD4F3]};
    return [[NSAttributedString alloc]initWithString:HcdLocalized(@"filelist_empty_tips", nil) attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:12], NSForegroundColorAttributeName: [UIColor colorWithRGBHex:0xBBD4F3]};
    return [[NSAttributedString alloc]initWithString:HcdLocalized(@"filelist_empty_tips_2", nil) attributes:attributes];
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

- (void)setFiles:(NSArray <TOSMBSessionFile *> *)files {
    _files = files;
    self.navigationItem.title = self.directoryTitle;
    
    [self.tableView reloadData];
}

- (void)leftNavBarButtonClicked {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
