//
//  BaseNavgationController.m
//  HcdPlayer
//
//  Created by Salvador on 2019/1/15.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "BaseNavigationController.h"

@interface BaseNavigationController ()

@property (nonatomic, strong) UIView * navLineView;

@end

@implementation BaseNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self hideBottomBorderInView:self.navigationBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self hideBottomBorderInView:self.navigationBar];
    if (nil == _navLineView) {
        _navLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 43, kScreenWidth, 1)];
        [_navLineView setBackgroundColor:kSplitLineBgColor];
        [self.navigationBar addSubview:_navLineView];
    }
}

- (void)hideBottomBorderInView: (UIView *)view {
    if ([view isKindOfClass:[UIImageView class]] && view.frame.size.height <= 1.0) {
        [view setHidden:YES];
        [view setBackgroundColor: kMainColor];
    }
    
    for (UIView *subview in view.subviews) {
        [self hideBottomBorderInView:subview];
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
