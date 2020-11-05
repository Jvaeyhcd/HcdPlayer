//
//  CDFFmpegPlayer.m
//  CYPlayer
//
//  Created by 黄威 on 2018/7/19.
//  Copyright © 2018年 Sutan. All rights reserved.
//

#import "CDFFmpegPlayer.h"
#import "CYPlayerDecoder.h"
#import "CYAudioManager.h"
#import "CYLogger.h"
#import "CYPlayerGLView.h"
#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>
#import <Masonry/Masonry.h>

//Views
#import "CYLoadingView.h"
#import "CYVideoPlayerPresentView.h"
#import "CYVideoPlayerBaseView.h"

//Models
#import "CDPlayerGestureControl.h"
#import "CYTimerControl.h"
#import "CYVideoPlayerRegistrar.h"
#import "CYVideoPlayerSettings.h"
#import "CYVideoPlayerResources.h"
#import "CYPrompt.h"
#import "CYVideoPlayerMoreSetting.h"
#import "CYPCMAudioManager.h"

//Others
#import <objc/message.h>
#import <sys/sysctl.h>
#import <mach/mach.h>


//#define USE_OPENAL @"UseCYPCMAudioManager"

#define USE_AUDIOTOOL @"UseCYAudioManager"

#define CYPLAYER_MAX_TIMEOUT 120.0 //秒

#define MoreSettingWidth (MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) * 0.382)

#define CYColorWithHEX(hex) [UIColor colorWithRed:(float)((hex & 0xFF0000) >> 16)/255.0 green:(float)((hex & 0xFF00) >> 8)/255.0 blue:(float)(hex & 0xFF)/255.0 alpha:1.0]

inline static void _cdErrorLog(id msg) {
    NSLog(@"__error__: %@", msg);
}

inline static void _cdHiddenViews(NSArray<UIView *> *views) {
    [views enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.alpha = 0.0;
        obj.hidden = YES;
    }];
}

inline static void _cdShowViews(NSArray<UIView *> *views) {
    [views enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.alpha = 1.0;
        obj.hidden = NO;
    }];
}

inline static void _cdAnima(void(^block)(void)) {
    if ( block ) {
        [UIView animateWithDuration:0.3 animations:^{
            block();
        }];
    }
}

inline static NSString *_formatWithSec(NSInteger sec) {
    NSInteger seconds = sec % 60;
    NSInteger minutes = sec / 60;
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
}


NSString * const CDPlayerParameterMinBufferedDuration = @"CDPlayerParameterMinBufferedDuration";
NSString * const CDPlayerParameterMaxBufferedDuration = @"CDPlayerParameterMaxBufferedDuration";
NSString * const CDPlayerParameterDisableDeinterlacing = @"CDPlayerParameterDisableDeinterlacing";

static NSMutableDictionary * gHistory = nil;//播放记录


#define LOCAL_MIN_BUFFERED_DURATION   0.2
#define LOCAL_MAX_BUFFERED_DURATION   0.4
#define NETWORK_MIN_BUFFERED_DURATION 2.0
#define NETWORK_MAX_BUFFERED_DURATION 8.0
#define MAX_BUFFERED_DURATION_MEMORY_USED_PERCENT 100//100 相当于关闭
#define HAS_PLENTY_OF_MEMORY [self getAvailableMemorySize] >= 0//0相当于关闭

@interface CDFFmpegPlayer ()<CYPCMAudioManagerDelegate,  CYAudioManagerDelegate>
{
    CGFloat             _moviePosition;//视频播放到的位置
    CGFloat             _audioPosition;//音频播放到的位置
    NSDictionary        *_parameters;
    NSString            *_path;
    BOOL                _interrupted;
    BOOL                _buffered;
    BOOL                _savedIdleTimer;
    BOOL                _isDraging;
    
    dispatch_queue_t    _asyncDecodeQueue;
    dispatch_queue_t    _videoQueue;
    dispatch_queue_t    _audioQueue;
    dispatch_queue_t    _progressQueue;
    NSMutableArray      *_videoFrames;
    NSMutableArray      *_audioFrames;
    NSMutableArray      *_subtitles;
    CGFloat             _minBufferedDuration;
    CGFloat             _maxBufferedDuration;
    NSData              *_currentAudioFrame;
    CGFloat             _videoBufferedDuration;
    CGFloat             _audioBufferedDuration;
    NSUInteger          _currentAudioFramePos;
    BOOL                _disableUpdateHUD;
    NSTimeInterval      _tickCorrectionTime;
    NSTimeInterval      _tickCorrectionPosition;
    NSUInteger          _tickCounter;
    
    //生成预览图
    CYPlayerDecoder      *_generatedPreviewImagesDecoder;
    dispatch_queue_t    _generatedPreviewImagesDispatchQueue;
    NSMutableArray      *_generatedPreviewImagesVideoFrames;
    BOOL                _generatedPreviewImageInterrupted;
    
    //UI
//    CYPlayerGLView       *_glView;
    UIImageView         *_imageView;
    
    //Gesture
    BOOL                _positionUpdating;
    CGFloat             _targetPosition;
    
    //缓冲到内存的进度
    CGFloat             _videoRAMBufferPostion;
    CGFloat             _audioRAMBufferPostion;
    
    //判断失败的时间
    CFAbsoluteTime      _cantPlayStartTime;
#ifdef DEBUG
    UILabel             *_messageLabel;
    NSTimeInterval      _debugStartTime;
    NSUInteger          _debugAudioStatus;
    NSDate              *_debugAudioStatusTS;
#endif
    
    //当前清晰度
    CYFFmpegPlayerDefinitionType _definitionType;
    BOOL _isChangingDefinition;
    NSInteger _currentSelections;
    BOOL _isChangingSelections;
    
}

@property (readwrite) BOOL playing;
@property (readwrite) BOOL decoding;

@property (readwrite, strong) CYArtworkFrame *artworkFrame;

@property (nonatomic, strong, readonly) dispatch_queue_t workQueue;

@property (nonatomic, assign, readwrite) CDFFmpegPlayerPlayState state;

@property (nonatomic, assign, readwrite) BOOL hiddenLeftControlView;
@property (nonatomic, assign, readwrite) BOOL hasBeenGeneratedPreviewImages;
@property (nonatomic, assign, readwrite) BOOL userClickedPause;
@property (nonatomic, assign, readwrite) BOOL stopped;
@property (nonatomic, assign, readwrite) BOOL touchedScrollView;
@property (nonatomic, assign, readwrite) BOOL suspend; // Set it when the [`pause` + `play` + `stop`] is called.
@property (nonatomic, assign, readwrite) BOOL enableAudio;
@property (nonatomic, strong, readwrite) NSError *error;

@end

@implementation CDFFmpegPlayer
{
    CYVideoPlayerPresentView *_presentView;
    CYLoadingView *_loadingView;
    CDPlayerGestureControl *_gestureControl;
    CYVideoPlayerBaseView *_view;
    dispatch_queue_t _workQueue;
    CYVideoPlayerRegistrar *_registrar;
}

+ (instancetype)sharedPlayer {
    static id _instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

+ (void)initialize
{
    if (!gHistory)
    {
        gHistory = [[NSMutableDictionary alloc] initWithCapacity:20];
        
        NSLog(@"%@", gHistory);
    }
}

- (instancetype)init {
    if (self = [super init]) {
        [self resetSetting];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsPlayerNotification:) name:CYSettingsPlayerNotification object:nil];
    }
    return self;
}

+ (id)movieViewWithContentPath:(NSString *)path
                    parameters:(NSDictionary *)parameters {
    return [[self alloc] initWithContentPath: path parameters: parameters];;
}

- (id)initWithContentPath:(NSString *)path
               parameters:(NSDictionary *)parameters {
    NSAssert(path.length > 0, @"empty path");
    
    self = [super init];
    if (self) {
        [self resetSetting];
        [self setupPlayerWithPath:path parameters:parameters];
        self.rate = 1.0;
    }
    return self;
}

- (void)setupPlayerWithPath:(NSString *)path parameters:(NSDictionary *)parameters {
    
    id<CYAudioManager> audioManager = [CYAudioManager audioManager];
    BOOL canUseAudio = [audioManager activateAudioSession];
    //    BOOL canUseAudio = YES;
    
    [self view];
    //__weak typeof(self) _self = self;
    [self settingPlayer:^(CYVideoPlayerSettings * _Nonnull settings) {

    }];
    [self registrar];
    
    [self _unknownState];
    
    [self _itemPrepareToPlay];
    
    if (!_progressQueue) {
        //        _progressQueue = dispatch_queue_create("CYPlayer Progress", DISPATCH_QUEUE_SERIAL);
        _progressQueue  = dispatch_get_main_queue();
    }
    
    if (!_videoQueue) {
        //        _videoQueue = dispatch_queue_create("CYPlayer Video", DISPATCH_QUEUE_SERIAL);
        _videoQueue  = dispatch_get_main_queue();
    }
    
    if (!_audioQueue) {
        _audioQueue = dispatch_queue_create("CYPlayer Audio", DISPATCH_QUEUE_SERIAL);
        //        _audioQueue  = dispatch_get_main_queue();
    }
    
    _moviePosition = 0;
    //        self.wantsFullScreenLayout = YES;
    
    _parameters = parameters;
    _path = path;
    
    __block CYPlayerDecoder *decoder = [[CYPlayerDecoder alloc] init];
    CYVideoDecodeType type = CYVideoDecodeTypeVideo;
    if (canUseAudio) {
        type |= CYVideoDecodeTypeAudio;
    } else {
        LoggerAudio(0, @"Can not open Audio Session");
    }
    [decoder setDecodeType:type];
    
    __weak __typeof(self) weakSelf = self;
    
    decoder.interruptCallback = ^BOOL() {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        return strongSelf ? [strongSelf interruptDecoder] : YES;
    };
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        
        NSError *error = nil;
        [decoder openFile:path error:&error];
        [decoder setupVideoFrameFormat:CYVideoFrameFormatYUV];
        [decoder setUseHWDecompressor:strongSelf.settings.useHWDecompressor];
        if (strongSelf) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                __strong __typeof(weakSelf) strongSelf2 = weakSelf;
                if (strongSelf2 && !strongSelf.stopped) {
                    [strongSelf2 setMovieDecoder:decoder withError:error];
                }
                else if (error) {
                    [weakSelf _itemPlayFailed];
                }
            });
        }
    });
}

- (void)changeSelectionsPath:(NSString *)path {
    
    _path = path;
    
    __block CYPlayerDecoder *decoder = [[CYPlayerDecoder alloc] init];
    CYVideoDecodeType type = _decoder.decodeType;
    [decoder setDecodeType:type];
    __weak __typeof(self) weakSelf = self;
    
    decoder.interruptCallback = ^BOOL(){
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        return strongSelf ? [strongSelf interruptDecoder] : YES;
    };
    [self pause];
    self.autoplay = YES;
    self.suspend = NO;//手动暂停会挂起,这里要取消挂起才会自动播放
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        
        NSError *error = nil;
        [decoder openFile:path error:&error];
        [decoder setupVideoFrameFormat:CYVideoFrameFormatYUV];
        
        if (strongSelf) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                __strong __typeof(weakSelf) strongSelf2 = weakSelf;
                if (strongSelf2 && !strongSelf.stopped) {
                    [decoder setPosition:0];
                    strongSelf2->_moviePosition = 0;
                    //关闭原先的解码器
//                    [strongSelf.decoder closeFile];
                    //清除旧的缓存
                    [strongSelf2 freeBufferedFrames];
                    //播放器连接新的解码器decoder
                    [strongSelf2 setMovieDecoder:decoder withError:error];
                    
//                    [strongSelf2 showTitle:@"切换完成"];
                    strongSelf2->_isChangingSelections = NO;
                }
                else if (error) {
                    [weakSelf _itemPlayFailed];
                    strongSelf2->_isChangingSelections = NO;
                }
            });
        }
    });
}

