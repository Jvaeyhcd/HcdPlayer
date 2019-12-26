//
//  HCDPlayerDef.h
//  HCDPlayer
//
//  Created by Jvaeyhcd on 05/12/2019.
//  Copyright © 2016 Jvaeyhcd. All rights reserved.
//

#ifndef HCDPlayerDef_h
#define HCDPlayerDef_h

#define HCDPlayerLocalizedStringTable   @"HCDPlayerStrings"

#define HCDPlayerMinBufferDuration  2
#define HCDPlayerMaxBufferDuration  5

#define HCDPlayerErrorDomainDecoder         @"HCDPlayerDecoder"
#define HCDPlayerErrorDomainAudioManager    @"HCDPlayerAudioManager"

#define HCDPlayerErrorCodeInvalidURL                        -1
#define HCDPlayerErrorCodeCannotOpenInput                   -2
#define HCDPlayerErrorCodeCannotFindStreamInfo              -3
#define HCDPlayerErrorCodeNoVideoAndAudioStream             -4

#define HCDPlayerErrorCodeNoAudioOuput                      -5
#define HCDPlayerErrorCodeNoAudioChannel                    -6
#define HCDPlayerErrorCodeNoAudioSampleRate                 -7
#define HCDPlayerErrorCodeNoAudioVolume                     -8
#define HCDPlayerErrorCodeCannotSetAudioCategory            -9
#define HCDPlayerErrorCodeCannotSetAudioActive              -10
#define HCDPlayerErrorCodeCannotInitAudioUnit               -11
#define HCDPlayerErrorCodeCannotCreateAudioComponent        -12
#define HCDPlayerErrorCodeCannotGetAudioStreamDescription   -13
#define HCDPlayerErrorCodeCannotSetAudioRenderCallback      -14
#define HCDPlayerErrorCodeCannotUninitAudioUnit             -15
#define HCDPlayerErrorCodeCannotDisposeAudioUnit            -16
#define HCDPlayerErrorCodeCannotDeactivateAudio             -17
#define HCDPlayerErrorCodeCannotStartAudioUnit              -18
#define HCDPlayerErrorCodeCannotStopAudioUnit               -19

#pragma mark - Notification
#define HCDPlayerNotificationOpened                 @"HCDPlayerNotificationOpened"
#define HCDPlayerNotificationClosed                 @"HCDPlayerNotificationClosed"
#define HCDPlayerNotificationEOF                    @"HCDPlayerNotificationEOF"
#define HCDPlayerNotificationBufferStateChanged     @"HCDPlayerNotificationBufferStateChanged"
#define HCDPlayerNotificationError                  @"HCDPlayerNotificationError"

#pragma mark - Notification Key
#define HCDPlayerNotificationBufferStateKey         @"HCDPlayerNotificationBufferStateKey"
#define HCDPlayerNotificationSeekStateKey           @"HCDPlayerNotificationSeekStateKey"
#define HCDPlayerNotificationErrorKey               @"HCDPlayerNotificationErrorKey"
#define HCDPlayerNotificationRawErrorKey            @"HCDPlayerNotificationRawErrorKey"

#endif /* HCDPlayerDef_h */
