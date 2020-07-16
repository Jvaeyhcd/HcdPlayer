//
//  CDFFmpegViewController.m
//  HcdPlayer
//
//  Created by Salvador on 2020/7/10.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import "CDFFmpegViewController.h"

@interface CDFFmpegViewController ()<CDFFmpegPlayerDelegate>
{
    NSArray *_localMovies;
    NSArray *_remoteMovies;
    CDFFmpegPlayer *vc;
}

@property (nonatomic, strong) UIView * contentView;

@end

@implementation CDFFmpegViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _remoteMovies = @[
                      
                      //            @"http://eric.cast.ro/stream2.flv",
                      //            @"http://liveipad.wasu.cn/cctv2_ipad/z.m3u8",
                      @"http://www.wowza.com/_h264/BigBuckBunny_175k.mov",
                      // @"http://www.wowza.com/_h264/BigBuckBunny_115k.mov",
                      @"rtsp://184.72.239.149/vod/mp4:BigBuckBunny_115k.mov",
                      @"http://santai.tv/vod/test/test_format_1.3gp",
                      @"http://santai.tv/vod/test/test_format_1.mp4",
                      @"rtsp://wowzaec2demo.streamlock.net/vod/mp4:BigBuckBunny_115k.mov",
                      @"http://static.tripbe.com/videofiles/20121214/9533522808.f4v.mp4",
                      @"rtmp://live.hkstv.hk.lxdns.com/live/hks",
                      @"rtmp://rtmp.yayiguanjia.com/dentalshow/1231244_lld?auth_key=1532686852-0-0-d5bc9fd0b5f48950464b48d7f3b37afd",
                      //@"rtsp://184.72.239.149/vod/mp4://BigBuckBunny_175k.mov",
                      //@"http://santai.tv/vod/test/BigBuckBunny_175k.mov",
                      
                      //            @"rtmp://aragontvlivefs.fplive.net/aragontvlive-live/stream_normal_abt",
                      //            @"rtmp://ucaster.eu:1935/live/_definst_/discoverylacajatv",
                      //            @"rtmp://edge01.fms.dutchview.nl/botr/bunny.flv"
                      ];
    
    NSString *path;
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
//    path = _remoteMovies[4];
    path = self.path.length > 0 ? self.path :  _remoteMovies[6];
    
    // increase buffering for .wmv, it solves problem with delaying audio frames
    if ([path.pathExtension isEqualToString:@"wmv"])
        parameters[CDPlayerParameterMinBufferedDuration] = @(5.0);
    
    // disable deinterlacing for iPhone, because it's complex operation can cause stuttering
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        parameters[CDPlayerParameterDisableDeinterlacing] = @(YES);
    
    UIView * contentView = [UIView new];
    contentView.backgroundColor = [UIColor blackColor];
    self.contentView = contentView;
    [self.view addSubview:contentView];
    [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.offset(0);
        make.leading.trailing.offset(0);
        make.height.equalTo(contentView.mas_width).multipliedBy(9.0 / 16.0);
    }];
    
    vc = [CDFFmpegPlayer movieViewWithContentPath:path parameters:parameters];
    vc.rate = 2.0;
    [vc settingPlayer:^(CYVideoPlayerSettings *settings) {
        settings.enableSelections = YES;
        settings.setCurrentSelectionsIndex = ^NSInteger{
            return 3;//假设上次播放到了第四节
        };
        settings.nextAutoPlaySelectionsPath = ^NSString *{
            return @"http://vodplay.yayi360.com/9f76b359339f4bbc919f35e39e55eed4/efa9514952ef5e242a4dfa4ee98765fb-ld.mp4";
        };
        settings.useHWDecompressor = NO;
//        settings.enableProgressControl = NO;
    }];
    vc.delegate = self;
    vc.autoplay = YES;
    vc.generatPreviewImages = YES;
    [contentView addSubview:vc.view];
    
    [vc.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.offset(0);
        make.top.bottom.offset(0);
        make.width.equalTo(vc.view.mas_height).multipliedBy(SCREEN_HEIGHT / SCREEN_WIDTH);
    }];
    
    
     __weak __typeof(&*self)weakSelf = self;
    vc.lockscreen = ^(BOOL isLock) {
        
    };
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [vc stop];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

