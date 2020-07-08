//
//  CDPlayerDecoder.h
//  HcdPlayer
//
//  Created by Salvador on 2020/6/24.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CDHardwareVideoDecompress.h"

NS_ASSUME_NONNULL_BEGIN

extern NSInteger CDPlayerDecoderConCurrentThreadCount;// range:1 - 5

extern NSInteger CDPlayerDecoderMaxFPS;

extern NSString * CDPlayerErrorDomain;

extern int ffmpeg_main(int argc, char * _Nonnull argv[_Nullable]);

typedef BOOL(^CDPlayerDecoderInterruptCallback)(void);

typedef enum {
    
    CDPlayerErrorNone,
    CDPlayerErrorOpenFile,
    CDPlayerErrorStreamInfoNotFound,
    CDPlayerErrorStreamNotFound,
    CDPlayerErrorCodecNotFound,
    CDPlayerErrorOpenCodec,
    CDPlayerErrorAllocateFrame,
    CDPlayerErrorSetupScaler,
    CDPlayerErrorSampler,
    CDPlayerErrorUnsupported,
    CDPlayerErrorOpenFilter
    
} CDPlayerError;

typedef enum {
    
    CDPlayerFrameTypeAudio,
    CDPlayerFrameTypeVideo,
    CDPlayerFrameTypeArtwork,
    CDPlayerFrameTypeSubtitle,
    
} CDPlayerFrameType;

typedef enum {
    
    CDVideoFrameFormatRGB,
    CDVideoFrameFormatYUV,
    
} CDVideoFrameFormat;

typedef enum {
    
    CDPlayerFilter_FILTER_NULL,
    CDPlayerFilter_FILTER_MIRROR,
    CDPlayerFilter_FILTER_WATERMARK,
    CDPlayerFilter_FILTER_NEGATE,
    CDPlayerFilter_FILTER_EDGE,
    CDPlayerFilter_FILTER_SPLIT4,
    CDPlayerFilter_FILTER_VINTAGE,
    CDPlayerFilter_FILTER_BRIGHTNESS,
    CDPlayerFilter_FILTER_CONTRAST,
    CDPlayerFilter_FILTER_SATURATION,
    CDPlayerFilter_FILTER_EQ,
    CDPlayerFilter_FILTER_TEST

} CDPlayerFilterType;

struct CDPixelBufferBytesPerRowOfPlane {
    size_t yBytes;
    size_t cbBytes;
    size_t crBytes;
};

@interface CDPlayerFrame : NSObject

@property (readonly, nonatomic) CDPlayerFrameType type;

@property (readonly, nonatomic) CGFloat position;

@property (readonly, nonatomic) CGFloat duration;

@end

@interface CDAudioFrame : CDPlayerFrame

@property (readonly, nonatomic, strong) NSData *samples;

@end

@interface CDVideoFrame : CDPlayerFrame

@property (readonly, nonatomic) CDVideoFrameFormat format;

@property (readonly, nonatomic) NSUInteger width;

@property (readonly, nonatomic) NSUInteger height;

@end

@interface CDVideoFrameRGB : CDVideoFrame

@property (readonly, nonatomic) NSUInteger linesize;

@property (readonly, nonatomic, strong) NSData *rgb;

- (UIImage *)asImage;

@end

@interface CDVideoFrameYUV : CDVideoFrame

@property (readonly, nonatomic, strong) NSData *luma;

@property (readonly, nonatomic, strong) NSData *chromaB;

@property (readonly, nonatomic, strong) NSData *chromaR;

@property (readonly, nonatomic, assign) CVPixelBufferRef pixelBuffer;

@property (readwrite, nonatomic, assign) struct CDPixelBufferBytesPerRowOfPlane bytesPerRowOfPlans;

@end

@interface CDArtworkFrame : CDPlayerFrame

@property (readonly, nonatomic, strong) NSData *picture;

- (UIImage *)asImage;

@end

