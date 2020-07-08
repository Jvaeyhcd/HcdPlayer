//
//  CDHardwareVideoDecompress.m
//  HcdPlayer
//
//  Created by Salvador on 2020/6/24.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import "CDHardwareVideoDecompress.h"

@implementation CDHardwareVideoDecompress {
    uint8_t *_sps;
    uint8_t *_pps;
    
    BOOL _isTakePicture;
    BOOL _isSaveTakePictureImage;
    NSString *_saveTakePicturePath;
    
    unsigned int _spsSize;
    unsigned int _ppsSize;
    
    int64_t mCurrentVideoSeconds;
    VTDecompressionSessionRef _decompressionSession;
    CMVideoFormatDescriptionRef _decompressionFormatDesc;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _isTakePicture = NO;
    }
    return self;
}

- (BOOL)takePicture:(NSString *)fileName {
    _isTakePicture = YES;
    _isSaveTakePictureImage = NO;
    _saveTakePicturePath = fileName;
    
    while (_isSaveTakePictureImage == NO) {
        // Just waiting "_isSaveTakePictureImage" become YES
    }
    _isTakePicture = NO;
    return YES;
}

- (CVPixelBufferRef)deCompressedCMSampleBufferWithData:(AVPacket *)packet andOffset:(int)offset {
    NALUnit nalUnit;
    CVPixelBufferRef pixelBufferRef = NULL;
    char *data = (char *)packet->data;
    int dataLen = packet->size;
    
    if (data == NULL || dataLen == 0) {
        return NULL;
    }
    
    // H264 start code
    if ((data[0] != 0x00 ||
         data[1] != 0x00 ||
         data[2] != 0x00 ||
         data[3] != 0x01)) {
        data[0] = 0x00;
        data[1] = 0x00;
        data[2] = 0x00;
        data[3] = 0x01;
    }
    
    while ([self nalunitWithData:data andDataLen:dataLen andOffset:offset toNALUnit:&nalUnit]) {
        if (nalUnit.data == NULL || nalUnit.size == 0) {
            return NULL;
        }
        
        pixelBufferRef = NULL;
        [self infalteStartCodeWithNalunitData:&nalUnit];
        NSLog(@"NALUint Type: %d.", nalUnit.type);
        
        switch (nalUnit.type) {
            case NALUTypeIFrame: // IFrame
                if (_sps && _pps) {
                    if ([self initH264Decoder]) {
                        pixelBufferRef = [self decompressWithAVPacket:packet];
                        NSLog(@"NALUint I Frame size:%d", nalUnit.size);
                        
                        free(_sps);
                        free(_pps);
                        _pps = NULL;
                        _sps = NULL;
                        return pixelBufferRef;
                    }
                }
                break;
            case NALUTypeSPS: // SPS
                _spsSize = nalUnit.size - 4;
                if (_spsSize <= 0) {
                    return NULL;
                }
                
                _sps = (uint8_t*)malloc(_spsSize);
                memcpy(_sps, nalUnit.data + 4, _spsSize);
                NSLog(@"NALUint SPS size:%d", nalUnit.size - 4);
                
                break;
            case NALUTypePPS: // PPS
                _ppsSize = nalUnit.size - 4;
                if (_ppsSize <= 0) {
                    return NULL;
                }
                
                _pps = (uint8_t*)malloc(_ppsSize);
                memcpy(_pps, nalUnit.data + 4, _ppsSize);
                NSLog(@"NALUint PPS size:%d", nalUnit.size - 4);
                break;
            case NALUTypeBPFrame://B/P Frame
                pixelBufferRef = [self decompressWithAVPacket:packet];
                NSLog(@"NALUint B/P Frame size:%d", nalUnit.size);
                return pixelBufferRef;
                break;
            default:
                break;
        }
        
        offset += nalUnit.size;
        if (offset >= dataLen) {
            return NULL;
        }
    }
    
    NSLog(@"The AVFrame data size:%d", offset);
    return NULL;
}

- (void)infalteStartCodeWithNalunitData:(NALUnit *)dataUnit {
    //Inflate start code with data length
    unsigned char* data  = dataUnit->data;
    unsigned int dataLen = dataUnit->size - 4;
    
    data[0] = (unsigned char)(dataLen >> 24);
    data[1] = (unsigned char)(dataLen >> 16);
    data[2] = (unsigned char)(dataLen >> 8);
    data[3] = (unsigned char)(dataLen & 0xff);
}