- (void)changeDefinitionPath:(NSString *)path {
    _path = path;
    
    __block CYPlayerDecoder *decoder = [[CYPlayerDecoder alloc] init];
    CYVideoDecodeType type = _decoder.decodeType;
    [decoder setDecodeType:type];
    __weak __typeof(self) weakSelf = self;
    
    decoder.interruptCallback = ^BOOL(){
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        return strongSelf ? [strongSelf interruptDecoder] : YES;
    };
    self.autoplay = YES;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        
        NSError *error = nil;
        [decoder openFile:path error:&error];
        [decoder setupVideoFrameFormat:CYVideoFrameFormatYUV];
        
        if (strongSelf) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                __strong __typeof(weakSelf) strongSelf2 = weakSelf;
                if (strongSelf2 && !strongSelf.stopped) {
                    [decoder setPosition:strongSelf.decoder.position];
                    //关闭原先的解码器
//                    [strongSelf.decoder closeFile];
//                    strongSelf2.controlView.decoder = decoder;
                    //播放器连接新的解码器decoder
                    [strongSelf2 setMovieDecoder:decoder withError:error];
                    
                    [strongSelf2 showTitle:@"切换完成"];
                    strongSelf2->_isChangingDefinition = NO;
                }
                else if (error) {
                    [weakSelf _itemPlayFailed];
                    strongSelf2->_isChangingDefinition = NO;
                }
            });
        }
    });
}

- (void)changeLiveDefinitionPath:(NSString *)path {
    _path = path;
    
    __block CYPlayerDecoder *decoder = [[CYPlayerDecoder alloc] init];
    CYVideoDecodeType type = _decoder.decodeType;
    [decoder setDecodeType:type];
    __weak __typeof(self) weakSelf = self;
    
    decoder.interruptCallback = ^BOOL(){
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        return strongSelf ? [strongSelf interruptDecoder] : YES;
    };
    self.autoplay = YES;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        
        NSError *error = nil;
        [decoder openFile:path error:&error];
        [decoder setupVideoFrameFormat:CYVideoFrameFormatYUV];
        
        if (strongSelf) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                __strong __typeof(weakSelf) strongSelf2 = weakSelf;
                if (strongSelf2 && !strongSelf.stopped) {
                    //关闭原先的解码器
//                    [strongSelf.decoder closeFile];
                    //播放器连接新的解码器decoder
                    [strongSelf2 setMovieDecoder:decoder withError:error];
                    
                    [strongSelf2 showTitle:@"切换完成"];
                    strongSelf2->_isChangingDefinition = NO;
                }
                else if (error) {
                    [weakSelf _itemPlayFailed];
                    strongSelf2->_isChangingDefinition = NO;
                }
            });
        }
    });
}

- (void)refreshSelectionsBtnStatus {
    
}

- (void)refreshDefinitionBtnStatus {
    
}


- (void)dealloc {
    
    [self enableAudioTick:NO];
    
    while ((_decoder.validVideo ? _videoFrames.count : 0) + (_decoder.validAudio ? _audioFrames.count : 0) > 0) {
        
        @synchronized(_videoFrames) {
            if (_videoFrames.count > 0)
            {
                [_videoFrames removeObjectAtIndex:0];
            }
        }
        
//        const CGFloat duration = _decoder.isNetwork ? .0f : 0.1f;
//        [_decoder decodeFrames:duration];
        @synchronized(_audioFrames) {
            if (_audioFrames.count > 0)
            {
                [_audioFrames removeObjectAtIndex:0];
            }
        }
        LoggerStream(1, @"%@ waiting dealloc", self);
    }
    
    self.playing = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (_asyncDecodeQueue) {
        // Not needed as of ARC.
        //        dispatch_release(_asyncDecodeQueue);
        _asyncDecodeQueue = NULL;
    }
    
    if (_progressQueue) {
        // Not needed as of ARC.
        //        dispatch_release(_asyncDecodeQueue);
        _progressQueue = NULL;
    }
    
    if (_videoQueue) {
        // Not needed as of ARC.
        //        dispatch_release(_asyncDecodeQueue);
        _videoQueue = NULL;
    }
    
    if (_audioQueue) {
        // Not needed as of ARC.
        //        dispatch_release(_asyncDecodeQueue);
        _audioQueue = NULL;
    }
    
    LoggerStream(1, @"%@ dealloc", self);
}

- (void)loadView {
    
    if (_decoder) {
        [self setupPresentView];
    }
}

- (void)didReceiveMemoryWarning {
    if (self.playing) {
        
        [self pause];
        [self freeBufferedFrames];
        
        if (_maxBufferedDuration > 0) {
            
            _minBufferedDuration = _maxBufferedDuration = 0;
            [self play];
            
            LoggerStream(0, @"didReceiveMemoryWarning, disable buffering and continue playing");
            
        } else {
            
            // force ffmpeg to free allocated memory
            [_decoder closeFile];
            [_decoder openFile:nil error:nil];
            
        }
        
    } else {
        
        [self freeBufferedFrames];
        [_decoder closeFile];
        [_decoder openFile:nil error:nil];
    }
}


# pragma mark - UI处理
- (UIView *)view {
    if ( _view ) {
        [_presentView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(_presentView.superview);
        }];
        return _view;
    }
    _view = [CYVideoPlayerBaseView new];
    _view.backgroundColor = [UIColor blackColor];
    [_view addSubview:self.presentView];
    
    [self gesturesHandleWithTargetView:_view];
    
    [_presentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_presentView.superview);
    }];
    
    _loadingView = [CYLoadingView new];
    [_view addSubview:_loadingView];
    [_loadingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.offset(0);
    }];
    
    return _view;
}

# pragma mark - 公开方法
- (double)currentTime {
    return self.decoder.validVideo ? _moviePosition : _audioPosition;
}

- (NSTimeInterval)totalTime {
    return self.decoder.duration;
}

- (void)viewDidAppear
{
    if (_decoder) {
        
        [self restorePlay];
        
    } else {
        
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:[UIApplication sharedApplication]];
}

- (void)viewWillDisappear {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (_decoder) {
        
        [self stop];
        
        NSMutableDictionary * gHis = [self getHistory];
        if (_moviePosition == 0 || _decoder.isEOF)
            [gHis removeObjectForKey:_decoder.path];
        else if (!_decoder.isNetwork)
            [gHis setValue:[NSNumber numberWithFloat:_moviePosition]
                    forKey:_decoder.path];
    }
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:_savedIdleTimer];
    
    _buffered = NO;
    _positionUpdating = NO;
    _interrupted = YES;
    
    LoggerStream(1, @"viewWillDisappear %@", self);
}

- (void)_startLoading {
    if ( _loadingView.isAnimating ) return;
    [_loadingView start];
}

- (void)_stopLoading {
    if ( !_loadingView.isAnimating ) return;
    [_loadingView stop];
}

- (void)_buffering {
    if (self.userClickedPause ||
        self.state == CDFFmpegPlayerPlayState_PlayFailed ||
        self.state == CDFFmpegPlayerPlayState_PlayEnd ||
        self.state == CDFFmpegPlayerPlayState_Unknown ) return;
    
    [self _startLoading];
    self.state = CDFFmpegPlayerPlayState_Buffing;
}

-(void)_play {
    
    [self _stopLoading];
    
    if (self.playing)
        return;
    
    if (!_decoder.validVideo &&
        !_decoder.validAudio) {
        
        return;
    }
    
    if (_interrupted)
        return;
    
    self.playing = YES;
    _interrupted = NO;
    _disableUpdateHUD = NO;
    _tickCorrectionTime = 0;
    _tickCounter = 0;
    
#ifdef DEBUG
    _debugStartTime = -1;
#endif
    

    //    [self asyncDecodeFrames];
    [self concurrentAsyncDecodeFrames];
    
    __weak typeof(self) weakSelf = self;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
    dispatch_after(popTime, _progressQueue, ^(void){
        
        [weakSelf progressTick];
        
        if (weakSelf.decoder.validAudio) {
            [weakSelf enableAudioTick:YES];
        }
        
        if (weakSelf.decoder.validVideo)
        {
            [weakSelf videoTick];
        }
    });
    
    
    
    LoggerStream(1, @"play movie");
}

- (void) _pause
{
    if (!self.playing)
        return;
    
    self.playing = NO;
    //_interrupted = YES;
#ifdef USE_OPENAL
    [[CYPCMAudioManager audioManager] setPlayRate:0];
#endif
    
#ifdef USE_AUDIOTOOL
    [self enableAudioTick:NO];
#endif
    LoggerStream(1, @"pause movie");
}

- (void)_stop
{
    if (!self.playing)
        return;
    
    self.playing = NO;
    _interrupted = YES;
    _generatedPreviewImageInterrupted = YES;
#ifdef USE_OPENAL
    [[CYPCMAudioManager audioManager] setPlayRate:0];//及时停止声音
#endif
    
#ifdef USE_AUDIOTOOL
    [self enableAudioTick:NO];
#endif
    LoggerStream(1, @"pause movie");
}

- (void)setMoviePosition:(CGFloat)position {
    
    BOOL playMode = self.playing;
    
    [self setMoviePosition:position playMode:playMode];
}

- (void)setMoviePosition:(CGFloat)position playMode:(BOOL)playMode {
    
    self.playing = NO;
    _buffered = NO;
    _disableUpdateHUD = YES;
    
    __weak typeof(self) weakSelf = self;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [weakSelf updatePosition:position playMode:playMode];
    });
}

- (void)generatedPreviewImagesWithCount:(NSInteger)imagesCount completionHandler:(CYPlayerImageGeneratorCompletionHandler)handler {
    
    __block CYPlayerDecoder *decoder = [[CYPlayerDecoder alloc] init];
    [decoder setDecodeType:CYVideoDecodeTypeVideo];
    
    __weak __typeof(self) weakSelf = self;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        
        NSError *error = nil;
        [decoder openFile:strongSelf->_decoder.path error:&error];
        
        if (strongSelf) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong __typeof(weakSelf) strongSelf2 = weakSelf;
                if (strongSelf2) {
                    [strongSelf2 setGeneratedPreviewImagesDecoder:decoder imagesCount:imagesCount withError:error completionHandler:handler];
                }
            });
        }
    });
}

- (void)setupPlayerWithPath:(NSString *)path {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    // increase buffering for .wmv, it solves problem with delaying audio frames
    if ([path.pathExtension isEqualToString:@"wmv"] ||
        [path.pathExtension isEqualToString:@"mov"])
        parameters[CDPlayerParameterMinBufferedDuration] = @(5.0);
    
    // disable deinterlacing for iPhone, because it's complex operation can cause stuttering
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        parameters[CDPlayerParameterDisableDeinterlacing] = @(YES);
    
    [self setupPlayerWithPath:path parameters:parameters];
}


# pragma mark - 私有方法
- (void) restorePlay
{
    NSNumber *n = [[self getHistory] valueForKey:_decoder.path];
    if (n)
        [self updatePosition:n.floatValue playMode:YES];
    else
        [self play];
}

- (void)rePlay
{
    if (_decoder.isEOF)
    {
        [self.decoder setPosition:0];
        [self replayFromInterruptWithDecoder:self.decoder];
    }
    else
    {
        [self setMoviePosition:0 playMode:YES];
    }
}

