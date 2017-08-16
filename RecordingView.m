//
//  RecordingView.m
//  SoundPill
//
//  Created by 宋旭东®Des on 15/1/17.
//  Copyright (c) 2015年 宋旭东. All rights reserved.
//

#import "RecordingView.h"
#import "JCAlertView.h"
@interface RecordingView ()<UIScrollViewDelegate>
{
    NSInteger isStartWithTop;//0, 1, 2
    float scrollOffSet;
    float waveLength;
    float percentage;
}
@property (strong, nonatomic) UIButton *button;
@property (strong, nonatomic) NSMutableDictionary *recordSettings;//录音设置
@property (strong, nonatomic) NSTimer *timer;//录音定时器
@property (strong, nonatomic) NSTimer *playTimer;//播放定时器
@property (assign, nonatomic) float averagePower;//平均值
@property (assign, nonatomic) float onceOffSet;//波形位移
@property (strong, nonatomic) NSNumber *onceOffSetNum;//波形位移
@property (assign, nonatomic) CGFloat playOffSet;//播放位移
@property (strong, nonatomic) NSNumber *averagePowerNum;//平均值 NSNumber
//位移数组
@property (strong, nonatomic) NSNumber *isDraft;

@end

@implementation RecordingView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.recordSettings = [NSMutableDictionary dictionary];
        [_recordSettings setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
        [_recordSettings setValue:[NSNumber numberWithFloat:44100] forKey:AVSampleRateKey];
        [_recordSettings setValue:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
        [_recordSettings setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
        [_recordSettings setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
        
        self.backgroundColor = [UIColor clearColor];
        
        CGRect MainScreen = [UIScreen mainScreen].bounds;
//        设置波形第一条绘制的位置
        self.onceOffSet = MainScreen.size.width / 2;
//        初始化播放时 scroll 的偏移量
        _playOffSet = 0;
//        初始化波形数据数组
        self.averagePowerArray = [[NSMutableArray alloc] init];
//        初始化波形数据的完整数组
        self.averagerPowerComplete = [[NSMutableArray alloc] init];
//        初始化波形位移数组
        self.offSetArray = [[NSMutableArray alloc] init];
        self.offSetComplete = [[NSMutableArray alloc] init];
//        初始化波形位移完整数组
        self.averagePowerNum = [[NSNumber alloc] init];
        self.onceOffSetNum = [[NSNumber alloc] initWithFloat:_onceOffSet];
    }
    return self;
}

- (void)getScrollView:(UIScrollView *)scroll
{
    self.scrollView = scroll;
    _scrollView.delegate = self;
    self.isDraft = [NSNumber numberWithBool:NO];
}
- (void)getAudioPath:(NSString *)audioPath draftAuioWaveform:(NSArray *)draftWaveform
{
    self.isDraft = [NSNumber numberWithBool:YES];
    NSString *worktime = audioPath;
    NSString *strUrl = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *DouNiu = [strUrl stringByAppendingPathComponent:@"DouNiu"];
    NSString *draftAudio = [DouNiu stringByAppendingFormat:@"/%@/%@.caf", worktime, worktime];
    self.draftPlayUrl = [NSURL URLWithString:draftAudio];
    self.draftWaveform = [NSArray arrayWithArray:draftWaveform];
    int offset = draftWaveform.count *2 + [UIScreen mainScreen].bounds.size.width / 2;
    NSNumber *width = [NSNumber numberWithInt:offset];
    waveLength = draftWaveform.count * 2;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"scrollContentSize" object: width];
    [self setNeedsDisplay];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:_draftPlayUrl error:nil];
    _player.delegate = self;
    _player.numberOfLoops = 0;
    _player.volume = 1;
    [_player prepareToPlay];
}
//开始录音
- (void)startForFilePath:(NSURL *)filePath
{
    if (self.record.isRecording) {
        return;
    }
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err = nil;

    [audioSession setActive:YES error:nil];
    [audioSession setCategory :AVAudioSessionCategoryPlayAndRecord error:&err];
//    判断 麦克风是否打开
    if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
        [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
            if (granted) {
                // Microphone enabled code
//                NSLog(@"Microphone is enabled..");

                self.recordedFile = filePath;
                self.record = [[AVAudioRecorder alloc] initWithURL:_recordedFile settings:_recordSettings error:nil];
                [self.record setDelegate:self];
                [self.record prepareToRecord];
                [self.record record];
                [self.record setMeteringEnabled:YES];
                self.timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(updateMeters) userInfo:nil repeats:YES];
//                AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:<#(nonnull NSURL *)#> error:nil];
            }
            else {
                // Microphone disabled code
//                [[[UIAlertView alloc] initWithTitle:@"无法使用麦克风" message:@"请在“设置-隐私-麦克风”选项中允许符点访问你的麦克风" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
                [JCAlertView showOneButtonWithTitle:@"无法使用麦克风" Message:@"请在“设置-隐私-麦克风”选项中允许符点访问你的麦克风" ButtonType:JCAlertViewButtonTypeDefault ButtonTitle:@"确定" Click:^{
                    
                }];
            }
        }];
    }
    
    
}
- (void)pauseRecord
{
    [self.record pause];
    [self.timer setFireDate:[NSDate distantFuture]];
}
- (void)resumeRecord
{
    [self.record record];
    [self.timer setFireDate:[NSDate distantPast]];
}
- (void)stopRecord
{
    
    [self.record stop];
    [self.timer invalidate];
    self.timer = nil;
    [self setNeedsDisplay];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:_recordedFile error:nil];
    _player.delegate = self;
    _player.numberOfLoops = 0;
    _player.volume = 1;
    [_player prepareToPlay];
    isStartWithTop = 1;
