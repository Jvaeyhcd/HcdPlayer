//
//  HCDPlayerAudioManager.h
//  HCDPlayer
//
//  Created by Jvaeyhcd on 08/12/2019.
//  Copyright © 2016 Jvaeyhcd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^HCDPlayerAudioManagerFrameReaderBlock)(float *data, UInt32 num, UInt32 channels);

@interface HCDPlayerAudioManager : NSObject

@property (nonatomic, copy) HCDPlayerAudioManagerFrameReaderBlock frameReaderBlock;
@property (nonatomic) float volume;

- (BOOL)open:(NSError **)error;
- (BOOL)play;
- (BOOL)play:(NSError **)error;
- (BOOL)pause;
- (BOOL)pause:(NSError **)error;
- (BOOL)close;
- (BOOL)close:(NSArray<NSError *> **)errors;

- (double)sampleRate;
- (UInt32)channels;

@end