- (int)nalunitWithData:(char *)data andDataLen:(int)dataLen andOffset:(int)offset toNALUnit:(NALUnit *)unit {
    unit->size = 0;
    unit->data = NULL;
    
    int addUpLen = offset;
    while (addUpLen < dataLen) {
        if (data[addUpLen++] == 0x00 &&
            data[addUpLen++] == 0x00 &&
            data[addUpLen++] == 0x00 &&
            data[addUpLen++] == 0x01) {
            // H264 start code
            int pos = addUpLen;
            while (pos < dataLen) {
                // Find next NALU
                if (data[pos++] == 0x00 &&
                    data[pos++] == 0x00 &&
                    data[pos++] == 0x00 &&
                    data[pos++] == 0x01) {
                        break;
                }
            }
            
            unit->type = data[addUpLen] & 0x1f;
            if (pos == dataLen) {
                unit->size = pos - addUpLen + 4;
            } else {
                unit->size = pos - addUpLen;
            }
            unit->data = (unsigned char*)&data[addUpLen - 4];
            return 1;
        }
    }
    return -1;
}

/// 初始化H264解码器
- (BOOL)initH264Decoder {
    
    if (_decompressionSession) {
        return YES;
    }
    
    const uint8_t * const parameterSetPointers[2] = {_sps, _pps};
    const size_t parameterSetSizes[2] = {_spsSize, _ppsSize};
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                          2,// parameter count
                                                                          parameterSetPointers,
                                                                          parameterSetSizes,
                                                                          4,// NAL start code size
                                                                          &(_decompressionFormatDesc));
    
    if (status == noErr) {
        const void *keys[] = {kCVPixelBufferPixelFormatTypeKey };
        
        // kCVPixelFormatType_420YpCbCr8Planar is YUV420, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
        uint32_t biPlanarType = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
        const void *values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &biPlanarType) };
        CFDictionaryRef attributes = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
        
        // Create decompression session
        VTDecompressionOutputCallbackRecord outputCallBaclRecord;
        outputCallBaclRecord.decompressionOutputRefCon = NULL;
        outputCallBaclRecord.decompressionOutputCallback = decompressionOutputCallbackRecord;
        status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                              _decompressionFormatDesc,
                                              NULL,
                                              attributes,
                                              &outputCallBaclRecord,
                                              &_decompressionSession);
        CFRelease(attributes);
        if (status != noErr) {
            return NO;
        }
    } else {
        NSLog(@"Error code %d:Creates a format description for a video media stream described by H.264 parameter set NAL units.", (int)status);
        return NO;
    }
    return YES;
}

// Callback function:Return data when finished, the data includes decompress data、status and so on.
static void decompressionOutputCallbackRecord(void * CM_NULLABLE decompressionOutputRefCon,
                                              void * CM_NULLABLE sourceFrameRefCon,
                                              OSStatus status,
                                              VTDecodeInfoFlags infoFlags,
                                              CM_NULLABLE CVImageBufferRef imageBuffer,
                                              CMTime presentationTimeStamp,
                                              CMTime presentationDuration ){
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(imageBuffer);
}

- (CVPixelBufferRef)decompressWithAVPacket:(AVPacket *)packet {
    CMBlockBufferRef blockBufferRef = NULL;
    CVPixelBufferRef outputPixelBufferRef = NULL;
    
    //1.Fetch video data and generate CMBlockBuffer
    OSStatus status = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                         packet->data,
                                                         packet->size,
                                                         kCFAllocatorNull,
                                                         NULL,
                                                         0,
                                                         packet->size,
                                                         0,
                                                         &blockBufferRef);
    //2.Create CMSampleBuffer
    if(status == kCMBlockBufferNoErr){
        CMSampleBufferRef sampleBufferRef = NULL;
        const size_t sampleSizes[] = {packet->size};
        
        CMSampleTimingInfo timing = {CMTimeMakeWithSeconds(packet->duration, 1),
            CMTimeMakeWithSeconds(packet->pts, 1), CMTimeMakeWithSeconds(packet->dts, 1)};
        
        OSStatus createStatus = CMSampleBufferCreate(kCFAllocatorDefault,
                                                     blockBufferRef,
                                                     true,
                                                     NULL,
                                                     NULL,
                                                     _decompressionFormatDesc,
                                                     1,
                                                     1,
                                                     &timing,
                                                     1,
                                                     sampleSizes,
                                                     &sampleBufferRef);
        
        //3.Create CVPixelBuffer
        if(createStatus == kCMBlockBufferNoErr && sampleBufferRef){
            VTDecodeFrameFlags frameFlags = 0;
            VTDecodeInfoFlags infoFlags = 0;
            
            OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(_decompressionSession,
                                                                      sampleBufferRef,
                                                                      frameFlags,
                                                                      &outputPixelBufferRef,
                                                                      &infoFlags);
            
            if(decodeStatus != noErr){
                CFRelease(sampleBufferRef);
                CFRelease(blockBufferRef);
                outputPixelBufferRef = nil;
                return nil;
            }
            
            
            if(_isTakePicture){
                if(!_isSaveTakePictureImage){
                    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:outputPixelBufferRef];
                    CIContext *ciContext = [CIContext contextWithOptions:nil];
                    CGImageRef videoImage = [ciContext
                                             createCGImage:ciImage
                                             fromRect:CGRectMake(0, 0,
                                                                 CVPixelBufferGetWidth(outputPixelBufferRef),
                                                                 CVPixelBufferGetHeight(outputPixelBufferRef))];
                    
                    UIImage *uiImage = [UIImage imageWithCGImage:videoImage];
                    _isSaveTakePictureImage = [UIImageJPEGRepresentation(uiImage, 1.0) writeToFile:_saveTakePicturePath atomically:YES];
                    CGImageRelease(videoImage);
                }
            }
            CFRelease(sampleBufferRef);
        }
        CFRelease(blockBufferRef);
    }
    return outputPixelBufferRef;
}

