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

@interface LocalMainViewController () {
    UITableView         *_tableView;
    NSString            *_currentPath;
    NSArray             *_pathChidren;
}

@end

@implementation LocalMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initData];
    [self initSubViews];
}

- (void)initData {
    _currentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    _pathChidren = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_currentPath error:nil];
    for (NSString *str in _pathChidren) {
        NSLog(@"%@", str);
        float size = [[HcdFileManager defaultManager] sizeOfPath:[NSString stringWithFormat:@"%@/%@", _currentPath, str]];
        NSLog(@"%lf", size);
    }
}

- (void)initSubViews {
    self.title = HcdLocalized(@"local", nil);
    [self showBarButtonItemWithImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_add"] position:RIGHT];
    [self showBarButtonItemWithImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_wifi"] position:LEFT];
    
    if (!_tableView) {
        [self createTableView];
    }
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