# pragma mark - 系统横竖屏切换调用

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    if (size.width > size.height)
    {
        [self.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(@(0));
            make.left.equalTo(@(0));
            make.right.equalTo(@(0));
        }];
    }
    else
    {
        [self.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.center.offset(0);
            make.leading.trailing.offset(0);
            make.height.equalTo(self.contentView.mas_width).multipliedBy(9.0 / 16.0);
        }];
    }
}

# pragma mark - CDFFmpegPlayerDelegate
- (void)CDFFmpegPlayer:(CDFFmpegPlayer *)player ChangeDefinition:(CYFFmpegPlayerDefinitionType)definition
{
    NSString * url = @"";
    switch (definition) {
        case CYFFmpegPlayerDefinitionLLD:
        {
            url = @"http://vodplay.yayi360.com/9f76b359339f4bbc919f35e39e55eed4/1d5b7ad50866e8e80140d658c5e59f8e-fd.mp4";
        }
            break;
        case CYFFmpegPlayerDefinitionLSD:
        {
            url = @"http://vodplay.yayi360.com/9f76b359339f4bbc919f35e39e55eed4/efa9514952ef5e242a4dfa4ee98765fb-ld.mp4";
        }
            break;
        case CYFFmpegPlayerDefinitionLHD:
        {
            url = @"http://vodplay.yayi360.com/9f76b359339f4bbc919f35e39e55eed4/04ad8e1641699cd71819fe38ec2be506-sd.mp4";
        }
            break;
        case CYFFmpegPlayerDefinitionLUD:
        {
            url = @"http://vodplay.yayi360.com/9f76b359339f4bbc919f35e39e55eed4/b43889cb2eb86103abb977d2b246cb83-hd.mp4";
        }
            break;
            
        default:
        {
            url = @"http://vodplay.yayi360.com/9f76b359339f4bbc919f35e39e55eed4/efa9514952ef5e242a4dfa4ee98765fb-ld.mp4";
        }
            break;
    }
//    NSString * localV = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp4"];
    [vc changeDefinitionPath:url];
}

- (void)CDFFmpegPlayer:(CDFFmpegPlayer *)player SetSelectionsNumber:(CYPlayerSelectionsHandler)setNumHandler
{
    setNumHandler(20);
}

- (void)CDFFmpegPlayer:(CDFFmpegPlayer *)player changeSelections:(NSInteger)selectionsNum
{
    NSString * url = @"";
        switch (selectionsNum) {
            case 0:
            {
                url = @"http://vodplay.yayi360.com/9f76b359339f4bbc919f35e39e55eed4/1d5b7ad50866e8e80140d658c5e59f8e-fd.mp4";
            }
                break;
            case 1:
            {
                url = @"http://vodplay.yayi360.com/9f76b359339f4bbc919f35e39e55eed4/efa9514952ef5e242a4dfa4ee98765fb-ld.mp4";
            }
                break;
            case 2:
            {
                url = @"http://vodplay.yayi360.com/9f76b359339f4bbc919f35e39e55eed4/04ad8e1641699cd71819fe38ec2be506-sd.mp4";
            }
                break;
            case 3:
            {
                url = @"http://vodplay.yayi360.com/9f76b359339f4bbc919f35e39e55eed4/b43889cb2eb86103abb977d2b246cb83-hd.mp4";
            }
                break;
                
            default:
            {
                url = @"http://vodplay.yayi360.com/9f76b359339f4bbc919f35e39e55eed4/efa9514952ef5e242a4dfa4ee98765fb-ld.mp4";
            }
                break;
        }
    //    NSString * localV = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp4"];
    [vc settingPlayer:^(CYVideoPlayerSettings *settings) {
        settings.setCurrentSelectionsIndex = ^NSInteger{
            return selectionsNum;
        };
    }];
        [vc changeSelectionsPath:url];
}


@end