- (void)setGeneratedPreviewImagesDecoder: (CYPlayerDecoder *) decoder
                             imagesCount:(NSInteger)imagesCount
                               withError: (NSError *) error
                       completionHandler:(CYPlayerImageGeneratorCompletionHandler)handler
{
    LoggerStream(2, @"setMovieDecoder");
    if (!error && decoder && !self.stopped)
    {
        _generatedPreviewImagesDecoder        = decoder;
        _generatedPreviewImageInterrupted     = NO;
        _generatedPreviewImagesDispatchQueue  = dispatch_queue_create("CYPlayer_GeneratedPreviewImagesDispatchQueue", DISPATCH_QUEUE_SERIAL);
        _generatedPreviewImagesVideoFrames   = [NSMutableArray array];
        [decoder setupVideoFrameFormat:CYVideoFrameFormatRGB];
        
        
        __weak CDFFmpegPlayer *weakSelf = self;
        __weak CYPlayerDecoder *weakDecoder = decoder;
        
        const CGFloat duration = decoder.isNetwork ? .0f : 0.1f;
        
        dispatch_async(_generatedPreviewImagesDispatchQueue, ^{
            @autoreleasepool {
                CGFloat timeInterval = weakDecoder.duration / imagesCount;
                NSError * error = nil;
                int i = 0;
                __strong CDFFmpegPlayer *strongSelf = weakSelf;
                while (i < imagesCount && strongSelf && !strongSelf->_generatedPreviewImageInterrupted)
                    //                for (int i = 0; i < imagesCount; i++)
                {
                    __strong CYPlayerDecoder *decoder = weakDecoder;
                    
                    if (decoder && decoder.validVideo && decoder.isEOF == NO) {
                        NSArray *frames = [decoder decodeFrames:duration];
                        if (frames.count && [frames firstObject]) {
                            
                            if (strongSelf) {
                                @synchronized(strongSelf->_generatedPreviewImagesVideoFrames) {
                                    //                                        for (CYPlayerFrame *frame in frames)
                                    CYVideoFrame * frame = [frames firstObject];
                                    {
                                        if (frame.type == CYPlayerFrameTypeVideo)
                                        {
                                            [strongSelf->_generatedPreviewImagesVideoFrames addObject:frame];
                                            [decoder setPosition:(timeInterval * (i+1))];
                                            i++;
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if (strongSelf->_generatedPreviewImagesVideoFrames.count < imagesCount) {
                            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : @"Generated Failed!" };
                            
                            error = [NSError errorWithDomain:cyplayerErrorDomain
                                                        code:-1
                                                    userInfo:userInfo];
                        }
                        strongSelf->_generatedPreviewImageInterrupted = YES;
                        break;
                    }
                    
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong CDFFmpegPlayer *strongSelf2 = weakSelf;
                    if (!strongSelf2) {
                        return;
                    }
                    strongSelf2->_generatedPreviewImageInterrupted = YES;
                    strongSelf2->_generatedPreviewImagesDecoder = nil;
                    handler(strongSelf2->_generatedPreviewImagesVideoFrames, error);
                });
                
            }
        });
    } else {
        
    }
}

- (void)setMovieDecoder:(CYPlayerDecoder *)decoder
              withError:(NSError *)error {
    
    LoggerStream(2, @"setMovieDecoder");
    
    if (!error && decoder) {
        _decoder        = decoder;
        if (!_asyncDecodeQueue) _asyncDecodeQueue  = dispatch_queue_create("CYPlayer AsyncDecode", DISPATCH_QUEUE_SERIAL);
        if (!_videoFrames)_videoFrames    = [NSMutableArray array];
        if (!_audioFrames)_audioFrames    = [NSMutableArray array];
        
        if (_decoder.subtitleStreamsCount) {
           if (!_subtitles) _subtitles = [NSMutableArray array];
        }
        
        if (_decoder.isNetwork) {
            
            _minBufferedDuration = NETWORK_MIN_BUFFERED_DURATION;
            _maxBufferedDuration = NETWORK_MAX_BUFFERED_DURATION;
            
        } else {
            
            _minBufferedDuration = LOCAL_MIN_BUFFERED_DURATION;
            _maxBufferedDuration = LOCAL_MAX_BUFFERED_DURATION;
        }
        
        if (!_decoder.validVideo) {
            _minBufferedDuration *= 2.0; // increase for audio
            _maxBufferedDuration *= 20.0;
        }
        
        // allow to tweak some parameters at runtime
        if (_parameters.count) {
            
            id val;
            
            val = [_parameters valueForKey: CDPlayerParameterMinBufferedDuration];
            if ([val isKindOfClass:[NSNumber class]])
                _minBufferedDuration = [val floatValue];
            
            val = [_parameters valueForKey: CDPlayerParameterMaxBufferedDuration];
            if ([val isKindOfClass:[NSNumber class]])
                _maxBufferedDuration = [val floatValue];
            
            val = [_parameters valueForKey: CDPlayerParameterDisableDeinterlacing];
            if ([val isKindOfClass:[NSNumber class]])
                _decoder.disableDeinterlacing = [val boolValue];
            
            if (_maxBufferedDuration < _minBufferedDuration)
                _maxBufferedDuration = _minBufferedDuration * 2;
        }
        
        LoggerStream(2, @"buffered limit: %.1f - %.1f", _minBufferedDuration, _maxBufferedDuration);
        
        [self setupPresentView];
        [self _itemReadyToPlay];
    } else {
        if (!_interrupted) {
            [self handleDecoderMovieError:error];
            self.error = error;
            [self _itemPlayFailed];
        }
    }
}

- (void)setupPresentView {
    @synchronized (_glView) {
        UIView *frameView = [self presentView];
        if (frameView) {
            if ([frameView isKindOfClass:[CYPlayerGLView class]]) {
                if (_decoder.validVideo && [_decoder getVideoFrameFormat] == CYVideoFrameFormatYUV) {
                    [((CYPlayerGLView *)frameView) setDecoder:_decoder];
                    [((CYPlayerGLView *)frameView) updateVertices];
                } else {
                    [frameView removeFromSuperview];
                    frameView = nil;
                }
            } else if ([frameView isKindOfClass:[UIImageView class]]) {
                if (_decoder.validVideo && [_decoder getVideoFrameFormat] == CYVideoFrameFormatYUV) {
                    [frameView removeFromSuperview];
                    frameView = nil;
                }
            }
        }
        
        if (!frameView) {
            CGRect bounds = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
            
            if (_decoder.validVideo && [_decoder getVideoFrameFormat] == CYVideoFrameFormatYUV) {
                _glView = [[CYPlayerGLView alloc] initWithFrame:bounds decoder:_decoder];
                _glView.contentScaleFactor = [UIScreen mainScreen].scale;
                _glView.contentMode = UIViewContentModeScaleAspectFill;
            }
            
            if (!_glView) {
                
                LoggerVideo(0, @"fallback to use RGB video frame and UIKit");
                [_decoder setupVideoFrameFormat:CYVideoFrameFormatRGB];
                _imageView = [[UIImageView alloc] initWithFrame:bounds];
                _imageView.backgroundColor = [UIColor blackColor];
            }
            
            frameView = [self presentView];
            frameView.contentMode = UIViewContentModeScaleAspectFit;
            frameView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
            
            [self.view insertSubview:frameView atIndex:0];
            [frameView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.edges.equalTo(@0);
            }];
        }
        
        if (_decoder.validVideo) {
            __weak typeof(self) _self = self;
            if (!self.generatPreviewImages || [self.decoder.path hasPrefix:@"rtmp"] || [self.decoder.path hasPrefix:@"rtsp"]) {
                return;
            }
            
            [self generatedPreviewImagesWithCount:20 completionHandler:^(NSMutableArray<CYVideoFrame *> *frames, NSError *error) {
                __strong typeof(_self) self = _self;
                if ( !self ) return;
                if (error) {
                    _self.hasBeenGeneratedPreviewImages = NO;
                    return;
                }
                _self.hasBeenGeneratedPreviewImages = YES;
            }];
            
        } else {
            
            _imageView.image = [UIImage imageNamed:@"cyplayer.bundle/music_icon.png"];
            _imageView.contentMode = UIViewContentModeCenter;
        }
        
        if (_decoder.duration == MAXFLOAT) {
            
        } else {
            
        }
        
        if (_decoder.subtitleStreamsCount) {
            
        }
    }
    
}

- (void)handleDecoderMovieError:(NSError *)error {
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failure", nil)
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Close", nil)
                                              otherButtonTitles:nil];
    
    [alertView show];
}

- (UIView *)presentView {
    return _glView ? _glView : _imageView;
}

- (BOOL)interruptDecoder {
    //if (!_decoder)
    //    return NO;
    return _interrupted;
}


/// 释放buffered frames
- (void)freeBufferedFrames {
    
    @synchronized(_videoFrames) {
        [_videoFrames removeAllObjects];
    }
    
    @synchronized(_audioFrames) {
        
        [_audioFrames removeAllObjects];
        _currentAudioFrame = nil;
    }
    
    if (_subtitles) {
        @synchronized(_subtitles) {
            [_subtitles removeAllObjects];
        }
    }
    
    _videoBufferedDuration = 0;
    _audioBufferedDuration = 0;
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    
    [self pause];
    
    LoggerStream(1, @"applicationWillResignActive");
}

- (void)settingsPlayerNotification:(NSNotification *)notifi {
    [self.decoder setUseHWDecompressor:self.settings.useHWDecompressor];
}


- (void)asyncDecodeFrames {
    if (self.decoding) {
        return;
    }
    self.decoding = YES;
    
    __weak CDFFmpegPlayer *weakSelf = self;
    __weak CYPlayerDecoder *weakDecoder = _decoder;
    
    const CGFloat duration = _decoder.isNetwork ? 1.0f : 0.1f;
    dispatch_async(_asyncDecodeQueue, ^{
        __strong CDFFmpegPlayer *strongSelf = weakSelf;
        if (strongSelf) {
            if (!weakSelf.playing)
                return;
            
            BOOL good = YES;
            while (good && !weakSelf.stopped) {
                CFAbsoluteTime startTime =CFAbsoluteTimeGetCurrent();
                good = NO;
                
                @autoreleasepool {
                    
                    if (weakDecoder && (weakDecoder.validVideo || weakDecoder.validAudio)) {
                        
                        NSArray *frames = nil;
                        // 正在跳播
                        if (strongSelf->_positionUpdating) {
                            frames = [weakDecoder decodeTargetFrames:duration targetPos:strongSelf->_targetPosition];
                        } else {
                            frames = [weakDecoder decodeFrames:duration];
                        }
                        
                        if (frames.count) {
                            good = [weakSelf addFrames:frames];
                        }
                        frames = nil;
                    }
                }
                CFAbsoluteTime linkTime = (CFAbsoluteTimeGetCurrent() - startTime);
                NSLog(@"Linked asyncDecodeFrames in %f ms", linkTime * 1000.0);
            }
            
            weakSelf.decoding = NO;
        }
    });
}

/// 异步解码媒体文件
- (void)concurrentAsyncDecodeFrames {
    if (self.decoding) {
        return;
    }
    self.decoding = YES;
    
    __weak CDFFmpegPlayer *weakSelf = self;
    __weak CYPlayerDecoder *weakDecoder = _decoder;
    
    const CGFloat duration = _decoder.isNetwork ? 1.0f : 0.1f;
    dispatch_async(_asyncDecodeQueue, ^{
        __strong CDFFmpegPlayer *strongSelf = weakSelf;
        if (strongSelf) {
            if (!weakSelf.playing)
                return;
            CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
            
            @autoreleasepool {
                
                if (weakDecoder && (weakDecoder.validVideo || weakDecoder.validAudio)) {
                    
                    if (strongSelf->_positionUpdating)//正在跳播
                    {
                        [weakDecoder asyncDecodeFrames:duration targetPosition:strongSelf->_targetPosition compeletionHandler:^(NSArray<CYPlayerFrame *> *frames, BOOL compeleted) {
                            [weakSelf insertFrames:frames];
                            if (compeleted)
                            {
                                weakSelf.decoding = NO;
                            }
                        }];
                    } else {
                        [weakDecoder concurrentDecodeFrames:duration compeletionHandler:^(NSArray<CYPlayerFrame *> *frames, BOOL compeleted) {
                            [weakSelf insertFrames:frames];
                            if (compeleted)
                            {
                                weakSelf.decoding = NO;
                            }
                        }];
                    }
                }
            }
            CFAbsoluteTime linkTime = (CFAbsoluteTimeGetCurrent() - startTime);
            NSLog(@"Linked asyncDecodeFrames in %f ms", linkTime * 1000.0);
        }
    });
}

- (void)insertFrames:(NSArray *)frames {
    
    if (_decoder.validVideo) {
        
        @synchronized(_videoFrames) {
            
            for (CYPlayerFrame *frame in frames) {
                if (frame.type == CYPlayerFrameTypeVideo) {
                    if (!_positionUpdating)
                    {
                        NSInteger targetIndex = _videoFrames.count;
                        BOOL hasInserted = NO;
                        for( int i = 0; i < _videoFrames.count; i ++ )
                        {
                            CYVideoFrame * targetFrame = [_videoFrames objectAtIndex:i];
                            if (frame.position <= targetFrame.position)
                            {
                                targetIndex = i;
                                if (frame.position == targetFrame.position) {
                                    hasInserted = YES;
                                }
                                break;
                            }
                        }
                        if (!hasInserted) {
                            [_videoFrames insertObject:frame atIndex:targetIndex];
                            _videoBufferedDuration += frame.duration;
                        } else {
                            LoggerVideo(0, @"skip hasInserted video frames");
                        }
                        
                    } else {
                        if (frame.position >= _targetPosition) {
                            NSInteger targetIndex = _videoFrames.count;
                            BOOL hasInserted = NO;
                            for( int i = 0; i < _videoFrames.count; i++ ) {
                                CYVideoFrame * targetFrame = [_videoFrames objectAtIndex:i];
                                if (frame.position <= targetFrame.position) {
                                    targetIndex = i;
                                    if (frame.position == targetFrame.position) {
                                        hasInserted = YES;
                                    }
                                    break;
                                }
                            }
                            if (!hasInserted) {
                                [_videoFrames insertObject:frame atIndex:targetIndex];
                                _videoBufferedDuration += frame.duration;
                            } else {
                                LoggerVideo(0, @"skip hasInserted video frames");
                            }
                        }
                    }
                }
            }
        }
    }
    
    if (_decoder.validAudio) {
        
        @synchronized(_audioFrames) {
            
            for (CYPlayerFrame *frame in frames) {
                if (frame.type == CYPlayerFrameTypeAudio) {
                    if (!_positionUpdating) {
                        NSInteger targetIndex = _audioFrames.count;
                        BOOL hasInserted = NO;
                        for( int i = 0; i < _audioFrames.count; i ++ )
                        {
                            CYAudioFrame * targetFrame = [_audioFrames objectAtIndex:i];
                            if (frame.position <= targetFrame.position)
                            {
                                targetIndex = i;
                                if (frame.position == targetFrame.position) {
                                    hasInserted = YES;
                                }
                                break;
                            }
                        }
                         if (!hasInserted) {
                             [_audioFrames insertObject:frame atIndex:targetIndex];
                             _audioBufferedDuration += frame.duration;
                         } else {
                             LoggerVideo(0, @"skip hasInserted audio frames");
                         }
                    } else {
                        if (frame.position >= _targetPosition) {
                            NSInteger targetIndex = _audioFrames.count;
                            BOOL hasInserted = NO;
                            for( int i = 0; i < _audioFrames.count; i ++ )
                            {
                                CYAudioFrame * targetFrame = [_audioFrames objectAtIndex:i];
                                if (frame.position <= targetFrame.position)
                                {
                                    targetIndex = i;
                                    if (frame.position == targetFrame.position) {
                                        hasInserted = YES;
                                    }
                                    break;
                                }
                            }
                            if (!hasInserted) {
                                [_audioFrames insertObject:frame atIndex:targetIndex];
                                _audioBufferedDuration += frame.duration;
                            }else {
                                LoggerVideo(0, @"skip hasInserted audio frames");
                            }
                        }
                    }
                }
            }
        }
        
        if (!_decoder.validVideo) {
            
            for (CYPlayerFrame *frame in frames)
                if (frame.type == CYPlayerFrameTypeArtwork)
                    self.artworkFrame = (CYArtworkFrame *)frame;
        }
    }
    
    if (_decoder.validSubtitles) {
        
        @synchronized(_subtitles) {
            
            for (CYPlayerFrame *frame in frames) {
                if (frame.type == CYPlayerFrameTypeSubtitle) {
                    if (!_positionUpdating) {
                        NSInteger targetIndex = _subtitles.count;
                        BOOL hasInserted = NO;
                        for( int i = 0; i < _subtitles.count; i ++ ) {
                            CYSubtitleFrame * targetFrame = [_subtitles objectAtIndex:i];
                            if (frame.position <= targetFrame.position) {
                                targetIndex = i;
                                if (frame.position == targetFrame.position) {
                                    hasInserted = YES;
                                }
                                break;
                            }
                        }
                        if (!hasInserted) {
                            [_subtitles insertObject:frame atIndex:targetIndex];
                        } else {
                            LoggerVideo(0, @"skip hasInserted subtitles frames");
                        }
                    } else {
                        if (frame.position >= _targetPosition) {
                            NSInteger targetIndex = _subtitles.count;
                            BOOL hasInserted = NO;
                            for( int i = 0; i < _subtitles.count; i ++ )
                            {
                                CYSubtitleFrame * targetFrame = [_subtitles objectAtIndex:i];
                                if (frame.position <= targetFrame.position)
                                {
                                    targetIndex = i;
                                    if (frame.position == targetFrame.position) {
                                        hasInserted = YES;
                                    }
                                    break;
                                }
                            }
                            if (!hasInserted) {
                                [_subtitles insertObject:frame atIndex:targetIndex];
                            } else {
                                LoggerVideo(0, @"skip hasInserted subtitles frames");
                            }
                        }
                    }
                }
            }
        }
    }
}

- (BOOL)addFrames:(NSArray *)frames {
    
    if (_decoder.validVideo) {
        
        @synchronized(_videoFrames) {
            
            for (CYPlayerFrame *frame in frames) {
                if (frame.type == CYPlayerFrameTypeVideo) {
                    if (_positionUpdating)
                    {
                        if (frame.position >= _targetPosition)
                        {
                            [_videoFrames addObject:frame];
                            _videoBufferedDuration += frame.duration;
                        }
                    }
                    else
                    {
                        [_videoFrames addObject:frame];
                        _videoBufferedDuration += frame.duration;
                    }
                }
            }
        }
    }
    
    if (_decoder.validAudio) {
        
        @synchronized(_audioFrames) {
            
            for (CYPlayerFrame *frame in frames) {
                if (frame.type == CYPlayerFrameTypeAudio) {
                    if (_positionUpdating)
                    {
                        if (frame.position >= _targetPosition)
                        {
                            [_audioFrames addObject:frame];
                            //                    if (!_decoder.validVideo)
                            _audioBufferedDuration += frame.duration;
                        }
                    }
                    else
                    {
                        [_audioFrames addObject:frame];
                        //                    if (!_decoder.validVideo)
                        _audioBufferedDuration += frame.duration;
                    }
                }
            }
        }
        
        if (!_decoder.validVideo) {
            
            for (CYPlayerFrame *frame in frames)
                if (frame.type == CYPlayerFrameTypeArtwork)
                    self.artworkFrame = (CYArtworkFrame *)frame;
        }
    }
    
    if (_decoder.validSubtitles) {
        
        @synchronized(_subtitles) {
            
            for (CYPlayerFrame *frame in frames) {
                if (frame.type == CYPlayerFrameTypeSubtitle) {
                    if (_positionUpdating)
                    {
                        if (frame.position >= _targetPosition)
                        {
                            [_subtitles addObject:frame];
                        }
                    } else {
                        [_subtitles addObject:frame];
                    }
                }
            }
        }
    }
    
    return self.playing
        && (_videoBufferedDuration < _maxBufferedDuration || _audioBufferedDuration < _maxBufferedDuration)
        && ([self getMemoryUsedPercent] < MAX_BUFFERED_DURATION_MEMORY_USED_PERCENT)
        && HAS_PLENTY_OF_MEMORY;
}

- (void)videoTick {
    
    __weak typeof(&*self) weakSelf = self;
    CGFloat interval = 0;
    if (!_buffered) {
        if (_positionUpdating ) {
            _positionUpdating = NO;
        }
        interval = [self presentVideoFrame];
    }
    
    if (self.playing) {
        const NSUInteger leftFrames =
        (_decoder.validVideo ? _videoFrames.count : 0) +
        (_decoder.validAudio ? _audioFrames.count : 0);
        
        if ([self getMemoryUsedPercent] <= MAX_BUFFERED_DURATION_MEMORY_USED_PERCENT && HAS_PLENTY_OF_MEMORY)
        {
            if (!leftFrames ||
                (_videoBufferedDuration < _maxBufferedDuration)
//                ||
//                !(_audioBufferedDuration > _maxBufferedDuration)
                )
            {
                //            [self asyncDecodeFrames];
                [self concurrentAsyncDecodeFrames];
            }
        }
    
        const NSTimeInterval correction = [self tickCorrection];
        const NSTimeInterval time = MAX(interval + correction, 0.01);
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC);
        dispatch_after(popTime, _videoQueue, ^(void){
            [weakSelf videoTick];
        });
    }
    
    
}