- (void)decompressWithPacket:(AVPacket *)packet completed:(CDHardwareDecompressCompleted)completed {
    
    if (!_decompressionSession) {
        return;
    }
    
    CMBlockBufferRef blockBufferRef = NULL;
    CVPixelBufferRef outputPixelBufferRef = NULL;
    
    // 1.Fetch video data and generate CMBlockBuffer
    OSStatus status = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                         packet->data,
                                                         packet->size,
                                                         kCFAllocatorNull,
                                                         NULL,
                                                         0,
                                                         packet->size,
                                                         0,
                                                         &blockBufferRef);
    
    // 2.Create CMSampleBuffer
    if (status == kCMBlockBufferNoErr) {
        CMSampleBufferRef sampleBufferRef = NULL;
        const size_t sampleSizes[] = {packet->size};
        
        CMSampleTimingInfo timing = {CMTimeMakeWithSeconds(packet->duration, 1), CMTimeMakeWithSeconds(packet->pts, 1), CMTimeMakeWithSeconds(packet->dts, 1)};
        OSStatus createStatus = CMSampleBufferCreate(kCFAllocatorDefault,
                                                     blockBufferRef,
                                                     true,
                                                     NULL,
                                                     NULL,
                                                     _decompressionFormatDesc,
                                                     1,
                                                     1,
                                                     &timing,
                                                     1,
                                                     sampleSizes,
                                                     &sampleBufferRef);
        
        // 3.Create CVPixelBuuffer
        if (createStatus == kCMBlockBufferNoErr && sampleBufferRef) {
            VTDecodeFrameFlags frameFlags = 0;
            VTDecodeInfoFlags infoFlags = 0;
            
            OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(_decompressionSession,
                                                                      sampleBufferRef,
                                                                      frameFlags,
                                                                      &outputPixelBufferRef,
                                                                      &infoFlags);
            
            if (decodeStatus != noErr) {
                CFRelease(sampleBufferRef);
                CFRelease(blockBufferRef);
                outputPixelBufferRef = nil;
                return;
            }
            
            completed(outputPixelBufferRef, packet->pts, packet->duration);
            CVPixelBufferRelease(outputPixelBufferRef);
            CFRelease(sampleBufferRef);
        }
        CFRelease(blockBufferRef);
    }
}

- (void)dealloc {
    if (_sps) {
        free(_sps);
        _sps = NULL;
    }
    if (_pps){
        free(_pps);
        _pps = NULL;
    }
    
    if (_decompressionSession) {
        VTDecompressionSessionInvalidate(_decompressionSession);
        CFRelease(_decompressionSession);
        _decompressionSession = NULL;
    }
    
    if (_decompressionFormatDesc) {
        CFRelease(_decompressionFormatDesc);
        _decompressionFormatDesc = NULL;
    }
}

- (id)initWithCodecCtx:(AVCodecContext *)codecCtx {
    
    if (self = [super init]) {
        [self initH264DecoderWithCodecCtx:codecCtx];
    }
    return self;
}

