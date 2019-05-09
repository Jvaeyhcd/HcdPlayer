//
//  PasscodeViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2019/3/23.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "PasscodeViewController.h"
#import "HcdSpecialField-Swift.h"
#import "HcdAppManager.h"
#import "NSString+Hcd.h"

@interface PasscodeViewController ()

@property (nonatomic, strong) HcdSpecialField *specialField;
@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, strong) UILabel *failedTipsLabel;
@property (nonatomic, copy) NSString *passcode;
@property (nonatomic, assign) NSInteger failedTimes;

@end

@implementation PasscodeViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _passcode = [HcdAppManager sharedInstance].passcode;
        _failedTimes = 0;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = HcdLocalized(@"enter-passcode", nil);
    [self.view addSubview:self.specialField];
    [self.view addSubview:self.tipsLabel];
    [self.view addSubview:self.failedTipsLabel];
    
    [self.specialField addTarget:self action:@selector(specialFieldDidChangeValue) forControlEvents:UIControlEventValueChanged];
    [self.specialField becomeFirstResponder];
    
    self.view.backgroundColor = [UIColor whiteColor];
    if (_type == PasscodeTypeSet) {
        self.tipsLabel.text = HcdLocalized(@"set-passcode-tip", nil);
    } else if (_type == PasscodeTypeCancle || _type == PasscodeTypeUnLock) {
        self.tipsLabel.text = HcdLocalized(@"enter-passcode-tip", nil);
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [HcdAppManager sharedInstance].isAllowAutorotate = NO;
    [HcdAppManager sharedInstance].passcodeViewShow = YES;
    _passcode = [HcdAppManager sharedInstance].passcode;
    _failedTimes = 0;
}

- (void)viewDidAppear:(BOOL)animated {
    [self.specialField becomeFirstResponder];
}

- (HcdSpecialField *)specialField {
    if (!_specialField) {
        _specialField = [[HcdSpecialField alloc] init];
        [_specialField setFrame:CGRectMake((kScreenWidth - 140) / 2, kScreenHeight / 4, 140, 30)];
        _specialField.backgroundColor = [UIColor whiteColor];
        _specialField.secureTextEntry = YES;
        _specialField.numberOfDigits = 4;
        _specialField.emptyDigit = @"-";
        _specialField.spaceBetweenDigits = 8;
        _specialField.textColor = [UIColor colorWithRGBHex:0x333333];
        _specialField.dashColor = [UIColor colorWithRGBHex:0x333333];
        _specialField.backColor = [UIColor whiteColor];
    }
    return _specialField;
}

- (UILabel *)tipsLabel {
    if (!_tipsLabel) {
        _tipsLabel = [[UILabel alloc] init];
        [_tipsLabel setFrame:CGRectMake(0, kScreenHeight / 4 - 50, kScreenWidth, 30)];
        _tipsLabel.textColor = [UIColor colorWithRGBHex:0x333333];
        _tipsLabel.textAlignment = NSTextAlignmentCenter;
        _tipsLabel.text = HcdLocalized(@"enter-passcode-tip", nil);
        _tipsLabel.font = [UIFont systemFontOfSize:16];
    }
    return _tipsLabel;
}

- (UILabel *)failedTipsLabel {
    if (!_failedTipsLabel) {
        _failedTipsLabel = [[UILabel alloc] init];
        _failedTipsLabel.textColor = [UIColor whiteColor];
        _failedTipsLabel.textAlignment = NSTextAlignmentCenter;
        _failedTipsLabel.backgroundColor = kMainColor;
        _failedTipsLabel.font = [UIFont systemFontOfSize:14];
        _failedTipsLabel.layer.cornerRadius = 16;
        _failedTipsLabel.layer.masksToBounds = YES;
    }
    return _failedTipsLabel;
}

@synthesize type = _type;
- (void)setType:(PasscodeType)type {
    _type = type;
}

- (void)specialFieldDidChangeValue {
    if (self.specialField.passcode.length == self.specialField.numberOfDigits) {
        // 密码输入完成
        if (_type == PasscodeTypeSet) {
            _type = PasscodeTypeRepeat;
            _passcode = self.specialField.passcode;
            self.specialField.passcode = @"";
            self.tipsLabel.text = HcdLocalized(@"repeat-passcode-tip", nil);
        } else if (_type == PasscodeTypeRepeat) {
            if (_passcode == self.specialField.passcode) {
                [self.specialField resignFirstResponder];
                [[HcdAppManager sharedInstance] setPasscode:_passcode];
                [self dismissViewControllerAnimated:YES completion:^{
                    
                }];
            } else {
                self.specialField.passcode = @"";
                _failedTimes++;
                NSString *failedTips = [NSString stringWithFormat:HcdLocalized(@"n-times-failed-passcode", nil), _failedTimes];
                CGFloat width = [failedTips widthWithConstainedWidth:kScreenWidth font:self.failedTipsLabel.font] + 18;
                self.failedTipsLabel.text = failedTips;
                self.failedTipsLabel.frame = CGRectMake((kScreenWidth - width) / 2, CGRectGetMaxY(self.specialField.frame) + kBasePadding, width, 32);
                self.failedTipsLabel.hidden = NO;
            }
        } else if (_type == PasscodeTypeUnLock) {
            if ([_passcode isEqualToString:self.specialField.passcode]) {
                self.specialField.passcode = @"";
                _failedTimes = 0;
                self.failedTipsLabel.hidden = YES;
                [[NSNotificationCenter defaultCenter] postNotificationName:DISSMISS_PASSCODE_NOTIFICATION object:nil];
                [HcdAppManager sharedInstance].passcodeViewShow = NO;
                [self dismissViewControllerAnimated:YES completion:^{
                    
                }];
            } else {
                self.specialField.passcode = @"";
                _failedTimes++;
                NSString *failedTips = [NSString stringWithFormat:HcdLocalized(@"n-times-failed-passcode", nil), _failedTimes];
                CGFloat width = [failedTips widthWithConstainedWidth:kScreenWidth font:self.failedTipsLabel.font] + 18;
                self.failedTipsLabel.text = failedTips;
                self.failedTipsLabel.frame = CGRectMake((kScreenWidth - width) / 2, CGRectGetMaxY(self.specialField.frame) + kBasePadding, width, 32);
                self.failedTipsLabel.hidden = NO;
            }
        } else if (_type == PasscodeTypeCancle) {
            if ([_passcode isEqualToString:self.specialField.passcode]) {
                
                [[HcdAppManager sharedInstance] setNeedPasscode:NO];
                [self dismissViewControllerAnimated:YES completion:nil];
            } else {
                self.specialField.passcode = @"";
                _failedTimes++;
                NSString *failedTips = [NSString stringWithFormat:HcdLocalized(@"n-times-failed-passcode", nil), _failedTimes];
                CGFloat width = [failedTips widthWithConstainedWidth:kScreenWidth font:self.failedTipsLabel.font] + 18;
                self.failedTipsLabel.text = failedTips;
                self.failedTipsLabel.frame = CGRectMake((kScreenWidth - width) / 2, CGRectGetMaxY(self.specialField.frame) + kBasePadding, width, 32);
                self.failedTipsLabel.hidden = NO;
            }
        }
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