- (void)audioCallbackFillData:(float *)outData
                    numFrames:(UInt32)numFrames
                  numChannels:(UInt32)numChannels {
#ifdef USE_AUDIOTOOL
    //fillSignalF(outData,numFrames,numChannels);
    //return;
    
    if (_buffered && _audioFrames.count <= 0) {
        memset(outData, 0, numFrames * numChannels * sizeof(float));
        return;
    }
    
    @autoreleasepool {
        
        while (numFrames > 0) {
            
            if (!_currentAudioFrame) {
                
                @synchronized(_audioFrames) {
                    
                    NSUInteger count = _audioFrames.count;
                    
                    if (count > 0) {
                        
                        CYAudioFrame *frame = _audioFrames[0];
                        
#ifdef DUMP_AUDIO_DATA
                        LoggerAudio(2, @"Audio frame position: %f", frame.position);
#endif
//                        if (_decoder.validVideo) {
//
//                            const CGFloat delta = _moviePosition - frame.position;
//
//                            if (delta < -0.1) {
//
//                                memset(outData, 0, numFrames * numChannels * sizeof(float));
//#ifdef DEBUG
//                                LoggerStream(0, @"desync audio (outrun) wait %.4f %.4f", _moviePosition, frame.position);
//                                _debugAudioStatus = 1;
//                                _debugAudioStatusTS = [NSDate date];
//#endif
//                                //                                [_audioFrames removeObjectAtIndex:0];
//                                //                                break; // silence and exit
//                            }
//
//
//                            if (delta > 0.1 && count > 1) {
//
//#ifdef DEBUG
//                                LoggerStream(0, @"desync audio (lags) skip %.4f %.4f", _moviePosition, frame.position);
//                                _debugAudioStatus = 2;
//                                _debugAudioStatusTS = [NSDate date];
//#endif
//                                continue;
//                            }
//
//                        }
                        [_audioFrames removeObjectAtIndex:0];
                        _audioPosition = frame.position;
                        _currentAudioFramePos = 0;
                        _audioBufferedDuration -= frame.duration;
                        _currentAudioFrame = frame.samples;
                    }
                }
            }
            
            if (_positionUpdating) {
                _positionUpdating = NO;
            }
            if (_currentAudioFrame) {
                
                const void *bytes = (Byte *)(_currentAudioFrame.bytes) + _currentAudioFramePos;
                const NSUInteger bytesLeft = (_currentAudioFrame.length - _currentAudioFramePos);
                const NSUInteger frameSizeOf = numChannels * sizeof(float);
                const NSUInteger bytesToCopy = MIN(numFrames * frameSizeOf, bytesLeft);
                const NSUInteger framesToCopy = bytesToCopy / frameSizeOf;
                
                memcpy(outData, bytes, bytesToCopy * 2);
                numFrames -= framesToCopy;
                outData += framesToCopy * numChannels;
                
                if (bytesToCopy < bytesLeft)
                    _currentAudioFramePos += bytesToCopy;
                else
                    _currentAudioFrame = nil;
                
            } else {
                
                memset(outData, 0, numFrames * numChannels * sizeof(float));
                //LoggerStream(1, @"silence audio");
#ifdef DEBUG
                _debugAudioStatus = 3;
                _debugAudioStatusTS = [NSDate date];
#endif
                break;
            }
        }
    }
#endif
}


