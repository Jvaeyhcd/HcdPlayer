//
//  AboutViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2019/4/17.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "AboutViewController.h"
#import "VersionView.h"

@interface AboutViewController ()

@property (nonatomic, retain) VersionView *versionView;

@end

@implementation AboutViewController

- (VersionView *)versionView {
    if (!_versionView) {
        _versionView = [[VersionView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, scaleFromiPhoneXDesign(140) + 40)];
        _versionView.backgroundColor = kMainBgColor;
    }
    return _versionView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = HcdLocalized(@"about", nil);
    [self showBarButtonItemWithImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_back"] position:LEFT];
    [self.view addSubview:self.versionView];
    self.view.backgroundColor = kMainBgColor;
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
