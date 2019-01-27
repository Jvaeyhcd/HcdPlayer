//
//  SettingViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2019/1/19.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "SettingViewController.h"
#import "HcdValueTableViewCell.h"

@interface SettingViewController () {
    UITableView             *_tableView;
}

@end

@implementation SettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Setting";
}

- (void)initSubviews {
    self.title = HcdLocalized(@"setting", nil);
    self.view.backgroundColor = kMainBgColor;
    [self createTableView];
}

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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