- (void)enableAudioTick:(BOOL)on {
#ifdef USE_AUDIOTOOL
    id<CYAudioManager> audioManager = [CYAudioManager audioManager];

    if (on && _decoder.validAudio) {
        audioManager.delegate = self;
        
        audioManager.outputBlock = ^(float *outData, UInt32 numFrames, UInt32 numChannels) {
//            CFAbsoluteTime startTime =CFAbsoluteTimeGetCurrent();
            [self audioCallbackFillData: outData numFrames:numFrames numChannels:numChannels];
//            CFAbsoluteTime linkTime = (CFAbsoluteTimeGetCurrent() - startTime);
//            NSLog(@"Linked audioCallbackFillData in %f ms", linkTime *1000.0);
        };
        
        [audioManager play];
        
        LoggerAudio(2, @"audio device smr: %d fmt: %d chn: %d",
                    (int)audioManager.samplingRate,
                    (int)audioManager.numBytesPerSample,
                    (int)audioManager.numOutputChannels);
        
    } else {
        
        [audioManager pause];
        audioManager.outputBlock = nil;
        audioManager.delegate = nil;
    }
    
#endif
}


- (void)audioTick {
#ifdef USE_OPENAL
    __weak typeof(self) weakSelf = self;
    CYPCMAudioManager * audioManager = [CYPCMAudioManager audioManager];
    
    CGFloat interval = 0;
    if (!_buffered) {
        if ( _positionUpdating ) {
            _positionUpdating = NO;
        }
        interval = [self presentAudioFrame];
    } else {
        //        const int bufSize = 100;
        int bufSize = av_samples_get_buffer_size(NULL,
                                                 (int)audioManager.avcodecContextNumOutputChannels,
                                                 audioManager.audioCtx->frame_size,
                                                 AV_SAMPLE_FMT_S16,
                                                 1);
        bufSize = bufSize > 0 ? bufSize : 100;
        char * empty_audio_data = (char *)calloc(bufSize, sizeof(char));
        memset(empty_audio_data, 0, bufSize);
        NSData * empty_audio = [NSData dataWithBytes:empty_audio_data length:bufSize];
        [audioManager setData:empty_audio];//播放
        //        interval = delta;
    }
    
    if (self.playing) {
        const NSUInteger leftFrames =
        (_decoder.validVideo ? _videoFrames.count : 0) +
        (_decoder.validAudio ? _audioFrames.count : 0);
        
        if ((!leftFrames ||
            !(_videoBufferedDuration > _maxBufferedDuration) ||
            !(_audioBufferedDuration > _maxBufferedDuration))
            &&
            ([self getMemoryUsedPercent] <= MAX_BUFFERED_DURATION_MEMORY_USED_PERCENT) && HAS_PLENTY_OF_MEMORY) {
            [self concurrentAsyncDecodeFrames];
        }
        
        const NSTimeInterval correction = [self tickCorrection];
        const NSTimeInterval time = MAX(interval + correction, 0.01);
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
        dispatch_after(popTime, _audioQueue, ^(void){
            [weakSelf audioTick];
        });
    }
#endif
}

- (void)progressTick {
    
    __weak typeof(self) weakSelf = self;
    if ( _buffered &&((
          (_videoBufferedDuration > _minBufferedDuration) ||
          (_audioBufferedDuration > _minBufferedDuration)) || _decoder.isEOF || ([self getMemoryUsedPercent] > MAX_BUFFERED_DURATION_MEMORY_USED_PERCENT || !(HAS_PLENTY_OF_MEMORY)))) {
        _tickCorrectionTime = 0;
        _cantPlayStartTime = 0;
        _buffered = NO;
        if (([self getMemoryUsedPercent] > MAX_BUFFERED_DURATION_MEMORY_USED_PERCENT) || !(HAS_PLENTY_OF_MEMORY)) {
            [self play];
        } else {
            if ((_videoBufferedDuration > _minBufferedDuration) ||
                (_audioBufferedDuration > _minBufferedDuration)) {
                [self play];
            }
        }
        
    }
    
    if (self.playing) {
        
        const NSUInteger leftFrames =
        (_decoder.validVideo ? _videoFrames.count : 0) +
        (_decoder.validAudio ? _audioFrames.count : 0);
        
        CGFloat curr_position = _decoder.validVideo ? _moviePosition : _audioPosition;
        if ( leftFrames == 0 ) {
            if (_decoder.isEOF) {
                if (_decoder.duration - curr_position <= 1.0 &&
                    _decoder.duration > 0 &&
                    _decoder.duration != NSNotFound) {
                    
                    [self _itemPlayEnd];
                    return;
                }
                if ([_decoder.path hasPrefix:@"rtsp"] || [_decoder.path hasPrefix:@"rtmp"] || [[_decoder.path lastPathComponent] containsString:@"m3u8"]) {
                    
                    [self _pause];
                    CGFloat interval = 0;
                    const NSTimeInterval correction = [self tickCorrection];
                    const NSTimeInterval time = MAX(interval + correction, 0.01);
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC);
                    dispatch_after(popTime, _progressQueue, ^(void){
                        [weakSelf replayFromInterruptWithDecoder:weakSelf.decoder];
                    });
                    return;
                } else {
                    
                    [self _itemPlayFailed];
                    
                    return;
                }
            } else {
                if (_cantPlayStartTime <= 0) {
                    _cantPlayStartTime = CFAbsoluteTimeGetCurrent();
                }
                CFAbsoluteTime currTime = CFAbsoluteTimeGetCurrent();
                NSString * currTimeStr = [NSString stringWithFormat:@"%f", currTime * 1000.0];
                CGFloat curr = [currTimeStr doubleValue];
                NSString * cantPlayStartTimeStr = [NSString stringWithFormat:@"%f", _cantPlayStartTime * 1000.0];
                CGFloat cant = [cantPlayStartTimeStr doubleValue];
                CGFloat durationTime = curr - cant;
                if (durationTime >= CYPLAYER_MAX_TIMEOUT * 1000) {
                    _interrupted = YES;
                    _cantPlayStartTime = 0.0;
                    return;
                }
            }
            
            if (_minBufferedDuration > 0) {
                
                if (!_buffered) {
                    _buffered = YES;
                }
                
                if (self.state != CDFFmpegPlayerPlayState_Buffing) {
                    [self _buffering];
                }
                
            }
        } else if ((_videoFrames.count == 0 && _audioFrames.count != 0 && _decoder.validVideo == YES) ||
                 ((_audioFrames.count == 0 && _videoFrames.count != 0 && _decoder.validAudio == YES))) {
            if (_decoder.isEOF) {
                if (_decoder.duration - curr_position <= 1.0 &&
                    _decoder.duration > 0 &&
                    _decoder.duration != NSNotFound) {
                    
                    [self _itemPlayEnd];
                    return;
                }
                if ([_decoder.path hasPrefix:@"rtsp"] || [_decoder.path hasPrefix:@"rtmp"] || [[_decoder.path lastPathComponent] containsString:@"m3u8"]) {
                    [self _pause];
                    CGFloat interval = 0;
                    const NSTimeInterval correction = [self tickCorrection];
                    const NSTimeInterval time = MAX(interval + correction, 0.01);
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC);
                    dispatch_after(popTime, _progressQueue, ^(void){
                        [weakSelf replayFromInterruptWithDecoder:weakSelf.decoder];
                    });
                    return;
                } else {
                    
                    [self _itemPlayFailed];

                    return;
                }
            }
        }
        
        if ([self.decoder validVideo]) {
            if ([self getMemoryUsedPercent] <= MAX_BUFFERED_DURATION_MEMORY_USED_PERCENT && HAS_PLENTY_OF_MEMORY) {
                if (!leftFrames || (_videoBufferedDuration < _maxBufferedDuration)) {
                    [self concurrentAsyncDecodeFrames];
                }
            }
        } else if (![self.decoder validVideo] && [self.decoder validAudio]) {
            if ([self getMemoryUsedPercent] <= MAX_BUFFERED_DURATION_MEMORY_USED_PERCENT && HAS_PLENTY_OF_MEMORY) {
                if (!leftFrames || (_audioBufferedDuration < _maxBufferedDuration)) {
                    
                    [self concurrentAsyncDecodeFrames];
                }
            }
        }
        
        CGFloat interval = 0.1;
        const NSTimeInterval correction = [self tickCorrection];
        const NSTimeInterval time = MAX(interval + correction, 0.01);
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC);
        dispatch_after(popTime, _progressQueue, ^(void){
            [weakSelf progressTick];
        });
    }
    
    [self refreshProgressViews];
}

- (void)refreshProgressViews
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(_progressQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf)
        {
            const CGFloat duration = strongSelf->_decoder.duration;
            CGFloat position = strongSelf->_audioPosition - strongSelf->_decoder.startTime;
            if (weakSelf.decoder.validVideo)
            {
                position = strongSelf->_moviePosition - strongSelf->_decoder.startTime;
            }
            if ((strongSelf->_tickCounter++ % 3) == 0 && strongSelf->_isDraging == NO) {
                const CGFloat loadedPosition = weakSelf.decoder.position;
                [weakSelf _refreshingTimeProgressSliderWithCurrentTime:position duration:duration];
                [weakSelf _refreshingTimeLabelWithCurrentTime:position duration:duration];
                [weakSelf _refreshingTimeProgressSliderWithLoadedTime:loadedPosition duration:duration];
            }
            
            if ([weakSelf.delegate respondsToSelector:@selector(cdFFmpegPlayer:updatePosition:duration:isDrag:)]) {
                [weakSelf.delegate cdFFmpegPlayer:weakSelf updatePosition:position duration:duration isDrag:strongSelf->_isDraging];
            }
            
            if (strongSelf.settings.definitionTypes != CYFFmpegPlayerDefinitionNone) {
                if (strongSelf->_definitionType == 0) {
                    if (strongSelf.settings.definitionTypes & CYFFmpegPlayerDefinitionLLD) {
                        strongSelf->_definitionType = CYFFmpegPlayerDefinitionLLD;
                    }else if (strongSelf.settings.definitionTypes & CYFFmpegPlayerDefinitionLSD) {
                        strongSelf->_definitionType = CYFFmpegPlayerDefinitionLSD;
                    }else if (strongSelf.settings.definitionTypes & CYFFmpegPlayerDefinitionLHD) {
                        strongSelf->_definitionType = CYFFmpegPlayerDefinitionLHD;
                    }else if (strongSelf.settings.definitionTypes & CYFFmpegPlayerDefinitionLUD) {
                        strongSelf->_definitionType = CYFFmpegPlayerDefinitionLUD;
                    }
                    
                }
                [strongSelf refreshDefinitionBtnStatus];
            }
            
            if (strongSelf.settings.enableSelections) {
                [strongSelf refreshSelectionsBtnStatus];
            }
        }
    });
}

- (CGFloat) tickCorrection
{
    if (_buffered)
        return 0;
    
    const NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    
    if (!_tickCorrectionTime) {
        
        _tickCorrectionTime = now;
        _tickCorrectionPosition = _moviePosition;
        return 0;
    }
    
    NSTimeInterval dPosition = _moviePosition - _tickCorrectionPosition;
    NSTimeInterval dTime = now - _tickCorrectionTime;
    NSTimeInterval correction = dPosition - dTime;
    
    //if ((_tickCounter % 200) == 0)
    //    LoggerStream(1, @"tick correction %.4f", correction);
    
    if (correction > 2.f || correction < -2.f) {
        
        LoggerStream(1, @"tick correction reset %.2f", correction);
        correction = 0;
        _tickCorrectionTime = 0;
    }
    
    return correction;
}

