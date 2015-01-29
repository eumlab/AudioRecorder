//
//  NTComposeHelper.h
//  AudioRecorder
//
//  Created by Nicholas Tau on 1/28/15.
//  Copyright (c) 2015 Nicholas Tau. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NTComposeHelper : NSObject
+(void)audioConnectWithAssertURLs:(NSArray*)urls
                  completedHander:(void (^)(void))handler;
@end
