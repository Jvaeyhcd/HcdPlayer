//
//  UIViewController+Hcd.m
//  HcdPlayer
//
//  Created by Salvador on 2019/1/21.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "UIViewController+Hcd.h"

#import "NSString+Hcd.h"

@implementation UIViewController (Hcd)

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self.navigationController pushViewController:viewController animated:animated];
}

- (void)popViewController:(BOOL)animated {
    [self.navigationController popViewControllerAnimated:animated];
}

- (void)showBarButtonItemWithStr:(NSString *)str position:(NSInteger)position {
    CGFloat width = [str widthWithConstainedWidth:kScreenWidth / 2 font: kBarButtonItemTitleFont];
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, width, 30)];
    btn.titleLabel.font = kBaseFont;
    [btn setTitle:str forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor colorWithRGBHex:0xFFFFFF] forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor colorWithRGBHex:0xBDBDBD] forState:UIControlStateDisabled];
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:btn];
    
    if (LEFT == position) {
        self.navigationItem.leftBarButtonItem = item;
        [btn addTarget:self action:@selector(leftNavBarButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    } else if (RIGHT == position) {
        self.navigationItem.rightBarButtonItem = item;
        [btn addTarget:self action:@selector(rightNavBarButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)showBarButtonItemWithImage:(UIImage *)image position:(NSInteger)position {
    if (LEFT == position) {
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(leftNavBarButtonClicked)];
        item.tintColor = [UIColor whiteColor];
        self.navigationItem.leftBarButtonItem = item;
    } else if (RIGHT == position) {
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(rightNavBarButtonClicked)];
        item.tintColor = [UIColor whiteColor];
        self.navigationItem.rightBarButtonItem = item;
    }
}

- (void)leftNavBarButtonClicked {
    
}

- (void)rightNavBarButtonClicked {
    
}

- (void)setNavigationBarBackgroundColor:(UIColor *)color
                             titleColor:(UIColor *)titleColor {
    // Do any additional setup after loading the view.
    [UINavigationBar appearance].tintColor = color;
    [UINavigationBar appearance].barTintColor = color;
    [UINavigationBar appearance].backgroundColor = color;
    [UINavigationBar appearance].titleTextAttributes = @{NSForegroundColorAttributeName: titleColor};
    
    // iOS15 相关新特性的设置适配
    if (@available(iOS 15.0, *)) {
        [UITableView appearance].sectionHeaderTopPadding = 0;
        UINavigationBarAppearance *barApp = [UINavigationBarAppearance new];
        barApp.titleTextAttributes = @{NSForegroundColorAttributeName: titleColor};
        barApp.backgroundColor = color;
        self.navigationController.navigationBar.scrollEdgeAppearance = barApp;
        self.navigationController.navigationBar.standardAppearance = barApp;
    }
}

@end