- (CGFloat) presentAudioFrame
{
#ifdef USE_OPENAL
    CGFloat interval = 0;
    
    CYPCMAudioManager * audioManager = [CYPCMAudioManager audioManager];
    audioManager.delegate = self;
    
    @synchronized(_audioFrames)
    {
        NSUInteger count = _audioFrames.count;
        CYAudioFrame * audioFrame = [_audioFrames firstObject];
        if ([audioFrame isKindOfClass: NSClassFromString(@"CYAudioFrame")] &&
            count > 0)
        {
            if (_decoder.validAudio)
            {
                _audioPosition = audioFrame.position;
                CGFloat delta = _audioPosition - _moviePosition;
                CGFloat limit_val = 0.1;
                //                if (limit_val < 1) { limit_val = 1; }
                if (delta <= limit_val && delta >= -(limit_val))//音视频处于同步
                {
                    
                    [_audioFrames removeObjectAtIndex:0];
                    _audioBufferedDuration -= audioFrame.duration;
                    [audioManager setData:audioFrame.samples];//播放
                    interval = audioFrame.duration;
                }
                else if (delta > limit_val)//音频快了
                {
                    [_audioFrames removeObjectAtIndex:0];
                    _audioBufferedDuration -= audioFrame.duration;
                    [audioManager setData:audioFrame.samples];//播放
                    interval = audioFrame.duration;
                }
                else//音频慢了
                {
                    [_audioFrames removeObjectAtIndex:0];
                    _audioBufferedDuration -= audioFrame.duration;
                    [audioManager setData:audioFrame.samples];//播放
                    interval = audioFrame.duration;
                    //                    interval = 0;
                }
            }
        }
    }
    
    return interval;
#endif
    return 0;
}

- (CGFloat)presentVideoFrame {
    
    CGFloat interval = 0;
    
    if (_decoder.validVideo) {
        
        CYVideoFrame *frame;
        
        @synchronized(_videoFrames) {
            
            if (_videoFrames.count > 0) {
                
                frame = _videoFrames[0];
                _moviePosition = frame.position;
                
                CGFloat delta = _moviePosition - _audioPosition;
                CGFloat limit_val = 0.1;
                //                if (limit_val < 1) { limit_val = 1; }
                if (delta <= limit_val && delta >= -(limit_val))//音视频处于同步
                {
                    
                    [_videoFrames removeObjectAtIndex:0];
                    _videoBufferedDuration -= frame.duration;
                    interval = [self presentVideoFrame:frame];//呈现视频
                }
                else if (delta > limit_val)//视频快了
                {
                    [_videoFrames removeObjectAtIndex:0];
                    _videoBufferedDuration -= frame.duration;
                    interval = [self presentVideoFrame:frame];//呈现视频
                    //                    interval = delta;
                }
                else//视频慢了
                {
                    [_videoFrames removeObjectAtIndex:0];
                    _videoBufferedDuration -= frame.duration;
                    interval = [self presentVideoFrame:frame];//呈现视频
                    //                    interval = 0;
                }
            }
        }
        
    } else if (_decoder.validAudio) {
        
        //interval = _videoBufferedDuration * 0.5;
        
        if (self.artworkFrame) {
            
            _imageView.image = [self.artworkFrame asImage];
            self.artworkFrame = nil;
        }
    }
    
    if (_decoder.validSubtitles)
        [self presentSubtitles];
    
#ifdef DEBUG
    if (self.playing && _debugStartTime < 0)
        _debugStartTime = [NSDate timeIntervalSinceReferenceDate] - _moviePosition;
#endif
    
    return interval;
}

- (CGFloat)presentVideoFrame:(CYVideoFrame *)frame {
    
    if([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        if (_glView) {
            
            @synchronized (_glView) {
                [_glView render:frame];
            }
            
        } else {
            
            CYVideoFrameRGB *rgbFrame = (CYVideoFrameRGB *)frame;
            _imageView.image = [rgbFrame asImage];
        }
    }
    _moviePosition = frame.position;
    
    return frame.duration;
}

- (void)presentSubtitles {
    NSArray *actual, *outdated;
    
    if ([self subtitleForPosition:_moviePosition
                           actual:&actual
                         outdated:&outdated]){
        
        if (outdated.count) {
            @synchronized(_subtitles) {
                [_subtitles removeObjectsInArray:outdated];
            }
        }
        
        if (actual.count) {
            
            NSMutableString *ms = [NSMutableString string];
            for (CYSubtitleFrame *subtitle in actual.reverseObjectEnumerator) {
                if (ms.length) [ms appendString:@"\n"];
                [ms appendString:subtitle.text];
            }
            
        } else {
            
            
        }
    }
}

- (BOOL) subtitleForPosition: (CGFloat) position
                      actual: (NSArray **) pActual
                    outdated: (NSArray **) pOutdated
{
    if (!_subtitles.count)
        return NO;
    
    NSMutableArray *actual = nil;
    NSMutableArray *outdated = nil;
    
    for (CYSubtitleFrame *subtitle in _subtitles) {
        
        if (position < subtitle.position) {
            
            break; // assume what subtitles sorted by position
            
        } else if (position >= (subtitle.position + subtitle.duration)) {
            
            if (pOutdated) {
                if (!outdated)
                    outdated = [NSMutableArray array];
                [outdated addObject:subtitle];
            }
            
        } else {
            
            if (pActual) {
                if (!actual)
                    actual = [NSMutableArray array];
                [actual addObject:subtitle];
            }
        }
    }
    
    if (pActual) *pActual = actual;
    if (pOutdated) *pOutdated = outdated;
    
    return actual.count || outdated.count;
}

- (void)updatePosition:(CGFloat)position
              playMode:(BOOL)playMode {
    
    if (_buffered) {
        return;
    }
    _positionUpdating = YES;
    _buffered = YES;
//    [self pause];
    __weak CDFFmpegPlayer *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf _startLoading];
    });
    [self freeBufferedFrames];
    //刷新audioManagr缓存队列中未来得及播放完的数据
#ifdef USE_OPENAL
    [[CYPCMAudioManager audioManager] stopAndCleanBuffer];
#endif
    
    position = MIN(_decoder.duration - 1, MAX(0, position));
    position = MAX(position, 0);
    _targetPosition = position;
    
    if (playMode) {
        dispatch_async(_asyncDecodeQueue, ^{
            {
                __strong CDFFmpegPlayer *strongSelf = weakSelf;
                if (!strongSelf) return;
                [strongSelf setDecoderPosition: position];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                __strong CDFFmpegPlayer *strongSelf = weakSelf;
                if (strongSelf) {
                    [strongSelf setMoviePositionFromDecoder];
                    [weakSelf play];
                    strongSelf->_isDraging = NO;
                }
            });
        });
    } else {
        dispatch_async(_asyncDecodeQueue, ^{
            {
                __strong CDFFmpegPlayer *strongSelf = weakSelf;
                if (!strongSelf) return;
                [strongSelf setDecoderPosition: position];
                [strongSelf decodeFrames];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                __strong CDFFmpegPlayer *strongSelf = weakSelf;
                if (strongSelf) {
                    
                    [strongSelf setMoviePositionFromDecoder];
                    [strongSelf presentVideoFrame];
                    strongSelf->_isDraging = NO;
                }
            });
        });
    }
}

- (void)setDecoderPosition:(CGFloat)position {
    _decoder.position = position;
}

- (void)setMoviePositionFromDecoder {
    _moviePosition = _decoder.position;
    _audioPosition = [_decoder position];
}

- (BOOL)decodeFrames {
//    NSAssert(dispatch_get_current_queue() == _asyncDecodeQueue, @"bugcheck");
    
    NSArray *frames = nil;
    
    if (_decoder.validVideo ||
        _decoder.validAudio) {
        
        frames = [_decoder decodeFrames:0];
    }
    
    if (frames.count) {
        return [self addFrames: frames];
    }
    return NO;
}

- (NSMutableDictionary *)getHistory
{
    return gHistory;
}

- (void)setHiddenLeftControlView:(BOOL)hiddenLeftControlView {
    if ( hiddenLeftControlView == _hiddenLeftControlView ) return;
    _hiddenLeftControlView = hiddenLeftControlView;
    if ( _hiddenLeftControlView ) {
        
    } else {
        
    }
}

- (CYVideoPlayerRegistrar *)registrar {
    if ( _registrar ) return _registrar;
    _registrar = [CYVideoPlayerRegistrar new];
    
    __weak typeof(self) _self = self;
    _registrar.willResignActive = ^(CYVideoPlayerRegistrar * _Nonnull registrar) {
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        self.lockScreen = YES;
        [self pause];
    };
    
    _registrar.didBecomeActive = ^(CYVideoPlayerRegistrar * _Nonnull registrar) {
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        self.lockScreen = NO;
        if ( self.state == CDFFmpegPlayerPlayState_PlayEnd ||
            self.state == CDFFmpegPlayerPlayState_Unknown ||
            self.state == CDFFmpegPlayerPlayState_PlayFailed ) return;
        if ( !self.userClickedPause ) [self play];
    };
    
    _registrar.oldDeviceUnavailable = ^(CYVideoPlayerRegistrar * _Nonnull registrar) {
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        if ( !self.userClickedPause ) [self pause];
    };
    
    _registrar.categoryChange = ^(CYVideoPlayerRegistrar * _Nonnull registrar) {
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        if ( !self.userClickedPause ) [self pause];
    };
    
    _registrar.newDeviceAvailable = ^(CYVideoPlayerRegistrar * _Nonnull registrar) {
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        if ( !self.userClickedPause ) [self pause];
    };
    
    return _registrar;
}

- (void)setState:(CDFFmpegPlayerPlayState)state {
    if ( state == _state ) return;
    _state = state;
    if ([self.delegate respondsToSelector:@selector(cdFFmpegPlayer:changeStatus:)])
    {
        [self.delegate cdFFmpegPlayer:self changeStatus:_state];
    }
}

- (dispatch_queue_t)workQueue {
    if ( _workQueue ) return _workQueue;
    _workQueue = dispatch_queue_create("com.CYVideoPlayer.workQueue", DISPATCH_QUEUE_SERIAL);
    return _workQueue;
}

- (void)_addOperation:(void(^)(CDFFmpegPlayer *player))block {
    __weak typeof(self) _self = self;
    dispatch_async(self.workQueue, ^{
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        if ( block ) block(self);
    });
}

