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

#if __has_include("Novocaine.h")
#import "Novocaine.h"
#import <AudioFileWriter.h>
#import <AudioFileReader.h>
#define kNovocaineLib
#endif

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
@property (nonatomic,strong) AEAudioFilePlayer * audioFilePlayer;
@property (nonatomic,strong) AEBlockAudioReceiver * audioReceiver;
@property (nonatomic,strong) AEAudioFileWriter * fileWriter;

#ifdef kNovocaineLib
@property (nonatomic,strong) AudioFileReader * fileReader;
#endif

@property (nonatomic,assign) UInt32 maxMemoryCacheCount;
@property (nonatomic,assign) int preRecordFrameEx;
@end

@implementation ViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initInstances];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self initInstances];
    }
    return self;
}

-(void)initInstances
{
    AudioStreamBasicDescription basicDescription =
    [ViewController customDescription];
    self.audioController =
    [[AEAudioController alloc] initWithAudioDescription:basicDescription
                                           inputEnabled:YES];
    [[NTAudioDataHelper sharedInstance] initWithNumChannels:basicDescription.mChannelsPerFrame
                                                 sampleRate:basicDescription.mSampleRate];
    _audioController.preferredBufferDuration = 0.005;
    _audioController.useMeasurementMode = YES;
    self.maxMemoryCacheCount = 15/_audioController.preferredBufferDuration;
    [_audioController start:NULL];
}

+ (AudioStreamBasicDescription)customDescription {
    AudioStreamBasicDescription audioDescription;
    memset(&audioDescription, 0, sizeof(audioDescription));
    audioDescription.mFormatID          = kAudioFormatLinearPCM;
    audioDescription.mFormatFlags       = kAudioFormatFlagIsFloat;
    audioDescription.mChannelsPerFrame  = 2;
    audioDescription.mBytesPerPacket    = 8;//sizeof(float);
    audioDescription.mFramesPerPacket   = 1;
    audioDescription.mBytesPerFrame     = 8;//sizeof(float);
    audioDescription.mBitsPerChannel    = 32;// * sizeof(float);
    audioDescription.mSampleRate        = 44100.0;
    audioDescription.mReserved          = NO;
    return audioDescription;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)preRecordTapped:(id)sender
{
    [self prerecordStart];
}
- (IBAction)recordTapped:(id)sender
{
    [self recordStart];
}
- (IBAction)finishTapped:(id)sender
{
    [self recordStop];
}
- (IBAction)playTapped:(id)sender {
    [self playAudio];
}

-(void)playAudio
{
#ifdef kNovocaineLib
    if (!self.fileReader) {
        self.fileReader =
        [[AudioFileReader alloc] initWithAudioFileURL:[kConnectedFileName fileURLInDocumentDirectory]
                                         samplingRate:44000
                                          numChannels:2];
    }else{
        [self.fileReader stop];
    }
    [self.fileReader play];
#else
    if(self.audioFilePlayer){
        [self.audioController removeChannels:@[self.audioFilePlayer]];
    }
    if (!self.audioFilePlayer) {
        NSError * error = nil;
        AEAudioFilePlayer * audioPlayer =
        [AEAudioFilePlayer audioFilePlayerWithURL:[kConnectedFileName fileURLInDocumentDirectory]
                                  audioController:self.audioController
                                            error:&error];
        audioPlayer.removeUponFinish = YES;
        audioPlayer.completionBlock = ^(){
            NSLog(@"audio play finished");
        };
        self.audioFilePlayer = audioPlayer;
        if (error) {
            NSLog(@"error:%@",error);
        }
    }
    [self.audioController addChannels:@[self.audioFilePlayer]];
#endif
}

-(NSMutableArray*)recordSampleList
{
    if (!_sampleCacheList) {
        _sampleCacheList = [NSMutableArray array];
    }
    return _sampleCacheList;
}

-(void)prerecordStart
{
    if (self.recordState==kRecordFinsied) {
        self.recordState = kRecordPrerecording;
        [self trackRecordSampleBuffer];
    }
}

-(void)recordStart
{
    if (self.recordState!=kRecordRecording) {
        if (self.recordState==kRecordFinsied) {
            [self trackRecordSampleBuffer];
        }
        self.recordState = kRecordRecording;
    }
}

-(void)recordStop
{
    self.recordState = kRecordFinsied;
    [self.fileWriter finishWriting];
    [self.audioController removeInputReceiver:self.audioReceiver];
    [self.audioController removeOutputReceiver:self.audioReceiver];
    self.audioReceiver = nil;
    
    [self writePreRecordFile];

    NSURL * preRecordURL = [kPreRecordFileName fileURLInDocumentDirectory];
    NSURL * realRecordURL = [kRealRecordFileName fileURLInDocumentDirectory];
    [NTComposeHelper audioConnectWithAssertURLs:@[preRecordURL,realRecordURL]
                                       fileName:kConnectedFileName
                                completedHander:^{
                                    NSLog(@"combine finished");
                                }];
}

