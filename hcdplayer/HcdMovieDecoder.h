//
//  HcdMovieDecoder.h
//  HcdPlayer
//
//  Created by Salvador on 2019/1/15.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * HcdmovieErrorDomain;

typedef enum {
    
    HcdMovieErrorNone,
    HcdMovieErrorOpenFile,
    HcdMovieErrorStreamInfoNotFound,
    HcdMovieErrorStreamNotFound,
    HcdMovieErrorCodecNotFound,
    HcdMovieErrorOpenCodec,
    HcdMovieErrorAllocateFrame,
    HcdMovieErroSetupScaler,
    HcdMovieErroReSampler,
    HcdMovieErroUnsupported,
    
} HcdMovieError;

typedef enum {
    
    HcdMovieFrameTypeAudio,
    HcdMovieFrameTypeVideo,
    HcdMovieFrameTypeArtwork,
    HcdMovieFrameTypeSubtitle,
    
} HcdMovieFrameType;

typedef enum {
    
    HcdVideoFrameFormatRGB,
    HcdVideoFrameFormatYUV,
    
} HcdVideoFrameFormat;

// 视频的信息
@interface HcdMovieInfo : NSObject

// 封面
@property (nonatomic, strong) UIImage           *coverImage;
// 字符串时长
@property (nonatomic, strong) NSString          *durationStr;
// 视频时长，单位秒
@property (nonatomic, assign) CGFloat           duration;

@end

@interface HcdMovieFrame: NSObject
@property (readonly, nonatomic) HcdMovieFrameType type;
@property (readonly, nonatomic) CGFloat position;
@property (readonly, nonatomic) CGFloat duration;
@end

@interface HcdAudioFrame: HcdMovieFrame
@property (readonly, nonatomic, strong) NSData *samples;
@end

@interface HcdVideoFrame: HcdMovieFrame
@property (readonly, nonatomic) HcdVideoFrameFormat format;
@property (readonly, nonatomic) NSUInteger width;
@property (readonly, nonatomic) NSUInteger height;
@end

@interface HcdVideoFrameRGB: HcdVideoFrame
@property (readonly, nonatomic) NSUInteger linesize;
@property (readonly, nonatomic, strong) NSData *rgb;
- (UIImage *)asImage;
@end

@interface HcdVideoFrameYUV: HcdVideoFrame
@property (readonly, nonatomic, strong) NSData *luma;
@property (readonly, nonatomic, strong) NSData *chromaB;
@property (readonly, nonatomic, strong) NSData *chromaR;
@end

@interface HcdArtworkFrame: HcdMovieFrame
@property (readonly, nonatomic, strong) NSData *picture;
- (UIImage *)asImage;
@end

@interface HcdSubtitleFrame: HcdMovieFrame
@property (readonly, nonatomic, strong) NSString *text;
@end

typedef BOOL(^HcdMovieDecoderInterruptCallback)(void);

@interface HcdMovieDecoder: NSObject

@property (readonly, nonatomic, strong) NSString *path;
@property (readonly, nonatomic) BOOL isEOF;
@property (readwrite,nonatomic) CGFloat position;
@property (readonly, nonatomic) CGFloat duration;
@property (readonly, nonatomic) CGFloat fps;
@property (readonly, nonatomic) CGFloat sampleRate;
@property (readonly, nonatomic) NSUInteger frameWidth;
@property (readonly, nonatomic) NSUInteger frameHeight;
@property (readonly, nonatomic) NSUInteger audioStreamsCount;
@property (readwrite,nonatomic) NSInteger selectedAudioStream;
@property (readonly, nonatomic) NSUInteger subtitleStreamsCount;
@property (readwrite,nonatomic) NSInteger selectedSubtitleStream;
@property (readonly, nonatomic) BOOL validVideo;
@property (readonly, nonatomic) BOOL validAudio;
@property (readonly, nonatomic) BOOL validSubtitles;
@property (readonly, nonatomic, strong) NSDictionary *info;
@property (readonly, nonatomic, strong) NSString *videoStreamFormatName;
@property (readonly, nonatomic) BOOL isNetwork;
@property (readonly, nonatomic) CGFloat startTime;
@property (readwrite, nonatomic) BOOL disableDeinterlacing;
@property (readwrite, nonatomic, strong) HcdMovieDecoderInterruptCallback interruptCallback;

+ (id)movieDecoderWithContentPath:(NSString *)path
                            error:(NSError **)perror;

- (BOOL)openFile:(NSString *)path
           error:(NSError **)perror;

- (void)closeFile;

- (BOOL)setupVideoFrameFormat:(HcdVideoFrameFormat)format;

- (NSArray *)decodeFrames:(CGFloat)minDuration;

+ (HcdMovieInfo *)videoInfoWithContentPath:(NSString *)path;

@end

@interface HcdMovieSubtitleASSParser: NSObject

+ (NSArray *)parseEvents: (NSString *)events;
+ (NSArray *)parseDialogue: (NSString *)dialogue
                  numFields: (NSUInteger)numFields;
+ (NSString *)removeCommandsFromEventText: (NSString *)text;

@end


NS_ASSUME_NONNULL_END