- (void)gesturesHandleWithTargetView:(UIView *)targetView {
    
    _gestureControl = [[CDPlayerGestureControl alloc] initWithTargetView:targetView];
    
    __weak typeof(self) _self = self;
    _gestureControl.triggerCondition = ^BOOL(CDPlayerGestureControl * _Nonnull control, UIGestureRecognizer *gesture) {
        __strong typeof(_self) self = _self;
        if (!self) {return NO;}
        //        if (self->_buffered) { return NO; }
        if ([self.control_delegate respondsToSelector:@selector(cdFFmpegPlayer:triggerCondition:gesture:)]) {
            return [self.control_delegate cdFFmpegPlayer:self triggerCondition:control gesture:gesture];
        }
        if ( self.isLockedScrren ) return NO;
//        CGPoint point = [gesture locationInView:gesture.view];
        BOOL result = YES;
        
        return result;
    };
    
    
    _gestureControl.singleTapped = ^(CDPlayerGestureControl * _Nonnull control) {
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        if ([self.control_delegate respondsToSelector:@selector(cdFFmpegPlayer:singleTapped:)]) {
            [self.control_delegate cdFFmpegPlayer:self singleTapped:control];
        }
        _cdAnima(^{
            self.hideControl = !self.isHiddenControl;
            
        });
    };
    
    _gestureControl.doubleTapped = ^(CDPlayerGestureControl * _Nonnull control) {
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        //        if (self->_buffered) return;
        if ([self.control_delegate respondsToSelector:@selector(cdFFmpegPlayer:doubleTapped:)]) {
            [self.control_delegate cdFFmpegPlayer:self doubleTapped:control];
        }
        switch (self.state) {
            case CDFFmpegPlayerPlayState_Unknown:
            case CDFFmpegPlayerPlayState_Prepare:
                break;
            case CDFFmpegPlayerPlayState_Buffing:
            case CDFFmpegPlayerPlayState_Playing: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self pause];
                    [self showTitle:@"已暂停"];
                });
                self.userClickedPause = YES;
            }
                break;
            case CDFFmpegPlayerPlayState_Pause:
            case CDFFmpegPlayerPlayState_PlayEnd:
            case CDFFmpegPlayerPlayState_Ready: {
                [self play];
                self.userClickedPause = NO;
            }
                break;
            case CDFFmpegPlayerPlayState_PlayFailed:
                break;
        }
        
    };
    
    _gestureControl.beganPan = ^(CDPlayerGestureControl * _Nonnull control, CDPanDirection direction, CDPanLocation location) {
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        if (self->_buffered) return;
        if (self->_positionUpdating) { return; }
        if ([self.control_delegate respondsToSelector:@selector(cdFFmpegPlayer:beganPan:direction:location:)]) {
            [self.control_delegate cdFFmpegPlayer:self beganPan:control direction:direction location:location];
        }
        switch (direction) {
            case CDPanDirection_H: {
                
                if (![self settings].enableProgressControl) {
                    return;
                }
                
                if (self->_decoder.duration <= 0)//没有进度信息
                {
                    return;
                }
                
//                [self _pause];
                _cdAnima(^{
                    
                });
                
                if ([self.decoder validVideo]) {
                    
                } else if ([self.decoder validAudio]) {
                    
                } else {
                    
                }
                self.hideControl = YES;
            }
                break;
            case CDPanDirection_V: {
                switch (location) {
                    case CDPanLocation_Right: break;
                    case CDPanLocation_Left: {
                        
                    }
                        break;
                    case CDPanLocation_Unknown: break;
                }
            }
                break;
            case CDPanDirection_Unknown:
                break;
        }
    };
    
    _gestureControl.changedPan = ^(CDPlayerGestureControl * _Nonnull control, CDPanDirection direction, CDPanLocation location, CGPoint translate) {
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        if ( self->_buffered ) return;
        if (self->_positionUpdating) { return; }
        if ([self.control_delegate respondsToSelector:@selector(cdFFmpegPlayer:changedPan:direction:location:)]) {
            [self.control_delegate cdFFmpegPlayer:self changedPan:control direction:direction location:location];
        }
        switch (direction) {
            case CDPanDirection_H: {
                if (![self settings].enableProgressControl) {
                    return;
                }
                
                if (self->_decoder.duration <= 0)//没有进度信息
                {
                    return;
                }
                NSLog(@"%f", translate.x * 0.0003);
            }
                break;
            case CDPanDirection_V: {
                switch (location) {
                    case CDPanLocation_Left: {
                        
                    }
                        break;
                    case CDPanLocation_Right: {
                        
                        
                    }
                        break;
                    case CDPanLocation_Unknown: break;
                }
            }
                break;
            default:
                break;
        }
    };
    
    _gestureControl.endedPan = ^(CDPlayerGestureControl * _Nonnull control, CDPanDirection direction, CDPanLocation location) {
        if ([_self.control_delegate respondsToSelector:@selector(cdFFmpegPlayer:endedPan:direction:location:)]) {
            [_self.control_delegate cdFFmpegPlayer:_self endedPan:control direction:direction location:location];
        }
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        if ( self->_buffered ) return;
        if (self->_positionUpdating) { return; }
        switch ( direction ) {
            case CDPanDirection_H:{
                if (![self settings].enableProgressControl) {
                    return;
                }
                
                if (self->_decoder.duration <= 0) { return; }//没有进度信息
                
                if (!self->_positionUpdating) { self->_positionUpdating = YES; } //手势互斥
                
            }
                break;
            case CDPanDirection_V:{
                if ( location == CDPanLocation_Left ) {
                    
                }
            }
                break;
            case CDPanDirection_Unknown: break;
        }
    };
}

- (void)_itemPrepareToPlay {
    [self _startLoading];
    _interrupted = NO;
    self.hideControl = YES;
    self.userClickedPause = NO;
    [self _prepareState];
}

- (void)_itemPlayFailed {
    [self _stopLoading];
    _interrupted = YES;
    [self _pause];
    [self _playFailedState];
    _cdErrorLog(self.error);
}

- (void)_itemReadyToPlay {
    _cdAnima(^{
        self.hideControl = NO;
    });
    if ( self.isAutoplay && !self.userClickedPause && !self.suspend ) {
        if ([self.delegate respondsToSelector:@selector(cdFFmpegPlayerStartAutoPlaying:)])
        {
            [self.delegate cdFFmpegPlayerStartAutoPlaying:self];
        }
        [self play];
    }
    [self _readyState];
    [self refreshProgressViews];
}

- (void)_itemPlayEnd {
    [self _stopLoading];
    [self _pause];
    [self setDecoderPosition:0.0];
    _audioPosition = 0.0;
    _moviePosition = 0.0;
    [self refreshProgressViews];
    [self _playEndState];
}

- (void)_refreshingTimeLabelWithCurrentTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration {
    if (currentTime == NSNotFound || isnan(currentTime) || currentTime == MAXFLOAT) {
        return;
    }
    if (currentTime > duration || duration == NSNotFound || isnan(duration) || duration == MAXFLOAT) {
//        self.controlView.bottomControlView.currentTimeLabel.text = _formatWithSec(currentTime);
//        self.controlView.bottomControlView.durationTimeLabel.text = @"LIVE?";
    } else {
        if (currentTime >= 0 && duration >= 0) {
            
        }
    }
}

- (void)_refreshingTimeProgressSliderWithCurrentTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration {
    CGFloat progress = currentTime / duration;
    if (isnan(progress) || progress == NSNotFound || progress == MAXFLOAT) {
        progress = 0.0;
    }
}

- (void)_refreshingTimeProgressSliderWithLoadedTime:(NSTimeInterval)loadedTime duration:(NSTimeInterval)duration {
    CGFloat progress = loadedTime / duration;
    if (isnan(progress) || progress == NSNotFound || progress == MAXFLOAT) {
        progress = 0.0;
    }
}

# pragma mark tools
- (double)getAvailableMemorySize {
    vm_statistics_data_t vmStats;
    mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
    kern_return_t kernReturn = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmStats, &infoCount);
    if (kernReturn != KERN_SUCCESS)
    {
        return NSNotFound;
    }

    return ((vm_page_size * vmStats.free_count)) / 1024.0 / 1024.0;// + vm_page_size * vmStats.inactive_count
}

- (double)usedMemory {
    task_basic_info_data_t taskInfo;
    mach_msg_type_number_t infoCount =TASK_BASIC_INFO_COUNT;
    kern_return_t kernReturn =task_info(mach_task_self(),
                                        TASK_BASIC_INFO,
                                        (task_info_t)&taskInfo,
                                        &infoCount);
    if (kernReturn != KERN_SUCCESS) {
        return NSNotFound;
    }
    return taskInfo.resident_size / 1024.0 / 1024.0;
    
}

- (double)memoryUsage {
    vm_size_t memory = m_memory_usage();
    return memory / 1000.0 /1000.0;
}


vm_size_t m_memory_usage(void) {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    return (kerr == KERN_SUCCESS) ? info.resident_size : 0; // size in bytes
}

- (double)getMemoryUsedPercent {
    
    double result = 1;
    
    result = [self getAvailableMemorySize] / [self getTotalMemorySize];
    
    result = 1 - result;
    
    return result >= 0 ? result * 100 : 100;
}

- (double)getTotalMemorySize {
    return [NSProcessInfo processInfo].physicalMemory / 1024.0 / 1024.0;
}

- (void)replayFromInterruptWithDecoder:(CYPlayerDecoder *)old_decoder {
    
    if (self.state == CDFFmpegPlayerPlayState_Prepare) {
        return;
    }
    
    [self _itemPrepareToPlay];
    NSString * path = _path;
    id<CYAudioManager> audioManager = [CYAudioManager audioManager];
    BOOL canUseAudio = [audioManager activateAudioSession];
    __block CYPlayerDecoder *decoder = [[CYPlayerDecoder alloc] init];
    CYVideoDecodeType type = CYVideoDecodeTypeVideo;
    if (canUseAudio) {
        type |= CYVideoDecodeTypeAudio;
    }
    if (old_decoder) {
        type = old_decoder.decodeType;
    }
    [decoder setDecodeType:type];
    __weak __typeof(self) weakSelf = self;
    
    _interrupted = NO;
    decoder.interruptCallback = ^BOOL(){
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        return strongSelf ? [strongSelf interruptDecoder] : YES;
    };
    self.autoplay = YES;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        
        NSError *error = nil;
        [decoder openFile:path error:&error];
        [decoder setupVideoFrameFormat:CYVideoFrameFormatYUV];
        
        if (strongSelf) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                __strong __typeof(weakSelf) strongSelf2 = weakSelf;
                if (strongSelf2 && !strongSelf.stopped && !error) {
                    [decoder setPosition:old_decoder.position];
                    //关闭原先的解码器
                    //                    [strongSelf.decoder closeFile];
                    //播放器连接新的解码器decoder
                    [strongSelf2 setMovieDecoder:decoder withError:error];
                }
                else if (error) {
                    [weakSelf handleDecoderMovieError: error];
                    weakSelf.error = error;
                    [weakSelf _itemPlayFailed];
                }
                else
                {
                   [weakSelf _itemPlayFailed];
                }
            });
        }
    });
}

@end

# pragma mark -

@implementation CDFFmpegPlayer (State)

