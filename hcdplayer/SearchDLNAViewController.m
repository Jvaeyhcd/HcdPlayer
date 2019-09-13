//
//  SearchDLNAViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2019/9/8.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "SearchDLNAViewController.h"
#import "HcdValueTableViewCell.h"
#import "UITableView+Hcd.h"
#import "MRDLNA.h"

@interface SearchDLNAViewController ()<UITableViewDelegate,UITableViewDataSource,DLNADelegate>

// 刷新指示器
@property (nonatomic, strong) UIActivityIndicatorView *activityView;

// 列表
@property (nonatomic, strong) UITableView *tableView;

// 设备列表数组
@property (nonatomic, copy) NSMutableArray *devicesArr;

// dlnaManager
@property (nonatomic, strong) MRDLNA  *dlnaManager;

// 刷新按钮
@property (nonatomic, strong) UIBarButtonItem *refreshBtn;

@end

@implementation SearchDLNAViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = HcdLocalized(@"select_a_device", nil);
    [self showBarButtonItemWithImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_close"] position:LEFT];
    self.navigationItem.rightBarButtonItem = self.refreshBtn;
    self.tableView.frame = self.view.bounds;
    [self makeDlnaManager];
    // 搜索设备
    [self refreshDevice];
}

#pragma mark - private

- (void)leftNavBarButtonClicked {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)refreshDevice {
    if (self.devicesArr && self.devicesArr.count > 0) {
        [self.devicesArr removeAllObjects];
    }
    
    [self.tableView reloadData];
    [self.dlnaManager startSearch];
    [self.view addSubview:self.activityView];
    [self.activityView startAnimating];
}

#pragma mark - lazy load

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [UITableView new];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor whiteColor];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [_tableView registerClass:[HcdValueTableViewCell class] forCellReuseIdentifier:kCellIdValueCell];
        [self.view addSubview:_tableView];
    }
    return _tableView;
}

- (UIActivityIndicatorView *)activityView {
    if (!_activityView) {
        _activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [_activityView setColor:[UIColor lightGrayColor]];
        _activityView.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, 200);
    }
    return _activityView;
}

- (UIBarButtonItem *)refreshBtn {
    if (!_refreshBtn) {
        _refreshBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_reload"] style:UIBarButtonItemStylePlain target:self action:@selector(refreshDevice)];
        _refreshBtn.tintColor = [UIColor whiteColor];
    }
    return _refreshBtn;
}

- (NSArray *)devicesArr {
    if (!_devicesArr) {
        _devicesArr = [NSMutableArray array];
    }
    return _devicesArr;
}


-(void)makeDlnaManager {
    self.dlnaManager = [MRDLNA sharedMRDLNAManager];
    self.dlnaManager.delegate  = self;
}

#pragma mark - UITableViewDelegate,UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.devicesArr count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [HcdValueTableViewCell cellHeight];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HcdValueTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:kCellIdValueCell forIndexPath:indexPath];
    CLUPnPDevice *device = self.devicesArr[indexPath.row];
    cell.titleLbl.text = device.friendlyName;
    [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:kBasePadding];
    return cell;
}

#pragma mark - DLNADelegate

-(void)searchDLNAResult:(NSArray *)devicesArray{
    self.devicesArr = [[NSMutableArray alloc] initWithArray:devicesArray];
}

-(void)dlnaDidEndSearch{
    [self.tableView reloadData];
    [self.activityView removeFromSuperview];
}

-(void)dealloc{
    NSLog(@"%s",__FUNCTION__);
}

@end
