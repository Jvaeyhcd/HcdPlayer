//
//  BaseViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2019/3/5.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "BaseViewController.h"
#import "HcdAppManager.h"

@interface BaseViewController ()

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setNavigationBarBackgroundColor:kNavBgColor titleColor:kNavTitleColor];
}

/**
 * 强制转屏
 * @param orientation 屏幕旋转的方向
 */
- (void)setInterfaceOrientation:(UIInterfaceOrientation)orientation {
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        
        [HcdAppManager sharedInstance].supportedInterfaceOrientationsForWindow = orientation;
        
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        // 从2开始是因为前两个参数已经被selector和target占用
        [invocation setArgument:&orientation atIndex:2];
        [invocation invoke];
    }
}

@end
