//
//  CDAudioManager.m
//  HcdPlayer
//
//  Created by Salvador on 2020/7/8.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import "CDAudioManager.h"
#import "TargetConditionals.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>
#import "CDLogger.h"

#define MAX_FRAME_SIZE          4096
#define MAX_CHAN                2
#define MAX_SAMPLE_DUMPED       5

static BOOL checkError(OSStatus error, const char *operation);
static OSStatus renderCallback (void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp * inTimeStamp, UInt32 inOutputBusNumber, UInt32 inNumberFrames, AudioBufferList* ioData);

@interface CDAudioManagerImpl : CDAudioManager<CDAudioManager> {
    
    BOOL                        _initialized;
    BOOL                        _activated;
    float                       *_outData;
    AudioUnit                   _audioUnit;
    AudioStreamBasicDescription _outputFormat;
}

@property (readonly) UInt32                         numOutputChannels;
@property (readonly) Float64                        samplingRate;
@property (readonly) UInt32                         numBytesPerSample;
@property (nonatomic, readwrite) Float32            outputVolume;
@property (readonly) BOOL                           playing;
@property (readonly, strong) NSString               *audioRoute;

@property (readwrite, copy) CDAudioManagerOutputBlock outputBlock;
@property (readwrite) BOOL playAfterSessionEndInterruption;

@property (nonatomic, readwrite) NSInteger          avcodecContextNumOutputChannels;
@property (nonatomic, readwrite) double             avcodecContextSamplingRate;

@property (nonatomic, weak) id<CDAudioManagerDelegate> delegate;


- (void)deactivateAudioSession;
- (BOOL)play;
- (void)pause;

- (BOOL)setupAudio;
- (BOOL)renderFrames:(UInt32)numFrames
              ioData:(AudioBufferList *)ioData;

@end

@implementation CDAudioManager

+ (id<CDAudioManager>)audioManager {
    
    static CDAudioManagerImpl *audioManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        audioManager = [[CDAudioManagerImpl alloc] init];
    });
    return audioManager;
}

@end

@implementation CDAudioManagerImpl

- (instancetype)init
{
    self = [super init];
    if (self) {
        _outData = (float *)calloc(MAX_FRAME_SIZE * MAX_CHAN, sizeof(float));
        _outputVolume = 0.5;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionInterrupted:) name:AVAudioSessionInterruptionNotification object:nil];
    }
    return self;
}

#pragma mark - private

// Debug: dump the current frame data. Limited to 20 samples.

#define dumpAudioSamples(prefix, dataBuffer, samplePrintFormat, sampleCount, channelCount) \
{ \
NSMutableString *dump = [NSMutableString stringWithFormat:prefix]; \
for (int i = 0; i < MIN(MAX_SAMPLE_DUMPED, sampleCount); i++) \
{ \
for (int j = 0; j < channelCount; j++) \
{ \
[dump appendFormat:samplePrintFormat, dataBuffer[j + i * channelCount]]; \
} \
[dump appendFormat:@"\n"]; \
} \
LoggerAudio(3, @"%@", dump); \
}

#define dumpAudioSamplesNonInterleaved(prefix, dataBuffer, samplePrintFormat, sampleCount, channelCount) \
{ \
NSMutableString *dump = [NSMutableString stringWithFormat:prefix]; \
for (int i = 0; i < MIN(MAX_SAMPLE_DUMPED, sampleCount); i++) \
{ \
for (int j = 0; j < channelCount; j++) \
{ \
[dump appendFormat:samplePrintFormat, dataBuffer[j][i]]; \
} \
[dump appendFormat:@"\n"]; \
} \
LoggerAudio(3, @"%@", dump); \
}

