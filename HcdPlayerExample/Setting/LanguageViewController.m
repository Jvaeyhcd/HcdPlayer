//
//  LanguageViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2019/2/17.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "LanguageViewController.h"
#import "HcdValueTableViewCell.h"
#import "UITableView+Hcd.h"

enum {
    HcdLanguageSystem,
    HcdLanguageChineseSimple,
    HcdLanguageEnglish,
    HcdLanguageCount
};

@interface LanguageViewController () {
    UITableView             *_tableView;
}

@end

@implementation LanguageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initSubviews];
}

- (void)initSubviews {
    self.title = HcdLocalized(@"language", nil);
    self.view.backgroundColor = kMainBgColor;
    [self showBarButtonItemWithImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_back"] position:LEFT];
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return HcdLanguageCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HcdValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdValueCell forIndexPath:indexPath];
    
    NSString *title = @"";
    
    if (indexPath.row == HcdLanguageSystem) {
        title = HcdLocalized(@"default", nil);
    } else if (indexPath.row == HcdLanguageEnglish) {
        title = HcdLocalized(@"english", nil);
    } else if (indexPath.row == HcdLanguageChineseSimple) {
        title = HcdLocalized(@"chineseSimple", nil);
    }
    
    cell.titleLlb.text = title;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:kBasePadding];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [HcdValueTableViewCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == HcdLanguageSystem) {
        [[HcdLocalized sharedInstance] systemLanguage];
    } else if (indexPath.row == HcdLanguageEnglish) {
        [[HcdLocalized sharedInstance] setLanguage:@"en"];
    } else if (indexPath.row == HcdLanguageChineseSimple) {
        [[HcdLocalized sharedInstance] setLanguage:@"zh-Hans"];
    }
    [self popViewController:YES];
}

#pragma mark - private

- (void)leftNavBarButtonClicked {
    [self popViewController:YES];
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