@interface CDSubtitleFrame : CDPlayerFrame

@property (readonly, nonatomic, strong) NSString *text;

@end

typedef enum {
    
    CDVideoDecodeTypeNone = 0,
    CDVideoDecodeTypeVideo = 1 << 0,
    CDVideoDecodeTypeAudio = 1 << 1,
    
} CDVideoDecodeType;

typedef void(^CDPlayerCompeletionDecode)(NSArray<CDPlayerFrame *> *frames, BOOL compeleted);
typedef void(^CDPlayerCompeletionThread)(NSArray<CDPlayerFrame *> *frames);

@interface CDPlayerDecoder : NSObject

@property (readonly, nonatomic, strong) NSString *path;

@property (readonly, nonatomic) BOOL isEOF;

@property (readwrite, nonatomic) CGFloat position;

// 每次快进重置这个值，目的是为了把上次没快进完成的进程结束掉
@property (readwrite, nonatomic) CGFloat targetPosition;

@property (readonly, nonatomic) CGFloat duration;

@property (readonly, nonatomic) CGFloat fps;

@property (readonly, nonatomic) CGFloat sampleRate;

// 设置解码播放速度，0.5-2.0
@property (readwrite, nonatomic) CGFloat rate;

// 是否开启硬件解码，只支持h264
@property (readwrite, nonatomic, assign) BOOL useHardwareDecompressor;

@property (readonly, nonatomic) NSUInteger frameWidth;

@property (readonly, nonatomic) NSUInteger frameHeight;

@property (readonly, nonatomic) NSUInteger audioStreamsCount;

@property (readwrite,nonatomic) NSInteger selectedAudioStream;

@property (readonly, nonatomic) NSUInteger subtitleStreamsCount;

@property (readwrite,nonatomic) NSInteger selectedSubtitleStream;

@property (readonly, nonatomic) BOOL validVideo;

@property (readonly, nonatomic) BOOL validAudio;

@property (readonly, nonatomic) BOOL validSubtitles;

@property (readonly, nonatomic) BOOL validFilter;

@property (readonly, nonatomic, strong) NSDictionary *info;

@property (readonly, nonatomic, strong) NSString *videoStreamFormatName;

@property (readonly, nonatomic) BOOL isNetwork;

@property (readonly, nonatomic) CGFloat startTime;

@property (readwrite, nonatomic) BOOL disableDeinterlacing;

@property (readonly, nonatomic, strong) CDHardwareVideoDecompress *hwDecompressor;

@property (readwrite, nonatomic, strong) CDPlayerDecoderInterruptCallback interruptCallback;

@property (nonatomic, readwrite, assign) CDVideoDecodeType decodeType;

+ (id)movieDecodeWithContentPath:(NSString *)path
                           error:(NSError **)perror;

- (void)closeFile;

- (void)flush;

- (BOOL)setupVideoFrameFormat:(CDVideoFrameFormat)format;

- (CDVideoFrameFormat)getVideoFrameFormat;

- (NSArray *)decodeFrames:(CGFloat)minDuration;

- (NSArray *)decodeTargetFrames:(CGFloat)minDuration targetPos:(CGFloat)targetPos;

- (void)concurrentDecodeFrrames:(CGFloat)minDuration compeletionHandler:(CDPlayerCompeletionDecode)compeletion;

- (void)asyncDecodeFrames:(CGFloat)minDuration targetPosition:(CGFloat)targetPos compeletionHandler:(CDPlayerCompeletionDecode)compeletion;

- (void)generatedPreviewImagesWithImagesCount:(NSInteger)count
                            completionHandler:(void (^)(NSMutableArray * frames, NSError * error))handler;

@end

@interface CDPlayerSubtitleASSParser : NSObject

+ (NSArray *)parseEvents:(NSString *)events;

+ (NSArray *)parseDialogue:(NSString *)dialogue numFields:(NSUInteger)numFields;

+ (NSString *)removeCommandsFromEventText:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
