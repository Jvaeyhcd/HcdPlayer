//
//  SortViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2019/1/26.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "SortViewController.h"
#import "HcdValueTableViewCell.h"
#import "UITableView+Hcd.h"
#import "HcdFileSortManager.h"

#define kHeaderHeight 40

@interface SortViewController () {
    UITableView         *_tableView;
    OrderType           _orderType;
    SortType            _sortType;
}

@end

@implementation SortViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initData];
    [self initSubviews];
}

- (void)initData {
    _orderType = [HcdFileSortManager sharedInstance].orderType;
    _sortType = [HcdFileSortManager sharedInstance].sortType;
}

- (void)initSubviews {
    self.title = HcdLocalized(@"sort", nil);
    self.view.backgroundColor = kMainBgColor;
    [self showBarButtonItemWithStr:HcdLocalized(@"done", nil) position:RIGHT];
    [self createTableView];
}

- (void)rightNavBarButtonClicked {
    [[HcdFileSortManager sharedInstance] setSortType:_sortType orderType:_orderType];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

#pragma mark - private fucntion

- (void)createTableView {
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth |UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_tableView registerClass:[HcdValueTableViewCell class] forCellReuseIdentifier:kCellIdValueCell];
    _tableView.hidden = NO;
    
    [self.view addSubview:_tableView];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return SortInfoSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case SortInfoSectionSort:
            return SortTypeCount;
        case SortInfoSectionOrder:
            return OrderTypeCount;
        default:
            return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return kHeaderHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kHeaderHeight)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kBasePadding, 0, kScreenWidth - 2 * kBasePadding, kHeaderHeight)];
    label.font = [UIFont systemFontOfSize:14];
    label.textColor = [UIColor color666];
    view.backgroundColor = kCellHeaderBgColor;
    [view addSubview:label];
    switch (section) {
        case SortInfoSectionSort:
            label.text = HcdLocalized(@"sort", nil);
            break;
        case SortInfoSectionOrder:
            label.text = HcdLocalized(@"order", nil);
            break;
        default:
            break;
    }
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HcdValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdValueCell forIndexPath:indexPath];
    [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:kBasePadding];
    
    if (indexPath.section == SortInfoSectionSort) {
        if (indexPath.row == SortTypeName) {
            cell.titleLbl.text = NSLocalizedString(@"name", nil);
        } else if (indexPath.row == SortTypeSize) {
            cell.titleLbl.text = NSLocalizedString(@"size", nil);
        } else if (indexPath.row == SortTypeDate) {
            cell.titleLbl.text = NSLocalizedString(@"date", nil);
        }
        if (indexPath.row == _sortType) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    } else if (indexPath.section == SortInfoSectionOrder) {
        if (indexPath.row == OrderTypeAscending) {
            cell.titleLbl.text = NSLocalizedString(@"ascending", nil);
        } else if (indexPath.row == OrderTypeDescending) {
            cell.titleLbl.text = NSLocalizedString(@"descending", nil);
        }
        if (indexPath.row == _orderType) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [HcdValueTableViewCell cellHeight];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.section) {
        case SortInfoSectionOrder:
            _orderType = indexPath.row;
            break;
        case SortInfoSectionSort:
            _sortType = indexPath.row;
        default:
            break;
    }
    [_tableView reloadData];
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
