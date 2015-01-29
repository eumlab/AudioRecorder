//
//  ViewController.m
//  AudioRecorder
//
//  Created by Nicholas Tau on 1/15/15.
//  Copyright (c) 2015 Nicholas Tau. All rights reserved.
//

#import "ViewController.h"
#import "NTAudioDataHelper.h"
#import "NTComposeHelper.h"
#import <AEAudioController.h>
#import <AEAudioFileWriter.h>
#import <AEBlockAudioReceiver.h>
#import "NSString+DocumentDirectory.h"

typedef enum : NSUInteger {
    kRecordFinsied,
    kRecordPrerecording,
    kRecordRecording,
} kRecordState;

static NSString * const kPreRecordFileName  = @"PreRecord.aiff";
static NSString * const kRealRecordFileName = @"RealRecord.aiff";
static NSString * const kConnectedFileName  = @"ConnectedRecord.aiff";

@interface ViewController ()
@property (nonatomic,assign) kRecordState recordState;
@property (nonatomic,strong) NSMutableArray * sampleCacheList;

@property (nonatomic,strong) AEAudioController * audioController;
@property (nonatomic,strong) AEBlockAudioReceiver * audioReceiver;

@property (nonatomic,assign) UInt32 maxMemoryCacheCount;

@property (nonatomic,strong) AEAudioFileWriter * fileWriter;
@end

@implementation ViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        AudioStreamBasicDescription basicDescription =
        [AEAudioController nonInterleaved16BitStereoAudioDescription];
        self.audioController =
        [[AEAudioController alloc] initWithAudioDescription:basicDescription
                                               inputEnabled:YES];
        [[NTAudioDataHelper sharedInstance] initWithNumChannels:basicDescription.mChannelsPerFrame
                                                     sampleRate:basicDescription.mSampleRate];
        _audioController.preferredBufferDuration = 0.005;
        _audioController.useMeasurementMode = YES;
        self.maxMemoryCacheCount = 15/_audioController.preferredBufferDuration;
        [_audioController start:NULL];
        
        self.fileWriter = [[AEAudioFileWriter alloc] initWithAudioDescription:basicDescription];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
