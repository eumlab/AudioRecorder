//
//  NSString+DocumentDirectory.h
//  AudioRecorder
//
//  Created by Nicholas Tau on 1/28/15.
//  Copyright (c) 2015 Nicholas Tau. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (DocumentDirectory)
-(NSURL*)fileURLInDocumentDirectory;
@end
