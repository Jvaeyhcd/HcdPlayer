//
//  CDHardwareVideoDecompress.h
//  HcdPlayer
//
//  Created by Salvador on 2020/6/24.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import "libavformat/avformat.h"

NS_ASSUME_NONNULL_BEGIN

typedef struct _NALUnit {
    unsigned int type;
    unsigned int size;
    unsigned char *data;
    int64_t pts;
    int64_t dts;
    int64_t duration;
}NALUnit;

typedef enum {
    NALUTypeBPFrame = 0x01,
    NALUTypeIFrame = 0x05,
    NALUTypeSPS = 0x07,
    NALUTypePPS = 0x08
}NALUType;

/// 定义硬件解码完成block
typedef void(^CDHardwareDecompressCompleted)(CVPixelBufferRef imageBuffer, int64_t pkt_pts, int64_t pkt_duration);

@interface CDHardwareVideoDecompress : NSObject

- (id)init;

- (BOOL)takePicture:(NSString *)fileName;

- (CVPixelBufferRef)deCompressedCMSampleBufferWithData:(AVPacket*)packet andOffset:(int)offset;

- (id)initWithCodecCtx:(AVCodecContext *)codecCtx;

/// AVPacket中没有分隔符编码0x00000001的情况下使用
/// @param packet 压缩的视频数据包
/// @param completed 解码完成block
- (void)decompressWithPacket:(AVPacket *)packet completed:(CDHardwareDecompressCompleted)completed;

@end

NS_ASSUME_NONNULL_END
