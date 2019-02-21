//
//  MoveViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2019/1/23.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "MoveViewController.h"

@interface MoveViewController () {
    BOOL                _isRoot;
    NSMutableArray      *_folderPathList;
}

@end

@implementation MoveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initSubviews];
    [self initDatas];
    [self reloadDatas];
}

- (void)initDatas {
    _folderPathList = [[NSMutableArray alloc] init];
    _isRoot = YES;
}

- (void)initSubviews {
    [self.view setBackgroundColor:kMainBgColor];
    [self showBarButtonItemWithStr:HcdLocalized(@"cancel", nil) position:LEFT];
    [self showBarButtonItemWithImage:[UIImage imageNamed:@"hcdplayer.bundle/icon_add"] position:RIGHT];
}

- (void)reloadDatas {
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    if (_currentPath && [_currentPath isEqualToString:documentPath]) {
        self.title = @"Documents";
        _isRoot = YES;
    } else {
        _isRoot = NO;
    }
}

- (void)leftNavBarButtonClicked {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)rightNavBarButtonClicked {
    
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