- (CYTimerControl *)timerControl {
    CYTimerControl *timerControl = objc_getAssociatedObject(self, _cmd);
    if ( timerControl ) return timerControl;
    timerControl = [CYTimerControl new];
    objc_setAssociatedObject(self, _cmd, timerControl, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return timerControl;
}

- (void)_cancelDelayHiddenControl {
    [self.timerControl reset];
}

- (void)_delayHiddenControl {
    __weak typeof(self) _self = self;
    [self.timerControl start:^(CYTimerControl * _Nonnull control) {
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        if ( self.state == CDFFmpegPlayerPlayState_Pause ) return;
        _cdAnima(^{
            self.hideControl = YES;
        });
    }];
}

- (void)setLockScreen:(BOOL)lockScreen {
    
    if ( self.isLockedScrren == lockScreen ) {
        return;
    }
    objc_setAssociatedObject(self, @selector(isLockedScrren), @(lockScreen), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    //外部调用
    if (self.lockscreen) {
        self.lockscreen(lockScreen);
    }
    
    [self _cancelDelayHiddenControl];
    _cdAnima(^{
        if ( lockScreen ) {
            [self _lockScreenState];
        }
        else {
            [self _unlockScreenState];
        }
    });
}

- (BOOL)isLockedScrren {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setHideControl:(BOOL)hideControl {
    [self.timerControl reset];
    if ( hideControl ) [self _hideControlState];
    else {
        [self _showControlState];
        [self _delayHiddenControl];
    }
    
    BOOL oldValue = self.isHiddenControl;
    if ( oldValue != hideControl ) {
        objc_setAssociatedObject(self, @selector(isHiddenControl), @(hideControl), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if ( self.controlViewDisplayStatus ) self.controlViewDisplayStatus(self, !hideControl);
        if ([self.delegate respondsToSelector:@selector(cdFFmpegPlayer:controlViewDisplayStatus:)])  {
            [self.delegate cdFFmpegPlayer:self controlViewDisplayStatus:!hideControl];
        }
    }
}

- (BOOL)isHiddenControl {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)_unknownState {
    // hidden
    self.state = CDFFmpegPlayerPlayState_Unknown;
}

- (void)_prepareState {
    
    
    [self _unlockScreenState];
    
    self.hiddenLeftControlView = YES;
    
    self.state = CDFFmpegPlayerPlayState_Prepare;
}

- (void)_readyState {
    self.state = CDFFmpegPlayerPlayState_Ready;
}

- (void)_playState {
    
    // show
    
    // hidden
    // hidden
    
    self.state = CDFFmpegPlayerPlayState_Playing;
}

- (void)_pauseState {
    
    // show
    
    // hidden
    
    self.state = CDFFmpegPlayerPlayState_Pause;
}

- (void)_playEndState {
    
    if (self.settings.nextAutoPlaySelectionsPath) {
        
        NSString * path = self.settings.nextAutoPlaySelectionsPath();
        
        if (path.length > 0) {
            [self changeSelectionsPath:path];
        }else {
            goto end;
        }
    } else {
        
        end: {
            // show
            
            // hidden
            
            
            self.state = CDFFmpegPlayerPlayState_PlayEnd;
        }
    }
}

- (void)_playFailedState {
    // show
    [self showBackBtn];
    
    // hidden
    
    self.state = CDFFmpegPlayerPlayState_PlayFailed;
    self.playing = NO;
}

- (void)_lockScreenState {
    
    // show
    
    
    // hidden
    
    self.hideControl = YES;
}

- (void)_unlockScreenState {
    
}

- (void)_hideControlState {
    
}

- (void)_showControlState {
    
}

@end

# pragma mark -

@implementation CDFFmpegPlayer (Setting)
- (void)setClickedBackEvent:(void (^)(CDFFmpegPlayer *player))clickedBackEvent {
    objc_setAssociatedObject(self, @selector(clickedBackEvent), clickedBackEvent, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(CDFFmpegPlayer * _Nonnull))clickedBackEvent {
    return objc_getAssociatedObject(self, _cmd);
}

- (float)rate {
    return [objc_getAssociatedObject(self, _cmd) floatValue];
}

- (void)setRate:(float)rate {
    if ( self.rate == rate ) return;
    objc_setAssociatedObject(self, @selector(rate), @(rate), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if ( !self.decoder ) return;
    self.decoder.rate = rate;
    self.userClickedPause = NO;
    _cdAnima(^{
        [self _playState];
    });
    
    if ( self.rateChanged ) self.rateChanged(self);
}

- (void)settingPlayer:(void (^)(CYVideoPlayerSettings * _Nonnull))block {
    [self _addOperation:^(CDFFmpegPlayer *player) {
        if ( block ) block([player settings]);
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:CYSettingsPlayerNotification object:[player settings]];
        });
    }];
}

- (void)setInternallyChangedRate:(void (^)(CDFFmpegPlayer * _Nonnull, float))internallyChangedRate {
    objc_setAssociatedObject(self, @selector(internallyChangedRate), internallyChangedRate, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(CDFFmpegPlayer * _Nonnull, float))internallyChangedRate {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)_clear {
    
}

- (void)dressSetting:(CYVideoPlayerMoreSetting *)setting {
    if ( !setting.clickedExeBlock ) return;
    void(^clickedExeBlock)(CYVideoPlayerMoreSetting *model) = [setting.clickedExeBlock copy];
    __weak typeof(self) _self = self;
    if ( setting.isShowTowSetting ) {
        setting.clickedExeBlock = ^(CYVideoPlayerMoreSetting * _Nonnull model) {
            clickedExeBlock(model);
            __strong typeof(_self) self = _self;
            if ( !self ) return;
        };
        return;
    }
    
    setting.clickedExeBlock = ^(CYVideoPlayerMoreSetting * _Nonnull model) {
        clickedExeBlock(model);
        __strong typeof(_self) self = _self;
        if ( !self ) return;
    };
}

- (NSArray<CYVideoPlayerMoreSetting *> *)moreSettings {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setMoreSettings:(NSArray<CYVideoPlayerMoreSetting *> *)moreSettings {
    objc_setAssociatedObject(self, @selector(moreSettings), moreSettings, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NSMutableSet<CYVideoPlayerMoreSetting *> *moreSettingsM = [NSMutableSet new];
    [moreSettings enumerateObjectsUsingBlock:^(CYVideoPlayerMoreSetting * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self addSetting:obj container:moreSettingsM];
    }];
    
    [moreSettingsM enumerateObjectsUsingBlock:^(CYVideoPlayerMoreSetting * _Nonnull obj, BOOL * _Nonnull stop) {
        [self dressSetting:obj];
    }];
}

- (void)addSetting:(CYVideoPlayerMoreSetting *)setting container:(NSMutableSet<CYVideoPlayerMoreSetting *> *)moreSttingsM {
    [moreSttingsM addObject:setting];
    if ( !setting.showTowSetting ) return;
    [setting.twoSettingItems enumerateObjectsUsingBlock:^(CYVideoPlayerMoreSettingSecondary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self addSetting:(CYVideoPlayerMoreSetting *)obj container:moreSttingsM];
    }];
}

- (CYVideoPlayerSettings *)settings {
    CYVideoPlayerSettings *setting = objc_getAssociatedObject(self, _cmd);
    if ( setting ) return setting;
    setting = [CYVideoPlayerSettings sharedVideoPlayerSettings];
    objc_setAssociatedObject(self, _cmd, setting, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return setting;
}

- (void)resetSetting {
    CYVideoPlayerSettings *setting = self.settings;
    //    setting.backBtnImage = [CYVideoPlayerResources imageNamed:@"cy_video_player_back"];
    //    setting.moreBtnImage = [CYVideoPlayerResources imageNamed:@"cy_video_player_more"];
    setting.backBtnImage = [CYVideoPlayerResources imageNamed:@"cy_video_player_back"];
    setting.moreBtnImage = [CYVideoPlayerResources imageNamed:@"cy_video_player_more"];
    setting.previewBtnImage = [CYVideoPlayerResources imageNamed:@""];
    setting.playBtnImage = [CYVideoPlayerResources imageNamed:@"cy_video_player_play"];
    setting.pauseBtnImage = [CYVideoPlayerResources imageNamed:@"cy_video_player_pause"];
    setting.fullBtnImage_nor = [CYVideoPlayerResources imageNamed:@"cy_video_player_fullscreen_nor"];
    setting.fullBtnImage_sel = [CYVideoPlayerResources imageNamed:@"cy_video_player_fullscreen_sel"];
    setting.lockBtnImage = [CYVideoPlayerResources imageNamed:@"cy_video_player_lock"];
    setting.unlockBtnImage = [CYVideoPlayerResources imageNamed:@"cy_video_player_unlock"];
    setting.replayBtnImage = [CYVideoPlayerResources imageNamed:@"cy_video_player_replay"];
    setting.replayBtnTitle = @"重播";
    setting.progress_traceColor = CYColorWithHEX(0x00c5b5);
    setting.progress_bufferColor = [UIColor colorWithWhite:0 alpha:0.2];
    setting.progress_trackColor =  [UIColor whiteColor];
    //    setting.progress_thumbImage = [CYVideoPlayerResources imageNamed:@"cy_video_player_thumbnail"];
    setting.progress_thumbImage_nor = [CYVideoPlayerResources imageNamed:@"cy_video_player_thumbnail_nor"];
    setting.progress_thumbImage_sel = [CYVideoPlayerResources imageNamed:@"cy_video_player_thumbnail_sel"];
    setting.progress_traceHeight = 3;
    setting.more_traceColor = CYColorWithHEX(0x00c5b5);
    setting.more_trackColor = [UIColor whiteColor];
    setting.more_trackHeight = 5;
    setting.loadingLineColor = [UIColor whiteColor];
    if (setting.title.length <= 0)
    {
        setting.title = @"";
    }
    setting.enableProgressControl = YES;
    
    setting.definitionTypes = CYFFmpegPlayerDefinitionNone;
    setting.enableSelections = NO;
    setting.useHWDecompressor = NO;
}

- (void (^)(CDFFmpegPlayer * _Nonnull))rateChanged {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setRateChanged:(void (^)(CDFFmpegPlayer * _Nonnull))rateChanged {
    objc_setAssociatedObject(self, @selector(rateChanged), rateChanged, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)disableRotation {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setDisableRotation:(BOOL)disableRotation {
    objc_setAssociatedObject(self, @selector(disableRotation), @(disableRotation), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setRotatedScreen:(void (^)(CDFFmpegPlayer * _Nonnull, BOOL))rotatedScreen {
    objc_setAssociatedObject(self, @selector(rotatedScreen), rotatedScreen, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(CDFFmpegPlayer * _Nonnull, BOOL))rotatedScreen {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setControlViewDisplayStatus:(void (^)(CDFFmpegPlayer * _Nonnull, BOOL))controlViewDisplayStatus {
    objc_setAssociatedObject(self, @selector(controlViewDisplayStatus), controlViewDisplayStatus, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(CDFFmpegPlayer * _Nonnull, BOOL))controlViewDisplayStatus {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setAutoplay:(BOOL)autoplay {
    objc_setAssociatedObject(self, @selector(isAutoplay), @(autoplay), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isAutoplay {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

@end

# pragma mark -

@implementation CDFFmpegPlayer (Control)

- (id<CDFFmpegControlDelegate>)control_delegate
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setControl_delegate:(id<CDFFmpegControlDelegate>)control_delegate
{
    objc_setAssociatedObject(self, @selector(control_delegate), control_delegate, OBJC_ASSOCIATION_ASSIGN);
}


- (BOOL)play {
    if (!_decoder) { return NO; }
    self.suspend = NO;
    self.stopped = NO;
    
    //    if ( !self.asset ) return NO;
    self.userClickedPause = NO;
    if ( self.state != CDFFmpegPlayerPlayState_Playing ) {
        _cdAnima(^{
            [self _playState];
        });
    }
    [self _play];
//    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    return YES;
}


- (BOOL)pause {
    if (!_decoder) { return NO; }
    
    self.suspend = YES;
    
    //    if ( !self.asset ) return NO;
    if ( self.state != CDFFmpegPlayerPlayState_Pause ) {
        _cdAnima(^{
            [self _pauseState];
            self.hideControl = NO;
        });
    }
    [self _pause];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    //    if ( self.orentation.fullScreen )
    //    {
    //        [self showTitle:@"已暂停"];
    //    }
    return YES;
}

- (void)stop {
    self.suspend = NO;
    self.stopped = YES;
    [self _stop];
    //    if ( !self.asset ) return;
    if ( self.state != CDFFmpegPlayerPlayState_Unknown ) {
        _cdAnima(^{
            [self _unknownState];
        });
    }
    [self _clear];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void)setLockscreen:(LockScreen)lockscreen
{
    objc_setAssociatedObject(self, @selector(lockscreen), lockscreen, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (LockScreen)lockscreen
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)hideBackBtn {
    
    self.hiddenLeftControlView = YES;
    
    _cdAnima(^{
        self.hideControl = YES;
    });
}

- (void)showBackBtn {

    self.hiddenLeftControlView = YES;
    
    _cdAnima(^{
        self.hideControl = NO;
    });
}

@end

# pragma mark -

@implementation CDFFmpegPlayer (Prompt)

- (CYPrompt *)prompt {
    CYPrompt *prompt = objc_getAssociatedObject(self, _cmd);
    if ( prompt ) return prompt;
    prompt = [CYPrompt promptWithPresentView:self.presentView];
    objc_setAssociatedObject(self, _cmd, prompt, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return prompt;
}

- (void)showTitle:(NSString *)title {
    [self showTitle:title duration:1];
}

- (void)showTitle:(NSString *)title duration:(NSTimeInterval)duration {
    [self.prompt showTitle:title duration:duration];
}

- (void)hiddenTitle {
    [self.prompt hidden];
}

@end
