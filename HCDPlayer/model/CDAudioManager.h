//
//  CDAudioManager.h
//  HcdPlayer
//
//  Created by Salvador on 2020/7/8.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CDAudioManager;

typedef void (^CDAudioManagerOutputBlock)(float *data, UInt32 numFrames, UInt32 numChannels);

@protocol CDAudioManagerDelegate <NSObject>

@end

@protocol CDAudioManager <NSObject>

@property (readonly) UInt32                     numOutputChannels;
@property (readonly) Float64                    samplingRate;
@property (readonly) UInt32                     numBytesPerSample;
@property (readonly) Float32                    outputVolume;
@property (readonly) BOOL                       playing;
@property (readonly, strong) NSString           *audioRoute;

@property (readwrite, copy) CDAudioManagerOutputBlock outputBlock;

@property (nonatomic, readwrite) NSInteger      avcodecContextNumOutputChannels;
@property (nonatomic, readwrite) double         avcodecContextSamplingRate;

@property (nonatomic, weak) id<CDAudioManagerDelegate> delegate;

- (BOOL)activateAudioSession;
- (void)deactivateAudioSession;
- (BOOL)play;
- (void)pause;

@end

@interface CDAudioManager : NSObject

+ (id<CDAudioManager>)audioManager;

@end

NS_ASSUME_NONNULL_END
