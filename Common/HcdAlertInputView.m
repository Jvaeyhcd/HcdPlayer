//
//  HcdAlertInputView.m
//  HcdPlayer
//
//  Created by Salvador on 2019/1/24.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "HcdAlertInputView.h"
#import "NSString+Hcd.h"
#import "UIView+Hcd.h"
#import "UIColor+Hcd.h"

#define kScreen_Height [UIScreen mainScreen].bounds.size.height
#define kScreen_Width [UIScreen mainScreen].bounds.size.width
#define kScaleFrom_iPhone5_Desgin(_X_) (_X_ * (kScreen_Width/320))

#define kContenViewHeight kScaleFrom_iPhone5_Desgin(110)

@interface HcdAlertInputView()<UITextViewDelegate>

@property (nonatomic, strong) UIView *dialogView, *mainView;
@property (nonatomic, strong) UIButton *commitBtn;
@property (nonatomic, strong) UITextField* textField;
@property (nonatomic, strong) UILabel *tipsLbl;

@end

@implementation HcdAlertInputView

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.userInteractionEnabled = YES;
        [self initUI];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        [self initUI];
    }
    return self;
}

- (void)initUI {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    if (!_mainView) {
        _mainView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        _mainView.userInteractionEnabled = YES;
        UIView *maskView;
        
        // 毛玻璃效果
        //        double version = [[UIDevice currentDevice].systemVersion doubleValue];
        //        if (version >= 8.0f) {
        //
        //            UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        //            maskView = [[UIVisualEffectView alloc] initWithEffect:blur];
        //            ((UIVisualEffectView *)maskView).frame = _mainView.bounds;
        //
        //        } else if(version >= 7.0f){
        //
        //            maskView = [[UIToolbar alloc] initWithFrame:_mainView.bounds];
        //            ((UIToolbar *)maskView).barStyle = UIBarStyleDefault;
        //
        //        }
        
        // 般透明效果
        maskView = [[UIView alloc]initWithFrame:_mainView.bounds];
        maskView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideReplayView)];
        
        [maskView addGestureRecognizer:singleTap];
        
        [_mainView addSubview:maskView];
        
        [self addSubview:_mainView];
    }
    
    if (!_dialogView) {
        _dialogView = [[UIView alloc]initWithFrame:CGRectMake(0, self.frame.size.height, kScreen_Width, kContenViewHeight)];
        _dialogView.userInteractionEnabled = YES;
        _dialogView.backgroundColor = [UIColor colorWithRed:1.000 green:1.000 blue:1.000 alpha:1.00];
        [_dialogView setCornerOnTop:8.0];
        [_mainView addSubview:_dialogView];
    }
    
    if (!_textField) {
        _textField = [[UITextField alloc]initWithFrame:CGRectMake(kBasePadding, (kContenViewHeight - 90) / 2 + 50, kScreen_Width - 3 * kBasePadding - 50, 40)];
        _textField.backgroundColor = [UIColor colorWithRed:0.957 green:0.961 blue:0.965 alpha:1.00];
        _textField.clipsToBounds = YES;
        _textField.layer.borderColor = [UIColor colorWithRed:0.957 green:0.961 blue:0.965 alpha:1.00].CGColor;
        _textField.layer.borderWidth = 1;
        _textField.layer.cornerRadius = 4;
        _textField.font = [UIFont systemFontOfSize:14];
        _textField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 0)];
        _textField.leftViewMode = UITextFieldViewModeAlways;
        _textField.textColor = [UIColor blackColor];
        _textField.clearsOnBeginEditing = YES;
        [_textField addTarget:self action:@selector(textFieldEditingChanged:) forControlEvents:UIControlEventEditingChanged];
        [_dialogView addSubview:_textField];
    }
    
    UIView *splitLine = [[UIView alloc] initWithFrame:CGRectMake(0, 50, kScreen_Width, 0.5)];
    splitLine.backgroundColor = [UIColor colorWithRed:0.937 green:0.937 blue:0.937 alpha:1.00];
    [_dialogView addSubview:splitLine];
    
    if (!_tipsLbl) {
        _tipsLbl = [[UILabel alloc]initWithFrame:CGRectMake(70, 0, kScreen_Width - 140, 50)];
        _tipsLbl.font = [UIFont boldSystemFontOfSize:16];
        _tipsLbl.textAlignment = NSTextAlignmentCenter;
        _tipsLbl.textColor = [UIColor color333];
        [_dialogView addSubview:_tipsLbl];
    }
    
    UIButton *cancleBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 70, 50)];
    [cancleBtn setTitle:HcdLocalized(@"cancel", nil) forState:UIControlStateNormal];
    [cancleBtn setTitleColor:[UIColor color999] forState:UIControlStateNormal];
    cancleBtn.titleLabel.font = kBaseFont;
    cancleBtn.backgroundColor = [UIColor whiteColor];
    [cancleBtn addTarget:self action:@selector(hideReplayView) forControlEvents:UIControlEventTouchUpInside];
    [_dialogView addSubview:cancleBtn];
    
    if (!_commitBtn) {
        _commitBtn = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(_textField.frame) + kBasePadding, CGRectGetMinY(_textField.frame), 50, 40)];
        _commitBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [_commitBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _commitBtn.layer.cornerRadius = 4;
        _commitBtn.clipsToBounds = YES;
        [_commitBtn addTarget:self action:@selector(confrimClick) forControlEvents:UIControlEventTouchUpInside];
        [_commitBtn setImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_done"] forState:UIControlStateNormal];
        _commitBtn.backgroundColor = [UIColor colorWithRed:0.792 green:0.792 blue:0.792 alpha:1.00];
        [_dialogView addSubview:_commitBtn];
    }
    
}