- (BOOL)setupAudio {
    
    // ----- Audio Unit Setup -----
    
    // Describe the output unit.
    
    AudioComponentDescription description = {0};
    description.componentType = kAudioUnitType_Output;
    description.componentSubType = kAudioUnitSubType_RemoteIO;
    description.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // Get component
    AudioComponent component = AudioComponentFindNext(NULL, &description);
    if (checkError(AudioComponentInstanceNew(component, &_audioUnit),
                   "Couldn't create the output audio unit"))
        return NO;
    
    UInt32 size;
    
    // Check the output stream format
    size = sizeof(AudioStreamBasicDescription);
    if (checkError(AudioUnitGetProperty(_audioUnit,
                                        kAudioUnitProperty_StreamFormat,
                                        kAudioUnitScope_Input,
                                        0,
                                        &_outputFormat,
                                        &size),
                   "Couldn't get the hardware output stream format"))
        return NO;
    
    
    _outputFormat.mSampleRate = self.samplingRate;
    if (checkError(AudioUnitSetProperty(_audioUnit,
                                        kAudioUnitProperty_StreamFormat,
                                        kAudioUnitScope_Input,
                                        0,
                                        &_outputFormat,
                                        size),
                   "Couldn't set the hardware output stream format")) {
        
        // just warning
    }
    
    _numBytesPerSample = _outputFormat.mBitsPerChannel / 8;
    
    LoggerAudio(2, @"Current output bytes per sample: %u", (unsigned int)_numBytesPerSample);
    LoggerAudio(2, @"Current output num channels: %u", (unsigned int)self.numOutputChannels);
    
    // Slap a render callback on the unit
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = renderCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    
    if (checkError(AudioUnitSetProperty(_audioUnit,
                                        kAudioUnitProperty_SetRenderCallback,
                                        kAudioUnitScope_Input,
                                        0,
                                        &callbackStruct,
                                        sizeof(callbackStruct)),
                   "Couldn't set the render callback on the audio unit"))
        return NO;
    
    if (checkError(AudioUnitInitialize(_audioUnit),
                   "Couldn't initialize the audio unit"))
        return NO;
    
    return YES;
}

- (BOOL)renderFrames:(UInt32)numFrames
              ioData:(AudioBufferList *)ioData {
    
    for (int iBuffer=0; iBuffer < ioData->mNumberBuffers; ++iBuffer) {
        memset(ioData->mBuffers[iBuffer].mData, 0, ioData->mBuffers[iBuffer].mDataByteSize);
    }
    
    if (_playing && _outputBlock ) {
        
        // Collect data to render from the callbacks
        _outputBlock(_outData, numFrames, self.numOutputChannels);
        
        // Put the rendered data into the output buffer
        if (_numBytesPerSample == 4) // then we've already got floats
        {
            float zero = 0.0;
            
            for (int iBuffer=0; iBuffer < ioData->mNumberBuffers; ++iBuffer) {
                
                int thisNumChannels = ioData->mBuffers[iBuffer].mNumberChannels;
                
                for (int iChannel = 0; iChannel < thisNumChannels; ++iChannel) {
                    vDSP_vsadd(_outData+iChannel, self.numOutputChannels, &zero, (float *)ioData->mBuffers[iBuffer].mData, thisNumChannels, numFrames);
                }
            }
        }
        else if (_numBytesPerSample == 2) // then we need to convert SInt16 -> Float (and also scale)
        {
            //            dumpAudioSamples(@"Audio frames decoded by FFmpeg:\n",
            //                             _outData, @"% 12.4f ", numFrames, _numOutputChannels);
            
            float scale = (float)INT16_MAX;
            vDSP_vsmul(_outData, 1, &scale, _outData, 1, numFrames * self.numOutputChannels);
            
#ifdef DUMP_AUDIO_DATA
            LoggerAudio(2, @"Buffer %u - Output Channels %u - Samples %u",
                        (uint)ioData->mNumberBuffers, (uint)ioData->mBuffers[0].mNumberChannels, (uint)numFrames);
#endif
            
            for (int iBuffer=0; iBuffer < ioData->mNumberBuffers; ++iBuffer) {
                
                int thisNumChannels = ioData->mBuffers[iBuffer].mNumberChannels;
                
                for (int iChannel = 0; iChannel < thisNumChannels; ++iChannel) {
                    vDSP_vfix16(_outData+iChannel, self.numOutputChannels, (SInt16 *)ioData->mBuffers[iBuffer].mData+iChannel, thisNumChannels, numFrames);
                }
#ifdef DUMP_AUDIO_DATA
                dumpAudioSamples(@"Audio frames decoded by FFmpeg and reformatted:\n",
                                 ((SInt16 *)ioData->mBuffers[iBuffer].mData),
                                 @"% 8d ", numFrames, thisNumChannels);
#endif
            }
            
        }
    }
    
    return noErr;
}

#pragma mark - public

