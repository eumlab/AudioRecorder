//
//  NTAudiDataHelper.m
//  AudioRecorder
//
//  Created by Nicholas Tau on 1/28/15.
//  Copyright (c) 2015 Nicholas Tau. All rights reserved.
//

#import "NTAudioDataHelper.h"
#import <pthread.h>
@interface NTAudioDataHelper()
@property (nonatomic,assign) float * outputBuffer;
@property (nonatomic,assign) UInt32 numChannels;
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

-(void)initWithNumChannels:(UInt32)numChannels
{
    if (!self.numChannels) {
        self.numChannels =  numChannels;
    }
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

-(NSData*)dataWithNewAudio:(void*)newData
                 numFrames:(UInt32)thisNumFrames
{
    UInt32 numIncomingBytes = thisNumFrames*self.numChannels*sizeof(float);
    memcpy(self.outputBuffer, newData, numIncomingBytes);
    
    NSData * data = [NSData dataWithBytes:self.outputBuffer length:numIncomingBytes];
    return data;
}
@end
