//
//  PasscodeViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2019/3/23.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "PasscodeViewController.h"
#import "HcdSpecialField-Swift.h"

@interface PasscodeViewController ()

@property (nonatomic, strong) HcdSpecialField *specialField;

@end

@implementation PasscodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.specialField];
    [self.specialField becomeFirstResponder];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (HcdSpecialField *)specialField {
    if (!_specialField) {
        _specialField = [[HcdSpecialField alloc] init];
        [_specialField setFrame:CGRectMake((kScreenWidth - 100) / 2, 50, 100, 40)];
        _specialField.secureTextEntry = YES;
        _specialField.numberOfDigits = 4;
        _specialField.spaceBetweenDigits = 4;
        _specialField.textColor = [UIColor colorWithRGBHex:0x333333];
        _specialField.backColor = [UIColor whiteColor];
    }
    return _specialField;
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
