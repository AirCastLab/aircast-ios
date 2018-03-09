//
//  ViewController.m
//  aircast-demo
//
//  Created by xiang on 04/03/2018.
//  Copyright © 2018 dotEngine. All rights reserved.
//

#import "ViewController.h"

#import "VideoPacket.h"
#import "AAPLEAGLLayer.h"
#import <VideoToolbox/VideoToolbox.h>

#import <aircast_sdk_ios/acast_c.h>



@interface ViewController ()
{
    uint8_t *_sps;
    NSInteger _spsSize;
    uint8_t *_pps;
    NSInteger _ppsSize;
    VTDecompressionSessionRef _deocderSession;
    CMVideoFormatDescriptionRef _decoderFormatDescription;
    
    AAPLEAGLLayer *_glLayer;
    
    void* _callbackContext;
    
    BOOL _isStarted;
}


-(void) showMsg:(NSString*)msg;
- (void)setPPS:(uint8_t*)data size:(size_t)dataSize;
- (void)setSPS:(uint8_t*)data size:(size_t)dataSize;
- (BOOL)initH264Decoder;
- (void)clearH264Deocder;
- (void)decode:(VideoPacket*)vp;

@end


#pragma static method

static void didDecompress( void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef pixelBuffer, CMTime presentationTimeStamp, CMTime presentationDuration ){
    
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
}

//callback
static int ac_callback( EACMsgType eType, void* data, size_t dataSize, void* opaque)
{
    ViewController* obj = (__bridge ViewController*)(opaque);
    NSString* msg;
    switch (eType)
    {
        case eACMsgType_Error:
        {
            SACErrorInfo * eInfo = (SACErrorInfo*)data;
            //ASSERT(dataSize == sizeof(SACErrorInfo));
            msg = [NSString stringWithFormat:@"error occurs: %s\n", eInfo->info];
            //NSLog(@"error occurs: %s\n", eInfo->info);
        }
            break;
        case eACMsgType_Info:
            break;
        case eACMsgType_Connected:
        {
            SACConnectedInfo * conInfo = (SACConnectedInfo*)data;
            //ASSERT(dataSize == sizeof(SACConnectedInfo));
            msg = [NSString stringWithFormat:@"new connection: name: %s; ip: %s; deviceID: %s, model: %s\n", \
                   conInfo->peerName, conInfo->peerIPAddr, conInfo->peerDeviceID, conInfo->peerModel];
        }
            break;
        case eACMsgType_MediaDesc:
        {
            SACMediaDescInfo * info = (SACMediaDescInfo*)data;
            //ASSERT(dataSize == sizeof(SACMediaDescInfo));
            NSLog(@"New media starting...\n");
            switch (info->mediaType)
            {
                case eACMediaType_VideoStream:
                {
                    msg = [NSString stringWithFormat:@"video stream: width: %d; height: %d, rotate: %d, extraDataSize: %d\n",
                           info->info.videoStream.width, info->info.videoStream.height, info->info.videoStream.rotate, info->info.videoStream.extraDataSize];
                    //to save sps, pps. extra data formatted as: [(uint8_t)sps size] + [sps] + [(uint8_t)pps size] + [pps]
                    ///
                    [obj clearH264Deocder];
                    
                    uint8_t* csd = info->info.videoStream.extraData;
                    size_t csdSize = info->info.videoStream.extraDataSize;
                    size_t sps_size = csd[0];
                    uint8_t* sps = csd + 1;
                    size_t pps_size = csd[1+sps_size];
                    uint8_t* pps = csd + 2 + sps_size;
                    [obj setSPS:sps size:sps_size];
                    [obj setPPS:pps size:pps_size];
                    [obj initH264Decoder];
                }
                    break;
                case eACMediaType_AudioFrame:
                    msg = [NSString stringWithFormat:@"audio stream: sampleRate: %d; channels: %d\n",
                           info->info.audioFrame.sampleRate, info->info.audioFrame.channels];
                    //TODO: initialize the audio output
                    break;
                default:
                    break;
            }
        }
            break;
        case eACMsgType_Disconnected:
        {
            SACDisconnectInfo * info = (SACDisconnectInfo*)data;
            //ASSERT(dataSize == sizeof(SACDisconnectInfo));
            switch (info->streamType)
            {
                case eACStreamType_All:
                    msg = [NSString stringWithFormat:@"current session reset.\n"];
                    break;
                case eACStreamType_Video:
                    //[obj clearH264Deocder];
                    msg = [NSString stringWithFormat:@"video session reset.\n"];
                    break;
                case eACStreamType_Audio:
                    msg = [NSString stringWithFormat:@"audio session reset.\n"];
                    break;
                default:
                    break;
            }
        }
            break;
        case eACMsgType_VideoData:
        {
            SACAVDataInfo * info = (SACAVDataInfo*)data;
            //ASSERT(dataSize == sizeof(SACAVDataInfo));
            if (info->flags & ACAVDATA_FLAG_NEWFORMAT)
            {
                ////////
                NSLog(@"new video segment\n");
                //[obj initH264Decoder];
                //TODO: Check and handle result
            }
            
            //output the data
            VideoPacket* vp = [[VideoPacket alloc] initWith:(info->data) size:(info->dataSize)];
            [obj decode:vp];
        }
            break;
        case eACMsgType_AudioData:
        {
            SACAVDataInfo * info = (SACAVDataInfo*)data;
            //ASSERT(dataSize == sizeof(SACAVDataInfo));
            if (info->flags & ACAVDATA_FLAG_NEWFORMAT)
            {
                ////////
                NSLog(@"new audio segment\n");
                //TODO: init audio output...
            }
        }
            break;
        case eACMsgType_LicenseRequest:
            //To send license Request
            NSLog(@"license request\n");
            break;
        default:
            break;
    }
    
    //display the message
    if( msg.length > 0)
    {
        [obj showMsg:msg];
    }
    return 1;
}

