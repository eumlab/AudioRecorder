//
//  NSString+DocumentDirectory.m
//  AudioRecorder
//
//  Created by Nicholas Tau on 1/28/15.
//  Copyright (c) 2015 Nicholas Tau. All rights reserved.
//

#import "NSString+DocumentDirectory.h"

@implementation NSString (DocumentDirectory)
-(NSURL*)fileURLInDocumentDirectory
{
    NSArray *combinedPathComponents =
    @[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],self];
    return [NSURL fileURLWithPathComponents:combinedPathComponents];
}
@end
