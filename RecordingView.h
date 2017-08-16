//
//  RecordingView.h
//  SoundPill
//
//  Created by 宋旭东®Des on 15/1/17.
//  Copyright (c) 2015年 宋旭东. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface RecordingView : UIView<AVAudioPlayerDelegate,AVAudioRecorderDelegate>
@property (strong ,nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) NSURL *recordedFile;
@property (strong, nonatomic) AVAudioRecorder *record;
@property (strong, nonatomic) AVAudioPlayer *player;
@property (strong, nonatomic) AVAudioPlayer *draftPlayer;
@property (strong, nonatomic) NSMutableArray *averagePowerArray;//平均值数组
@property (strong, nonatomic) NSMutableArray *averagerPowerComplete;
@property (strong, nonatomic) NSArray *draftWaveform;
@property (strong, nonatomic) NSURL *draftPlayUrl;
@property (strong, nonatomic) NSMutableArray *offSetComplete;
@property (strong, nonatomic) NSMutableArray *offSetArray;

- (void)startForFilePath:(NSURL *)filePath;
- (void)pauseRecord;
- (void)resumeRecord;
- (void)stopRecord;
- (void)stopWithNoPlay;
- (void)playStart;
- (void)playPause;
- (void)getScrollView:(UIScrollView *)scroll;
- (void)getAudioPath:(NSString *)audioPath draftAuioWaveform:(NSArray *)draftWaveform;
@end
