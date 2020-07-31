//
//  CDFFmpegViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2020/7/10.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import "CDFFmpegViewController.h"
#import "HcdAppManager.h"

@interface CDFFmpegViewController ()<CDFFmpegPlayerDelegate>
{
    NSArray *_localMovies;
    NSArray *_remoteMovies;
}

@property (nonatomic) BOOL landscape;
@property (nonatomic) BOOL locked;
@property (nonatomic) CGFloat statusBarHeight;
@property (nonatomic, strong) CDFFmpegPlayer *player;

@property (nonatomic, strong) UIView * contentView;

@end

@implementation CDFFmpegViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.statusBarHeight = STATUS_BAR_HEIGHT;
    _remoteMovies = @[];
    
    UIView * contentView = [UIView new];
    contentView.backgroundColor = [UIColor blackColor];
    self.contentView = contentView;
    [self.view addSubview:contentView];
    [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.bottom.mas_equalTo(0);
    }];
    
    
    [contentView addSubview:self.player.view];
    
    [self.player.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(0);
        make.top.mas_equalTo(self.statusBarHeight);
        make.height.mas_equalTo(self.view.width * 9 / 16);
    }];

}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 不自动锁屏
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    [HcdAppManager sharedInstance].isAllowAutorotate = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO];
    
    // 恢复自动锁屏
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [HcdAppManager sharedInstance].isAllowAutorotate = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [self.player stop];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

#pragma mark - 状态栏颜色
- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

# pragma mark - 系统横竖屏切换调用

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    BOOL isLandscape = size.width > size.height;

    if (isLandscape) {
        [self.player.view mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.top.right.bottom.mas_equalTo(0);
        }];
    } else {
        [self.player.view mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.mas_equalTo(0);
            make.top.mas_equalTo(self.statusBarHeight);
            make.height.mas_equalTo(size.width * 9 / 16);
        }];
    }
}

#pragma mark - getter

- (CDFFmpegPlayer *)player {
    if (!_player) {
        NSString *path;
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        
        path = self.path.length > 0 ? self.path :  _remoteMovies[6];
        
        // increase buffering for .wmv, it solves problem with delaying audio frames
        if ([path.pathExtension isEqualToString:@"wmv"])
            parameters[CDPlayerParameterMinBufferedDuration] = @(5.0);
        
        // disable deinterlacing for iPhone, because it's complex operation can cause stuttering
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
            parameters[CDPlayerParameterDisableDeinterlacing] = @(YES);
    
        _player = [CDFFmpegPlayer movieViewWithContentPath:path parameters:parameters];
        _player.rate = 2.0;
        _player.delegate = self;
        _player.autoplay = YES;
        _player.generatPreviewImages = YES;
    }
    return _player;
}

# pragma mark - CDFFmpegPlayerDelegate
- (void)cdFFmpegPlayer:(CDFFmpegPlayer *)player changeDefinition:(CYFFmpegPlayerDefinitionType)definition {
    
}

- (void)cdFFmpegPlayer:(CDFFmpegPlayer *)player setSelectionsNumber:(CYPlayerSelectionsHandler)setNumHandler {
    
}

- (void)cdFFmpegPlayer:(CDFFmpegPlayer *)player changeSelections:(NSInteger)selectionsNum {
    
    
}


@end
