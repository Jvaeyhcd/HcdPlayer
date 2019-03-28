//
//  SettingViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2019/1/19.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "SettingViewController.h"
#import "HcdValueTableViewCell.h"
#import "UITableView+Hcd.h"
#import "SortViewController.h"
#import "PasscodeViewController.h"
#import "HcdDeviceManager.h"

#import "LanguageViewController.h"

enum {
    HcdSettingSectionGeneral,
    HcdSettingSectionGesture,
    HcdSettingSectionOther,
    HcdSettingSectionCount
};

enum {
    HcdSettingGeneralLanguage,
    HcdSettingGeneralSort,
    HcdSettingGeneralPasscode,
    HcdSettingGeneralCount
};

enum {
    HcdSettingGestureOne,
    HcdSettingGestureTwo,
    HcdSettingGestureCount
};

enum {
    HcdSettingOtherAbout,
    HcdSettingOtherCount
};

@interface SettingViewController () {
    UITableView             *_tableView;
}

@end

@implementation SettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Setting";
    [self initDatas];
    [self initSubviews];
}

- (void)initDatas {
    
}

- (void)initSubviews {
    self.title = HcdLocalized(@"setting", nil);
    self.view.backgroundColor = kMainBgColor;
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
    [_tableView registerClass:[HcdValueTableViewCell class] forCellReuseIdentifier:kCellIdValueCell];
    _tableView.hidden = NO;
    
    [self.view addSubview:_tableView];
}

#pragma mark - UItableView Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return HcdSettingSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case HcdSettingSectionGeneral:
            return HcdSettingGeneralCount;
        case HcdSettingSectionGesture:
            return HcdSettingGestureCount;
        case HcdSettingSectionOther:
            return HcdSettingOtherCount;
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

    NSString *header = @"";
    switch (section) {
        case HcdSettingSectionGeneral:
            header = HcdLocalized(@"general", nil);
            break;
        case HcdSettingSectionGesture:
            header = HcdLocalized(@"gesture", nil);
            break;
        case HcdSettingSectionOther:
            header = HcdLocalized(@"other", nil);
            break;
        default:
            break;
    }
    label.text = header;
    
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HcdValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdValueCell forIndexPath:indexPath];
    
    NSString *title = @"";
    NSString *content = @"";
    if (indexPath.section == HcdSettingSectionGeneral) {
        if (indexPath.row == HcdSettingGeneralLanguage) {
            title = HcdLocalized(@"language", nil);
            content = [[HcdLocalized sharedInstance] currentLanguageStr];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else if (indexPath.row == HcdSettingGeneralSort) {
            title = HcdLocalized(@"sort", nil);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else if (indexPath.row == HcdSettingGeneralPasscode) {
            title = HcdLocalized(@"passcode-lock", nil);
            UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = switchView;
            switchView.tag = indexPath.row;
            [switchView setOn:[[HcdDeviceManager sharedInstance] needPasscode] animated:NO];
            [switchView addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventTouchUpInside];
        }
    } else if (indexPath.section == HcdSettingSectionGesture) {
        if (indexPath.row == HcdSettingGestureOne) {
            title = HcdLocalized(@"oneFingerGesture", nil);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else if (indexPath.row == HcdSettingGestureTwo) {
            title = HcdLocalized(@"twoFingerGesture", nil);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    } else if (indexPath.section == HcdSettingSectionOther) {
        if (indexPath.row == HcdSettingOtherAbout) {
            title = HcdLocalized(@"about", nil);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    
    cell.contentLbl.text = content;
    cell.titleLbl.text = title;
    [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:kBasePadding];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [HcdValueTableViewCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == HcdSettingSectionGeneral) {
        if (indexPath.row == HcdSettingGeneralLanguage) {
            LanguageViewController *vc = [[LanguageViewController alloc] init];
            vc.hidesBottomBarWhenPushed = YES;
            [self pushViewController:vc animated:YES];
        } else if (indexPath.row == HcdSettingGeneralSort) {
            SortViewController *vc = [[SortViewController alloc] init];
            BaseNavigationController *nvc = [[BaseNavigationController alloc] initWithRootViewController:vc];
            [self presentViewController:nvc animated:YES completion:^{
                
            }];
        }
    }
}

#pragma mark - private

- (void) switchChanged:(id)sender {
    UISwitch *switchControl = sender;
    switch (switchControl.tag) {
        case HcdSettingGeneralPasscode: {
            PasscodeViewController *vc = [[PasscodeViewController alloc] init];
            vc.type = PasscodeTypeSet;
            [self presentViewController:[[BaseNavigationController alloc] initWithRootViewController:vc] animated:YES completion:^{
                
            }];
            break;
        }
        default:
            break;
    }
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
