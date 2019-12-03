//
//  HcdAudioManager.h
//  HcdPlayer
//
//  Created by Salvador on 2019/1/15.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^HcdAudioManagerOutputBlock)(float *data, UInt32 numFrames, UInt32 numChannels);

@protocol HcdAudioManager <NSObject>

@property (readonly) UInt32             numOutputChannels;
@property (readonly) Float64            samplingRate;
@property (readonly) UInt32             numBytesPerSample;
@property (readonly) Float32            outputVolume;
@property (readonly) BOOL               playing;
@property (readonly, strong) NSString   *audioRoute;

@property (readwrite, copy) HcdAudioManagerOutputBlock outputBlock;

- (BOOL)activateAudioSession;
- (void)deactivateAudioSession;
- (BOOL)play;
- (void)pause;

@end

@interface HcdAudioManager : NSObject
+ (id<HcdAudioManager>) audioManager;
@end

NS_ASSUME_NONNULL_END
