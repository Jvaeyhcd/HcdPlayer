//
//  HCDPlayerDecoder.h
//  HCDPlayer
//
//  Created by Jvaeyhcd on 05/12/2019.
//  Copyright © 2016 Jvaeyhcd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HCDPlayerDecoder : NSObject

@property (nonatomic) BOOL isYUV;
@property (nonatomic) BOOL hasVideo;
@property (nonatomic) BOOL hasAudio;
@property (nonatomic) BOOL hasPicture;
@property (nonatomic) BOOL isEOF;

@property (nonatomic) double rotation;
@property (nonatomic) double duration;
@property (nonatomic, strong) NSDictionary *metadata;

@property (nonatomic) UInt32 audioChannels;
@property (nonatomic) float audioSampleRate;

@property (nonatomic) double videoFPS;
@property (nonatomic) double videoTimebase;
@property (nonatomic) double audioTimebase;

- (BOOL)open:(NSString *)url error:(NSError **)error;
- (void)close;
- (void)prepareClose;
- (NSArray *)readFrames;
- (void)seek:(double)position;
- (int)videoWidth;
- (int)videoHeight;
- (BOOL)isYUV;

@end