//    NSLog(@"偏移量 == %@", [_offSetArray lastObject]);
//        波形最后的偏移量
    NSNumber *arrayLast = [_offSetArray lastObject];
    float last = arrayLast.floatValue;
//    拿最后的偏移量 减去初始位置的坐标 = 波形长度
    waveLength = last - [UIScreen mainScreen].bounds.size.width / 2;
//    NSLog(@"波形长度 == %.2f", waveLength);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"scrollContentSize" object:[_offSetArray lastObject]];
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error;
    [session setCategory:AVAudioSessionCategoryPlayback error:&error];
}

- (void)stopWithNoPlay
{
    [self.record stop];
    [self.timer invalidate];
    self.timer = nil;
}

- (void)playStart
{
    if (isStartWithTop == 1) {
        _playOffSet = 0.0;
        _player.currentTime = 0;
    } else if (isStartWithTop == 0) {
        _player.currentTime = percentage * _player.duration;
        _playOffSet = scrollOffSet;
    }
    if (_playTimer) {
        [_playTimer setFireDate:[NSDate distantPast]];
    } else {
        self.playTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(playTimerAction:) userInfo:nil repeats:YES];
    }
        [_player play];
}

- (void)playPause
{
    [_player pause];
    [_playTimer setFireDate:[NSDate distantFuture]];
    isStartWithTop = 2;
}

- (void)playTimerAction:(id)sender
{
//    播放定时器 执行方法
    _playOffSet += 2;
    _scrollView.contentOffset = CGPointMake(_playOffSet, 0);
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self.playTimer invalidate];
    _playTimer = nil;
    isStartWithTop = 1;
    _playOffSet = 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"play" object:nil];
}

- (void)updateMeters
{
    //画笔 X 坐标
    _onceOffSet = _onceOffSet + 2;
//    NSLog(@"%f", _onceOffSet);
    _onceOffSetNum = [NSNumber numberWithFloat:_onceOffSet];
    if (_onceOffSet > [[UIScreen mainScreen] bounds].size.width) {
        [_offSetArray removeObjectAtIndex:0];
    }
    [_offSetComplete addObject:_onceOffSetNum];
    [_offSetArray addObject:_onceOffSetNum];
    
    //scrollView 自动滚动
    CGPoint newContentOffSet = self.scrollView.contentOffset;
    newContentOffSet.x += 2;
    self.scrollView.contentOffset = newContentOffSet;
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    if (_onceOffSet >= (self.frame.size.width - screenSize.width / 2)) {
        CGFloat width = self.frame.size.width + screenSize.width / 2;
        CGFloat hight = self.frame.size.height;
        _scrollView.contentSize = CGSizeMake(width, hight);
        self.frame = CGRectMake(0, 0, width, hight);
//        NSLog(@"%f,%f", _scrollView.contentSize.width,_scrollView.contentSize.height);
    }
    
    //    NSLog(@"%f", _onceOffSet);
    [self.record updateMeters];
    float linear = pow (30, [_record averagePowerForChannel:0] / 50);
//    _averagePower = level * 120;
    _averagePower = linear *80;
//    NSLog(@"%f", _averagePower);
    _averagePowerNum = [NSNumber numberWithFloat:_averagePower];
    if (_onceOffSet > [[UIScreen mainScreen] bounds].size.width) {
        [_averagePowerArray removeObjectAtIndex:0];
    }
    [_averagerPowerComplete addObject:_averagePowerNum];
    [_averagePowerArray addObject:_averagePowerNum];
    [self setNeedsDisplay];
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineCap(context, kCGLineCapSquare); //线条样式
    CGContextSetLineWidth(context, 1); //线条宽度
    CGContextSetRGBStrokeColor(context, 0.706, 0.706, 0.706, 1);
    CGContextBeginPath(context);
    if (_isDraft.boolValue == YES) {
        int offset = [UIScreen mainScreen].bounds.size.width /2;
        for (int i = 0; i < _draftWaveform.count; i++) {
            offset += 2;
            NSNumber *average = _draftWaveform[i];
            CGContextMoveToPoint(context, offset, (self.frame.size.height + 20) / 2 + average.intValue);
            CGContextAddLineToPoint(context, offset, (self.frame.size.height + 20) / 2 - average.intValue);
        }
    } else {
        if ([_record isRecording]) {
            for (int i = 0; i < [_offSetArray count]; i++) {
                NSNumber *offset = _offSetArray[i];
                NSNumber *average = _averagePowerArray[i];
                CGContextMoveToPoint(context, offset.intValue, (self.frame.size.height + 20) / 2 + average.intValue);
                CGContextAddLineToPoint(context, offset.intValue, (self.frame.size.height + 20) / 2 - average.intValue);
            }
        } else {
            for (int i = 0; i < _offSetComplete.count; i++) {
                NSNumber *offset = _offSetComplete[i];
                NSNumber *average = _averagerPowerComplete[i];
                CGContextMoveToPoint(context, offset.intValue, (self.frame.size.height + 20) / 2 + average.intValue);
                CGContextAddLineToPoint(context, offset.intValue, (self.frame.size.height + 20) / 2 - average.intValue);
            }
        }
    }
    CGContextStrokePath(context);
}
#pragma mark - 
#pragma mark scrollView 协议方法
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self playPause];
}
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    scrollOffSet = scrollView.contentOffset.x;
    percentage = scrollOffSet / waveLength;
    if (percentage == 1.0) {
        isStartWithTop = 1;
    } else {
        isStartWithTop = 0;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    scrollOffSet = scrollView.contentOffset.x;
//    NSLog(@"%.2f", scrollOffSet);
    percentage = scrollOffSet / waveLength;
//    NSLog(@"%.4f", percentage);
    if (percentage == 1.0) {
        isStartWithTop = 1;
    } else {
        isStartWithTop = 0;
    }
}
@end
