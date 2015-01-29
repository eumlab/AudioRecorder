//
//  NTComposeHelper.m
//  AudioRecorder
//
//  Created by Nicholas Tau on 1/28/15.
//  Copyright (c) 2015 Nicholas Tau. All rights reserved.
//

#import "NTComposeHelper.h"
#import <AVFoundation/AVFoundation.h>
#import "NSString+DocumentDirectory.h"

@implementation NTComposeHelper
+(void)audioConnectWithAssertURLs:(NSArray*)urls
                  completedHander:(void (^)(void))handler
{
    AVMutableComposition * audioComposition =[AVMutableComposition composition];
    
    AVMutableCompositionTrack * composedTrack =
    [audioComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                  preferredTrackID:kCMPersistentTrackID_Invalid];
    
    NSError * insertError = nil;
    CMTime insertionPoint = kCMTimeZero;
    for (NSURL * assertURL in urls) {
        AVURLAsset * assert = [AVURLAsset assetWithURL:assertURL];
        [composedTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, assert.duration)
                               ofTrack:[assert tracksWithMediaType:AVMediaTypeAudio].firstObject
                                atTime:insertionPoint
                                 error:&insertError];
        NSLog(@"audio insert error:%@",insertError);
        insertionPoint = CMTimeAdd(insertionPoint, assert.duration);
    }
    
    AVAssetExportSession * exportSession =
    [[AVAssetExportSession alloc] initWithAsset:audioComposition
                                     presetName:AVAssetExportPresetAppleM4A];
    exportSession.outputURL = [@"ConnectedRecording.m4a" fileURLInDocumentDirectory];;
    exportSession.outputFileType = AVFileTypeAppleM4A;
    [exportSession exportAsynchronouslyWithCompletionHandler:handler];
}
@end
