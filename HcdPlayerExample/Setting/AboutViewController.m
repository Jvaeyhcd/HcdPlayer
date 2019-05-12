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

enum {
    HcdAboutContactUs,
    HcdAboutRate,
    HcdAboutNewVersion,
    HcdAboutCount
};

@interface AboutViewController ()<UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate>

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
            break;
        case HcdAboutContactUs:
            [self contactUsByEmail];
            break;
        case HcdAboutRate:
            break;
        default:
            break;
    }
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - private

- (void)leftNavBarButtonClicked {
    [self popViewController:YES];
}

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
    
    [vc setSubject:subject];
    [vc setMessageBody:message isHTML:NO];
    [vc setToRecipients:@[@"chedahuang@icloud.com"]];
    vc.mailComposeDelegate = self;
    [self presentViewController:vc animated:YES completion:nil];
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