- (void)setPlaceHolder:(NSString *)placeHolder {
    _placeHolder = placeHolder;
    _textField.placeholder = _placeHolder;
}

- (void)setTips:(NSString *)tips {
    _tipsLbl.text = tips;
}

- (void)showReplyInView:(UIView *)view {
    [view addSubview:self];
    self.commitBtn.enabled = YES;
    [self.textField becomeFirstResponder];
}

- (void)hideReplayView {
    
    [self removeFromSuperview];
    [self.textField resignFirstResponder];
    self.dialogView.frame = CGRectMake(0, kScreen_Height, kScreen_Width, kContenViewHeight);
}

- (void)confrimClick {
    
    // 去掉头尾的空格、换行和Tab
    NSString *content = [self.textField.text removeBothSideSpaceAndNewline];
    // 将换行替换成空格
    content = [content stringByReplacingOccurrencesOfString: @"\n" withString: @" "];
    // 将中间连续十个以上的空格替换成十个
    content = [content replaceMoreThan10SpaceTo10Space];
    
    if (content.length > 0) {
        if (self.commitBlock) {
            self.commitBlock(content);
        }
        [self hideReplayView];
    } else {
        
    }
}

- (void)textFieldEditingChanged :(UITextField *)textField{
    if (textField.text.isBlankString) {
        textField.text = @"";
    }
    if (textField.text && textField.text.length > 0) {
        [self.commitBtn setBackgroundColor:kMainColor];
    } else {
        [self.commitBtn setBackgroundColor:[UIColor colorWithRed:0.792 green:0.792 blue:0.792 alpha:1.00]];
    }
}

#pragma mark TextView Delegate
- (void)textViewDidChange:(UITextView *)textView{
    
    if (textView.text.isBlankString) {
        textView.text = @"";
    }
    
    if (textView.text && textView.text.length > 0) {
        
        if (textView.text.length > 150) {
            textView.text = [textView.text substringToIndex:150];
        }
        
        self.tipsLbl.text = [NSString stringWithFormat:@"您已输入%lu字", (unsigned long)textView.text.length];
        [self.commitBtn setBackgroundColor:[UIColor colorWithRed:0.145 green:0.557 blue:0.831 alpha:1.00]];
    } else {
        self.tipsLbl.text = @"请输入1~150个文字";
        [self.commitBtn setBackgroundColor:[UIColor colorWithRed:0.792 green:0.792 blue:0.792 alpha:1.00]];
    }
}

- (void)removeKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification{
    
    CGRect keyboardBounds;
    [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardBounds];
    
    int  keyBoardHeight=keyboardBounds.size.height;
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:[duration doubleValue]];
    [UIView setAnimationCurve:[curve intValue]];
    
    _dialogView.center = CGPointMake(kScreen_Width / 2, kScreen_Height - keyBoardHeight - kContenViewHeight / 2);
    
    [UIView commitAnimations];
}

-(void)dealloc{
    
    [self removeKeyboardNotifications];
}

@end