-(void)writePreRecordFile
{
#ifdef kNovocaineLib
    UInt32 numChannels = [Novocaine audioManager].numInputChannels;
    AudioFileWriter * fileWriter =
    [[AudioFileWriter alloc] initWithAudioFileURL:[kPreRecordFileName fileURLInDocumentDirectory]
                                     samplingRate:[Novocaine audioManager].samplingRate
                                      numChannels:[Novocaine audioManager].numInputChannels];
    while (self.sampleCacheList.count>0) {
        NSData * dataBytes = self.sampleCacheList.firstObject;
        AudioBufferList bufferList =
        [[NTAudioDataHelper sharedInstance] audioBufferListWithData:dataBytes];
        UInt32 numFrames = bufferList.mBuffers[0].mDataByteSize/(numChannels*sizeof(float));
        [fileWriter writeNewAudioWithBufferList:bufferList
                                      numFrames:numFrames
                                    numChannels:numChannels];
        [self.sampleCacheList removeObjectAtIndex:0];
        NSLog(@"bufferList:%p",dataBytes);
    }
    [fileWriter stop];
    [[Novocaine audioManager] pause];

#else
    if (self.sampleCacheList.count>0) {
        UInt32 sampleRate = self.audioController.audioDescription.mSampleRate;
        AEAudioFileWriter * fileWriter =
        [[AEAudioFileWriter alloc] initWithAudioDescription:self.audioController.audioDescription];
        NSError * error = nil;
        [fileWriter beginWritingToFileAtPath:[kPreRecordFileName fileURLInDocumentDirectory].path
                                    fileType:kAudioFileAIFFType
                                       error:&error];
        if (error) {
            NSLog(@"file writer begin write error:%@",error);
        }else {
            while (self.sampleCacheList.count>0) {
                NSData * dataByte = self.sampleCacheList.firstObject;
                AudioBufferList bufferList =
                [[NTAudioDataHelper sharedInstance] audioBufferListWithData:dataByte];
                AEAudioFileWriterAddAudio(fileWriter, &bufferList, sampleRate);
                [self.sampleCacheList removeObjectAtIndex:0];
                NSLog(@"bufferList:%p",dataByte);
            }
            [fileWriter finishWriting];
        }
    }
#endif
}

-(void)trackRecordSampleBuffer
{
    [self.recordSampleList removeAllObjects];
    if(self.audioReceiver){
        [self.audioController removeInputReceiver:self.audioReceiver];
        [self.fileWriter finishWriting];
        self.fileWriter = nil;
#ifdef kNovocaineLib
        [[Novocaine audioManager] pause];
#endif
    }else{
        self.fileWriter =
        [[AEAudioFileWriter alloc] initWithAudioDescription:self.audioController.audioDescription];
        NSError * error = nil;
        [self.fileWriter beginWritingToFileAtPath:[kRealRecordFileName fileURLInDocumentDirectory].path
                                         fileType:kAudioFileAIFFType
                                            error:&error];
        if (error) {
            NSLog(@"file writer begin write error:%@",error);
        }else{
#ifdef kNovocaineLib
            __weak __typeof(&*self)weakSelf = self;
            [Novocaine audioManager].inputBlock = ^(float *data, UInt32 numFrames, UInt32 numChannels) {
                AudioBufferList audilBufferList =
                [[NTAudioDataHelper sharedInstance] audioBufferListWithNewAudio:data
                                                                      numFrames:numFrames
                                                                    numChannels:numChannels];
                [weakSelf realtimeProcessWithBufferList:&audilBufferList
                                              numFrames:numFrames];
            };
            [[Novocaine audioManager] play];
#else
            __weak __typeof(&*self)weakSelf = self;
            self.audioReceiver =
            [AEBlockAudioReceiver audioReceiverWithBlock:^(void *source,
                                                           const AudioTimeStamp *time,
                                                           UInt32 frames,
                                                           AudioBufferList *bufferList) {
                [weakSelf realtimeProcessWithBufferList:bufferList
                                              numFrames:frames];
            }];
            [self.audioController addInputReceiver:self.audioReceiver];
#endif
        }
    }
}

-(void)realtimeProcessWithBufferList:(AudioBufferList*)bufferList
                           numFrames:(UInt32)numFrames
{
    if (self.preRecordFrameEx<10) {
        AudioBufferList audioBufferList = *bufferList;
        NSData * dataBytes = [NSData dataWithBytes:audioBufferList.mBuffers[0].mData
                                            length:audioBufferList.mBuffers[0].mDataByteSize];
        [self.sampleCacheList addObject:dataBytes];
        if (self.sampleCacheList.count>self.maxMemoryCacheCount) {
            [self.sampleCacheList removeObjectAtIndex:0];
        }
    }
    if (self.recordState==kRecordRecording) {
        AEAudioFileWriterAddAudio(self.fileWriter, bufferList, numFrames);
        if(self.preRecordFrameEx<10){
            self.preRecordFrameEx++;
        }
    }
}

@end
