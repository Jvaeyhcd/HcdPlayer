//
//  AboutViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2019/4/17.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "AboutViewController.h"
#import "SendEmailViewController.h"
#import "VersionView.h"
#import "HcdValueTableViewCell.h"
#import "UITableView+Hcd.h"
#import <StoreKit/StoreKit.h>

enum {
    HcdAboutContactUs,
    HcdAboutRate,
    HcdAboutNewVersion,
    HcdAboutCount
};

@interface AboutViewController ()<UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate, SKStoreProductViewControllerDelegate>

@property (nonatomic, retain) VersionView *versionView;
@property (nonatomic, retain) UITableView *tableView;

@end

@implementation AboutViewController

- (VersionView *)versionView {
    if (!_versionView) {
        _versionView = [[VersionView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, scaleFromiPhoneXDesign(140) + 40)];
        _versionView.backgroundColor = kMainBgColor;
    }
    return _versionView;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight) style:UITableViewStylePlain];
        [_tableView registerClass:[HcdValueTableViewCell class] forCellReuseIdentifier:kCellIdValueCell];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return _tableView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = HcdLocalized(@"about", nil);
    [self showBarButtonItemWithImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_back"] position:LEFT];
    [self.view addSubview:self.versionView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.versionView.mas_bottom);
        make.left.mas_equalTo(0);
        make.right.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
    }];
    self.view.backgroundColor = kMainBgColor;
}

#pragma mark - UITableViewDelegate, UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return HcdAboutCount;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [HcdValueTableViewCell cellHeight];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HcdValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdValueCell forIndexPath:indexPath];
    switch (indexPath.row) {
        case HcdAboutNewVersion:
            cell.titleLbl.text = HcdLocalized(@"update_version", nil);
            break;
        case HcdAboutContactUs:
            cell.titleLbl.text = HcdLocalized(@"contact_us", nil);
            break;
        case HcdAboutRate:
            cell.titleLbl.text = HcdLocalized(@"praise", nil);
            break;
        default:
            break;
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:kBasePadding];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case HcdAboutNewVersion:
            [self gotoAppStore];
            break;
        case HcdAboutContactUs:
            [self contactUsByEmail];
            break;
        case HcdAboutRate:
            [self goToAppStoreComment];
            break;
        default:
            break;
    }
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - SKStoreProductViewControllerDelegate
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [self dismissViewControllerAnimated:viewController completion:nil];
}

#pragma mark - private

- (void)leftNavBarButtonClicked {
    [self popViewController:YES];
}

/**
 发送邮件联系我们
 */
- (void)contactUsByEmail {
    if (![MFMailComposeViewController canSendMail]) {
        return;
    }
    
    NSString *title = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (title == nil) {
        title = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    }
    NSString *version = [[[NSBundle mainBundle] infoDictionary]objectForKey:@"CFBundleShortVersionString"];
    NSString *subject = [NSString stringWithFormat:@"[%@ %@]", title, version];
    NSString *message = @"";
    MFMailComposeViewController *vc = [[SendEmailViewController alloc] init];
    vc.title = subject;
    vc.navigationBar.tintColor = kNavTitleColor;
    
    [vc setSubject:subject];
    [vc setMessageBody:message isHTML:NO];
    [vc setToRecipients:@[@"chedahuang@icloud.com"]];
    vc.mailComposeDelegate = self;
    [self presentViewController:vc animated:YES completion:nil];
}

/**
 跳转至App Store编写评论
 */
- (void)goToAppStoreComment {
    
    NSString *str = [NSString stringWithFormat:  @"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@", KAPPID];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:str]];
    
}


/**
 跳转至App Store
 */
- (void)gotoAppStore {
    NSString * urlStr = [NSString stringWithFormat: @"itms-apps://itunes.apple.com/app/id%@", KAPPID];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlStr]];
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
