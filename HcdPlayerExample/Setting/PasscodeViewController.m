//
//  PasscodeViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2019/3/23.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "PasscodeViewController.h"
#import "HcdSpecialField-Swift.h"
#import "HcdDeviceManager.h"

@interface PasscodeViewController ()

@property (nonatomic, strong) HcdSpecialField *specialField;
@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, copy) NSString *passcode;

@end

@implementation PasscodeViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _passcode = [HcdDeviceManager sharedInstance].passcode;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = HcdLocalized(@"enter-passcode", nil);
    [self.view addSubview:self.specialField];
    [self.view addSubview:self.tipsLabel];
    
    [self.specialField addTarget:self action:@selector(specialFieldDidChangeValue) forControlEvents:UIControlEventValueChanged];
    [self.specialField becomeFirstResponder];
    
    self.view.backgroundColor = [UIColor whiteColor];
    if (_type == PasscodeTypeSet) {
        self.tipsLabel.text = HcdLocalized(@"set-passcode-tip", nil);
    } else if (_type == PasscodeTypeCancle || _type == PasscodeTypeUnLock) {
        self.tipsLabel.text = HcdLocalized(@"enter-passcode-tip", nil);
    }
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
    }
    return _tipsLabel;
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
                [[HcdDeviceManager sharedInstance] setPasscode:_passcode];
                [self dismissViewControllerAnimated:YES completion:^{
                    
                }];
            } else {
                self.specialField.passcode = @"";
            }
        } else if (_type == PasscodeTypeUnLock) {
            
        } else if (_type == PasscodeTypeCancle) {
            
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
