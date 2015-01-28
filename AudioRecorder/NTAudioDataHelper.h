//
//  NTAudiDataHelper.h
//  AudioRecorder
//
//  Created by Nicholas Tau on 1/28/15.
//  Copyright (c) 2015 Nicholas Tau. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
@interface NTAudioDataHelper : NSObject
+(instancetype)sharedInstance;
-(void)initWithNumChannels:(UInt32)numChannels;

-(AudioBufferList)audioBufferListWithData:(NSData*)data;
-(NSData*)dataWithNewAudio:(void*)newData
                 numFrames:(UInt32)thisNumFrames;
@end
