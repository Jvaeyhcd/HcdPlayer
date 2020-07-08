//
//  CDPlayerDecoder.m
//  HcdPlayer
//
//  Created by Salvador on 2020/6/24.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import "CDPlayerDecoder.h"
#import <libavformat/avformat.h>

#define CDDocumentDir [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
#define CDBundlePath(res) [[NSBundle mainBundle] pathForResource:res ofType:nil]
#define CDDocumentPath(res) [CDDocumentDir stringByAppendingPathComponent:res]

//#define USE_OPENAL @"UseCYPCMAudioManager"

#define USE_AUDIOTOOL @"UseCYAudioManager"

NSString * CDPlayerErrorDomain = @"com.jvaeyhcd.hcdplayer";
NSInteger CDPlayerDecoderMaxFPS = 26;
NSInteger CDPlayerDecoderConCurrentThreadCount = 1; // range: 1 - 5

# pragma mark - struct CDPicture

typedef struct CDPicture {
    uint8_t *data[AV_NUM_DATA_POINTERS];    // pointers to the image data planes
    int linesize[AV_NUM_DATA_POINTERS];     // number of bytes per line
} CDPicture;

int cdpicture_alloc(CDPicture *picture, enum AVPixelFormat pix_fmt, int width, int height) {
    int ret = av_image_alloc(picture->data, picture->linesize, width, height, pix_fmt, 1);
    if (ret < 0) {
        memset(picture, 0, sizeof(CDPicture));
        return ret;
    }
    return 0;
}

@implementation CDPlayerDecoder

@end