static void init_aircast(void* context)
{
    //simply
    int ret = ac_setup(ac_callback, context);
    if (ret != AC_OK)
    {
        NSLog(@"failed to setup, return: %d\n", ret);
    }
    
    //params
    SACStartParams params;
    params.broadcastName = "aircast_sdk_test";
    params.enableAudio = true;
    params.eVideoOutputResOption = eACResOpt_Auto;
    
    ret = ac_start(&params);
    if (ret != AC_OK)
    {
        NSLog(@"failed to start, ret: %d\n", ret);
    }
    return;
}

static void deinit_aircast()
{
    ac_stop();
    ac_finalize();
    return;
}


#pragma implementation


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _glLayer = [[AAPLEAGLLayer alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 300)];
    
    [self.view.layer addSublayer:_glLayer];
    
    _labelMsg.text = @"click start";
    _isStarted = false;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear : (BOOL)animated{
    //
    [super viewWillDisappear:animated];
    
    //////
    if( _isStarted)
    {
        deinit_aircast();
        CFBridgingRelease( _callbackContext);
    }
}


- (IBAction)buttonClick:(id)sender {
    
    if( _isStarted)
    {
        deinit_aircast();
        CFBridgingRelease( _callbackContext);
        [_btnControl setTitle:@"Start" forState:UIControlStateNormal];
        _isStarted = FALSE;
    }
    else
    {
        //start to initialize the aircast
        _callbackContext = (void*)CFBridgingRetain(self);
        init_aircast( _callbackContext);
        [_btnControl setTitle:@"Stop" forState:UIControlStateNormal];
        _isStarted = TRUE;
    }
    
}




-(void) showMsg:(NSString*)msg
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _labelMsg.text =  msg;
    });
}



//todo make decode to a lib
-(void) setSPS:(uint8_t*)data size:(size_t)dataSize{
    _spsSize = dataSize;
    _sps = malloc( dataSize);
    memcpy( _sps, data, dataSize);
}

