//
//  SendEmailViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2019/5/4.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "SendEmailViewController.h"

@interface SendEmailViewController ()

@end

@implementation SendEmailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationBar.translucent = NO;
    [UINavigationBar appearance].tintColor = kNavBgColor;
    [UINavigationBar appearance].barTintColor = kNavBgColor;
    [UINavigationBar appearance].backgroundColor = kNavBgColor;
    [UINavigationBar appearance].titleTextAttributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18], NSForegroundColorAttributeName: kNavTitleColor};
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
