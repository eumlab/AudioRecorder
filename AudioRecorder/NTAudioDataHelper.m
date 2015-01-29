//
//  NTAudiDataHelper.m
//  AudioRecorder
//
//  Created by Nicholas Tau on 1/28/15.
//  Copyright (c) 2015 Nicholas Tau. All rights reserved.
//

#import "NTAudioDataHelper.h"
@interface NTAudioDataHelper()
@property (nonatomic,assign) UInt32 numChannels;
@property (nonatomic,assign) float samplingRate;

@property (nonatomic,assign) float * outputBuffer;
@end

@implementation NTAudioDataHelper

static NTAudioDataHelper * _instance;
+(instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [NTAudioDataHelper new];
    });
    return _instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        //默认单音轨，采样率为44100
        _numChannels = 1;
        _samplingRate = 44100.0;
        _outputBuffer = (float *)calloc(self.samplingRate, sizeof(float));
    }
    return self;
}

-(void)initWithNumChannels:(UInt32)numChannels
                sampleRate:(float)samplingRate
{
    self.numChannels =  numChannels;
    self.samplingRate = samplingRate;
}

-(AudioBufferList)audioBufferListWithNewAudio:(float *)newData
                                    numFrames:(UInt32)thisNumFrames
                                  numChannels:(UInt32)thisNumChannels
{
    UInt32 numIncomingBytes = thisNumFrames*thisNumChannels*sizeof(float);
    memcpy(self.outputBuffer, newData, numIncomingBytes);
    
    AudioBufferList outgoingAudio;
    outgoingAudio.mNumberBuffers = 1;
    outgoingAudio.mBuffers[0].mNumberChannels = thisNumChannels;
    outgoingAudio.mBuffers[0].mDataByteSize = numIncomingBytes;
    outgoingAudio.mBuffers[0].mData = self.outputBuffer;
    return outgoingAudio;
}

-(AudioBufferList)audioBufferListWithData:(NSData*)data
{
    AudioBufferList outgoingAudio;
    outgoingAudio.mNumberBuffers = 1;
    outgoingAudio.mBuffers[0].mNumberChannels = self.numChannels;
    outgoingAudio.mBuffers[0].mDataByteSize = (UInt32)data.length;
    outgoingAudio.mBuffers[0].mData = (void*)data.bytes;
    return outgoingAudio;
}
@end
