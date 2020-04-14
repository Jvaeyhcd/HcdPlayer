//
//  DocumentViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2019/4/6.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "DocumentViewController.h"

@interface DocumentViewController ()<UIWebViewDelegate>

@property (nonatomic, strong) UIWebView *webView;

@end

@implementation DocumentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self showBarButtonItemWithImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_close"] position:LEFT];
    [self.view addSubview:self.webView];
    [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(0);
        make.top.mas_equalTo(0);
        make.right.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
    }];
    
    if (self.documentPath) {
        [self loadDocument:self.documentPath inView:self.webView];
        NSString *fileName = [self.documentPath lastPathComponent];
        self.title = fileName;
    }
}

#pragma mark - 懒加载组件

- (UIWebView *)webView {
    if (!_webView) {
        _webView = [[UIWebView alloc] initWithFrame:self.view.frame];
        _webView.delegate = self;
        _webView.backgroundColor = kMainBgColor;
        _webView.scalesPageToFit = YES;
    }
    return _webView;
}

#pragma makr - private

- (void)loadDocument:(NSString *)documentPath inView:(UIWebView *)webView {
    NSURL *url = [NSURL fileURLWithPath:documentPath];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [webView loadRequest:request];
}

- (void)leftNavBarButtonClicked {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
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