- (BOOL)activateAudioSession {
    
    if (!_activated) {
        
        if (!_initialized) {
            NSError * error = nil;
            [[AVAudioSession sharedInstance] setActive:YES error:&error];
            if (error) {
                return NO;
            }
            _initialized = YES;
        }
        
        if ([self setupAudio]) {
            _activated = YES;
        }
    }
    
    return _activated;
}

- (void)deactivateAudioSession {
    if (_activated) {
        
        [self pause];
        
        checkError(AudioUnitUninitialize(_audioUnit),
                   "Couldn't uninitialize the audio unit");
        
        /*
         fails with error (-10851) ?
         
         checkError(AudioUnitSetProperty(_audioUnit,
         kAudioUnitProperty_SetRenderCallback,
         kAudioUnitScope_Input,
         0,
         NULL,
         0),
         "Couldn't clear the render callback on the audio unit");
         */
        
        checkError(AudioComponentInstanceDispose(_audioUnit),
                   "Couldn't dispose the output audio unit");
        
        //        checkError(AudioSessionSetActive(NO),
        //                   "Couldn't deactivate the audio session");
        NSError * error = nil;
        [[AVAudioSession sharedInstance] setActive:NO error:&error];
        if (error) {
            NSLog(@"Couldn't deactivate the audio session");
        }
        
        _activated = NO;
    }
}

- (void)pause {
    if (_playing) {
        _playing = checkError(AudioOutputUnitStop(_audioUnit), "Couldn't stop the output unit");
    }
}

- (BOOL)play {
    if (!_playing) {
        if ([self activateAudioSession]) {
            _playing = !checkError(AudioOutputUnitStart(_audioUnit), "Couldn't start the output unit");
        }
    }
    return _playing;
}

#pragma mark - getter

- (Float64)samplingRate {
    
    double result = [AVAudioSession sharedInstance].sampleRate;
    if (self.avcodecContextSamplingRate) {
        return self.avcodecContextSamplingRate;
    }
    return result;
}

- (UInt32)numOutputChannels {
    
    double result = [AVAudioSession sharedInstance].outputNumberOfChannels;
    if (self.avcodecContextNumOutputChannels) {
        return (UInt32)(self.avcodecContextNumOutputChannels);
    }
    return result;
}

- (Float32)outputVolume {
    
    double result = [AVAudioSession sharedInstance].outputVolume;
    return result;
}

#pragma mark - AVAudioSessionNotification

- (void)audioSessionInterrupted:(NSNotification *)notification {
    //通知类型
    NSNumber *interruptionType = [[notification userInfo] objectForKey:AVAudioSessionInterruptionTypeKey];
    AVAudioSessionInterruptionOptions options = [AVAudioSessionInterruptionOptionKey integerValue];
    switch (interruptionType.unsignedIntegerValue) {
            
        case AVAudioSessionInterruptionTypeBegan:{
            LoggerAudio(2, @"Begin interuption");
            self.playAfterSessionEndInterruption = self.playing;
            [self pause];
        }
            break;
        case AVAudioSessionInterruptionTypeEnded:{
            if (options == AVAudioSessionInterruptionOptionShouldResume) {
                //触发重新播放
                LoggerAudio(2, @"End interuption");
                if (self.playAfterSessionEndInterruption) {
                    self.playAfterSessionEndInterruption = NO;
                    [self play];
                }
            }
            
        }
            break;
        default:
            break;
    }
    
}

@end

#pragma mark - callbacks

static OSStatus renderCallback (void                              *inRefCon,
                                AudioUnitRenderActionFlags        *ioActionFlags,
                                const AudioTimeStamp              *inTimeStamp,
                                UInt32                            inOutputBusNumber,
                                UInt32                            inNumberFrames,
                                AudioBufferList                   *ioData) {
    CDAudioManagerImpl *sm = (__bridge CDAudioManagerImpl *)inRefCon;
    return [sm renderFrames:inNumberFrames ioData:ioData];
}

static BOOL checkError(OSStatus error, const char *operation) {
    
    if (error == noErr)
        return NO;
    
    char str[20] = {0};
    // see if it appears to be a 4-char-code
    *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
    if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
        str[0] = str[5] = '\'';
        str[6] = '\0';
    } else
        // no, format it as an integer
        sprintf(str, "%d", (int)error);
    
    LoggerStream(0, @"Error: %s (%s)\n", operation, str);
    
    //exit(1);
    
    return YES;
}