- (BOOL)initH264DecoderWithCodecCtx:(AVCodecContext *)codec {
    if (_decompressionSession) {
        return YES;
    }
    
    uint8_t *sps = NULL;
    int spsLen = 0;
    int sps_start_index = 0;
    int sps_index = -1;
    while ((++sps_index) < codec->extradata_size) {
        if (codec->extradata[sps_start_index] != 0x67 && codec->extradata[sps_start_index] != 0x27)
        {
            sps_start_index ++;
        }
    }
    
    uint8_t *pps = NULL;
    int ppsLen = 0;
    int pps_start_index = codec->extradata_size > 0 ? (codec->extradata_size - 1) : 0;
    int pps_index = codec->extradata_size;
    while ((--pps_index) >= 0)
    {
        if (codec->extradata[pps_start_index] != 0x68 && codec->extradata[pps_start_index] != 0x28)
        {
            pps_start_index --;
        }
    }
    
    if ((codec->extradata_size > 0) && (sps_start_index != pps_start_index))
    {
        ppsLen = ABS(codec->extradata_size - pps_start_index);
        if (ppsLen < 4)
        {
            if (*(codec->extradata + (codec->extradata_size - 4)) == 0x68 || *(codec->extradata + (codec->extradata_size - 4)) == 0x28) {
                ppsLen = 4;
                pps_start_index = ABS(codec->extradata_size - 4);
            }
        }
        spsLen = ABS(pps_start_index - sps_start_index);
        
        
        sps = (uint8_t*)malloc(sizeof(uint8_t)*spsLen);
        pps = (uint8_t*)malloc(sizeof(uint8_t)*ppsLen);
        
        memcpy(sps,  (codec->extradata + sps_start_index), spsLen);
        memcpy(pps,  (codec->extradata + pps_start_index), ppsLen);
    }
    
    const uint8_t * const parameterSetPointers[2] = {sps, pps};
    const size_t parameterSetSizes[2] = {spsLen, ppsLen};
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                          2,//parameter count
                                                                          parameterSetPointers,
                                                                          parameterSetSizes,
                                                                          4,//NAL start code size
                                                                          &(_decompressionFormatDesc));
    
    if(status == noErr){
        _sps = sps;
        _pps = pps;
        // 指定VT必须使 的解码
        CFMutableDictionaryRef decoderParam = CFDictionaryCreateMutable(NULL,
                                                                        0,
                                                                        &kCFTypeDictionaryKeyCallBacks,
                                                                        &kCFTypeDictionaryValueCallBacks);
        
        // 设置解码后视频帧的格式(包括颜 空间、宽 等)
        CFMutableDictionaryRef destinationPixelAttributes = CFDictionaryCreateMutable(NULL,
                                                                                      0,
                                                                                      &kCFTypeDictionaryKeyCallBacks,
                                                                                      &kCFTypeDictionaryValueCallBacks);
        
        SInt32 destinationPixelType = kCVPixelFormatType_420YpCbCr8Planar;
        int tmpWidth = codec->width;
        int tmpHeight = codec->height;
        
        CFDictionarySetValue(destinationPixelAttributes,
                             kCVPixelBufferPixelFormatTypeKey,
                             CFNumberCreate(NULL,
                                            kCFNumberSInt32Type,
                                            &destinationPixelType));
        CFDictionarySetValue(destinationPixelAttributes,
                             kCVPixelBufferWidthKey,
                             CFNumberCreate(NULL,
                                            kCFNumberSInt32Type,
                                            &tmpWidth));
        CFDictionarySetValue(destinationPixelAttributes,
                             kCVPixelBufferHeightKey,
                             CFNumberCreate(NULL,
                                            kCFNumberSInt32Type,
                                            &tmpHeight));
        
        // 创建解码的session
        // 最后一个参数是返回值，也就是解码的session对象，在之后的解码与释放等流程都会使  到
        VTDecompressionOutputCallbackRecord outputCallBaclRecord;
        outputCallBaclRecord.decompressionOutputRefCon = NULL;
        outputCallBaclRecord.decompressionOutputCallback = decompressionOutputCallbackRecord;
        
        status = VTDecompressionSessionCreate(NULL,
                                              _decompressionFormatDesc,
                                              decoderParam,
                                              destinationPixelAttributes,
                                              &outputCallBaclRecord,
                                              &_decompressionSession);
        
        CFRelease(destinationPixelAttributes);
        CFRelease(decoderParam);
        
        if (status != noErr) {
            return NO;
        }
    } else {
        NSLog(@"Error code %d:Creates a format description for a video media stream described by H.264 parameter set NAL units.", (int)status);
        return NO;
    }

    return YES;
}

@end
