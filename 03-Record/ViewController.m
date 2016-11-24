//
//  ViewController.m
//  03-Record
//
//  Created by vera on 15/10/21.
//  Copyright © 2015年 vera. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Speech/Speech.h>
@interface ViewController ()<SFSpeechRecognitionTaskDelegate>

//录音
@property (nonatomic, strong) AVAudioRecorder *recorder;

//播放
@property (nonatomic, strong) AVAudioPlayer *player;

@property (weak, nonatomic) IBOutlet UITextView *textView;

@property(nonatomic,strong)NSArray *exclamations;

@end

@implementation ViewController

- (AVAudioRecorder *)recorder
{
    if (!_recorder)
    {
        //录音保存路径
        NSURL *fileUrl = [NSURL fileURLWithPath:[self recordPath]];
        
        /*
         initWithURL:录音保存的地址
         settings:录音设置
         */
        _recorder = [[AVAudioRecorder alloc] initWithURL:fileUrl settings:[self recordSettringParamter] error:nil];
    }
    
    return _recorder;
}

//初始化播放器
- (AVAudioPlayer *)player
{
    if (!_player)
    {
        _player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[self recordPath]] error:nil];
    }
    
    return _player;
}

//录音设置
- (NSDictionary *)recordSettringParamter
{
    //录音设置
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    //设置录音格式  AVFormatIDKey==kAudioFormatLinearPCM
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    //设置录音采样率(Hz) 如：AVSampleRateKey==8000/44100/96000（影响音频的质量）
    [recordSetting setValue:[NSNumber numberWithFloat:44100] forKey:AVSampleRateKey];
    //录音通道数  1 或 2
    [recordSetting setValue:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
    //线性采样位数  8、16、24、32
    [recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    //录音的质量
    [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
    
    return recordSetting;
}

///录音保存路径
- (NSString *)recordPath
{
    NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
//    NSLog(@"%@",documentPath);
    return [documentPath stringByAppendingPathComponent:@"test.aac"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _textView.text = @"语音输入... 点击按钮进入录音状态，松开手指，完成录音，自动转化为文字";
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
//        NSLog(@"%s  status %ld",__func__,(long)status);
    }];
}

/*
 touch down 手指按下会触发
 */
- (IBAction)startRecord:(id)sender
{
    NSLog(@"开始录音");
    
    //设置当前为录音模式
    //AVAudioSessionCategoryPlayAndRecord 录音和播放
    //AVAudioSessionCategoryRecord录音
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [session setActive:YES error:nil];
    
    //准备录音
    [self.recorder prepareToRecord];
    //录音
    [self.recorder record];
}

/*
 touch up inside 手指松开会触发
 */
- (IBAction)endRecord:(id)sender
{
    NSLog(@"停止录音");
    //停止录音
    [self.recorder stop];
    __weak typeof(self) weakSelf = self;
            //创建语音识别操作类对象
    SFSpeechRecognizer * rec = [[SFSpeechRecognizer alloc]init];
    NSURL *url = [NSURL fileURLWithPath:[weakSelf recordPath]];
    
    //通过一个音频路径创建音频识别请求
    SFSpeechRecognitionRequest * request = [[SFSpeechURLRecognitionRequest alloc]initWithURL:url];
    [rec recognitionTaskWithRequest:request delegate:self];
    
}


- (void)deleRecordAAC {
    
    NSFileManager* fileManager=[NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    //文件名
    NSString *uniquePath=[[paths objectAtIndex:0] stringByAppendingPathComponent:@"test.aac"];
    BOOL blHave=[[NSFileManager defaultManager] fileExistsAtPath:uniquePath];
    if (blHave == NO) {
    }else {
        BOOL blDele= [fileManager removeItemAtPath:uniquePath error:nil];
        if (blDele) {
            self.player = nil;
        }
        
    }
}
#pragma mark - 语音的代理方法-
- (void)speechRecognitionDidDetectSpeech:(SFSpeechRecognitionTask *)task {
    
    NSLog(@"检测到语音");

}
// Called for all recognitions, including non-final hypothesis
- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didHypothesizeTranscription:(SFTranscription *)transcription {
    NSLog(@"基本完成 语音转换  %@",transcription.formattedString);
    

}

// Called only for final recognitions of utterances. No more about the utterance will be reported
- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didFinishRecognition:(SFSpeechRecognitionResult *)recognitionResult {
    NSLog(@"完成录音转换   %@",recognitionResult.bestTranscription);
    NSMutableString  *targetString = [[NSMutableString alloc]init];
    
    for (int i = 0 ; i < recognitionResult.bestTranscription.segments.count; i ++) {
        SFTranscriptionSegment *currentSeg = recognitionResult.bestTranscription.segments[i];
        SFTranscriptionSegment *nextSeg = nil;
        if (i != recognitionResult.bestTranscription.segments.count - 1) {
           nextSeg = recognitionResult.bestTranscription.segments[i+1];
        }
        [targetString appendString:currentSeg.substring];
        [targetString appendString:[self appendStringWithTwoTime:currentSeg andEndSegment:nextSeg]];
    }
    _textView.text = targetString;
}

- (NSString *)appendStringWithTwoTime:(SFTranscriptionSegment *)startSegment andEndSegment:(SFTranscriptionSegment *)endSegment {
    NSTimeInterval interval = [self durationWithTwoTime:startSegment andEndSegment:endSegment];
    if (interval > 0.6) {
        return [self punctuationOfCurrentSpeechString:startSegment.substring];
    }else if(interval == 0) {
        return @".";
    }else {
        return @"";
    }
    
}

- (NSTimeInterval)durationWithTwoTime:(SFTranscriptionSegment *)startSegment andEndSegment:(SFTranscriptionSegment *)endSegment {
    if (endSegment == nil) return 0;
    NSTimeInterval startTime =  startSegment.timestamp;
    NSTimeInterval endTime = endSegment.timestamp;
    return  endTime - startTime;
}

// Called when the task is no longer accepting new audio but may be finishing final processing
- (void)speechRecognitionTaskFinishedReadingAudio:(SFSpeechRecognitionTask *)task {
    NSLog(@"不再接受其他任务");
}

// Called when the task has been cancelled, either by client app, the user, or the system
- (void)speechRecognitionTaskWasCancelled:(SFSpeechRecognitionTask *)task {
    
    NSLog(@"任务被取消");

}

// Called when recognition of all requested utterances is finished.
// If successfully is false, the error property of the task will contain error information
- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didFinishSuccessfully:(BOOL)successfully {
    
    NSLog(@"转换完成的时候");
    
}


- (NSString *)punctuationOfCurrentSpeechString:(NSString *)speechString {
    if (speechString.length == 0) return @"";
    NSString *lastString = [speechString substringFromIndex:speechString.length  - 1];
    _exclamations = @[@"啊",@"吧",@"呢",@"哈"];

    if ([lastString isEqualToString:@"啊"]) {
        return @"!";
    }else if ([lastString isEqualToString:@"吧"])
    {
        return @"~";
    }else if ([lastString isEqualToString:@"呢"]){
        return @"?";
    }else if ([lastString isEqualToString:@"哈"]) {
        return @"~~";
    }else {
        return @",";
    }
}



@end
