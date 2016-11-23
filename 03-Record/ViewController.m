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
@interface ViewController ()

//录音
@property (nonatomic, strong) AVAudioRecorder *recorder;

//播放
@property (nonatomic, strong) AVAudioPlayer *player;

@property (weak, nonatomic) IBOutlet UITextView *textView;
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    
    //这个block会回调几次 ，所以这个删除方法也会删除几次 不过也没有什么影响
    [rec recognitionTaskWithRequest:request resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        //语音识别的结果字符串
        weakSelf.textView.text = result.bestTranscription.formattedString;
        [weakSelf deleRecordAAC];
    }];
}


- (void)deleRecordAAC {
    
    NSFileManager* fileManager=[NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    //文件名
    NSString *uniquePath=[[paths objectAtIndex:0] stringByAppendingPathComponent:@"test.aac"];
//    NSLog(@" uniquePath %@",uniquePath);
    BOOL blHave=[[NSFileManager defaultManager] fileExistsAtPath:uniquePath];
    if (blHave == NO) {
        NSLog(@"录音失败，本地没有保存写入的文件");
    }else {
        NSLog(@"录音成功，本地正常保存，即将删除");
        BOOL blDele= [fileManager removeItemAtPath:uniquePath error:nil];
        if (blDele) {
            self.player = nil;
            NSLog(@"本地录音删除成功");
        }else {
            NSLog(@"本地录音删除失败");
        }
        
    }
}


@end