-(void) setPPS:(uint8_t*)data size:(size_t)dataSize{
    _ppsSize = dataSize;
    _pps = malloc( dataSize);
    memcpy( _pps, data, dataSize);
}

-(BOOL)initH264Decoder {
    if(_deocderSession) {
        return YES;
    }
    
    const uint8_t* const parameterSetPointers[2] = { _sps, _pps };
    const size_t parameterSetSizes[2] = { _spsSize, _ppsSize };
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                          2, //param count
                                                                          parameterSetPointers,
                                                                          parameterSetSizes,
                                                                          4, //nal start code size
                                                                          &_decoderFormatDescription);
    
    if(status == noErr) {
        CFDictionaryRef attrs = NULL;
        const void *keys[] = { kCVPixelBufferPixelFormatTypeKey };
        //      kCVPixelFormatType_420YpCbCr8Planar is YUV420
        //      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
        uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
        const void *values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &v) };
        attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
        
        VTDecompressionOutputCallbackRecord callBackRecord;
        callBackRecord.decompressionOutputCallback = didDecompress;
        callBackRecord.decompressionOutputRefCon = NULL;
        
        status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                              _decoderFormatDescription,
                                              NULL, attrs,
                                              &callBackRecord,
                                              &_deocderSession);
        CFRelease(attrs);
    } else {
        NSLog(@"IOS_VT: reset decoder session failed status=%d", status);
    }
    
    return YES;
}

-(void)clearH264Deocder {
    if(_deocderSession) {
        VTDecompressionSessionInvalidate(_deocderSession);
        CFRelease(_deocderSession);
        _deocderSession = NULL;
    }
    
    if(_decoderFormatDescription) {
        CFRelease(_decoderFormatDescription);
        _decoderFormatDescription = NULL;
    }
    
    if( _sps){
        free(_sps);
        _sps = NULL;
    }
    if( _pps){
        free(_pps);
        _pps = NULL;
    }
    
    _spsSize = _ppsSize = 0;
}

-(void)decode:(VideoPacket*)vp {
    CVPixelBufferRef outputPixelBuffer = NULL;
    
    CMBlockBufferRef blockBuffer = NULL;
    OSStatus status  = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                          (void*)vp.buffer, vp.size,
                                                          kCFAllocatorNull,
                                                          NULL, 0, vp.size,
                                                          0, &blockBuffer);
    if(status == kCMBlockBufferNoErr) {
        CMSampleBufferRef sampleBuffer = NULL;
        const size_t sampleSizeArray[] = {vp.size};
        status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                           blockBuffer,
                                           _decoderFormatDescription ,
                                           1, 0, NULL, 1, sampleSizeArray,
                                           &sampleBuffer);
        if (status == kCMBlockBufferNoErr && sampleBuffer) {
            VTDecodeFrameFlags flags = 0;
            VTDecodeInfoFlags flagOut = 0;
            OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(_deocderSession,
                                                                      sampleBuffer,
                                                                      flags,
                                                                      &outputPixelBuffer,
                                                                      &flagOut);
            
            if(decodeStatus == kVTInvalidSessionErr) {
                NSLog(@"IOS_VT: Invalid session, reset decoder session");
            } else if(decodeStatus == kVTVideoDecoderBadDataErr) {
                NSLog(@"IOS_VT: decode failed status=%d(Bad data)", decodeStatus);
            } else if(decodeStatus != noErr) {
                NSLog(@"IOS_VT: decode failed status=%d", decodeStatus);
            }
            
            CFRelease(sampleBuffer);
        }
        CFRelease(blockBuffer);
    }
    if( outputPixelBuffer != NULL){
        dispatch_sync(dispatch_get_main_queue(), ^{
            _glLayer.pixelBuffer = outputPixelBuffer;
        });
        
        CVPixelBufferRelease(outputPixelBuffer);
    }
    return;
}


@end
