//
//  ViewController.m
//  ReplayKit录屏Demo
//
//  Created by Doris on 2017/7/19.
//  Copyright © 2017年 Doris. All rights reserved.
//

#import "ViewController.h"
#import <ReplayKit/ReplayKit.h>

@interface ViewController ()<RPScreenRecorderDelegate, RPPreviewViewControllerDelegate>
{
    NSInteger IsDecoderScreen;//记录是否正在录屏0-未录屏 1-录屏
    UIButton *startRecordScreenBtn;
    BOOL isSave;
}
@property (nonatomic,strong) RPPreviewViewController *RPPreview;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    startRecordScreenBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];
    startRecordScreenBtn.backgroundColor = [UIColor greenColor];
    startRecordScreenBtn.titleLabel.font = [UIFont systemFontOfSize:20];
    [startRecordScreenBtn setTitle:@"录屏" forState:UIControlStateNormal];
    [startRecordScreenBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [startRecordScreenBtn addTarget:self action:@selector(startRecoderTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startRecordScreenBtn];
}

- (void)startRecoderTouchUpInside:(UIButton *)sender{
    if ([sender.titleLabel.text isEqualToString:@"录屏"]) {
//        sender.backgroundColor = [UIColor redColor];
//        [sender setTitle:@"结束" forState:UIControlStateNormal];
        [sender setTitle:@"正在启动录屏..." forState:UIControlStateNormal];
        [self startRecoding];
    }else if([sender.titleLabel.text isEqualToString:@"结束录屏"]){
//        sender.backgroundColor = [UIColor greenColor];
//        [sender setTitle:@"录屏" forState:UIControlStateNormal];
        [sender setTitle:@"正在结束录屏..." forState:UIControlStateNormal];
        [self stopRecording];
    }
}

//开始录屏
- (void)startRecoding
{
    //将开启录屏功能的代码放在主线程执行
//    __weak typeof (self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[RPScreenRecorder sharedRecorder] isAvailable] && [self isSystemVersionOk]) { //判断硬件和ios版本是否支持录屏
            NSLog(@"支持ReplayKit录制");
            //这是录屏的类
            RPScreenRecorder* recorder = RPScreenRecorder.sharedRecorder;
            recorder.delegate = self;
            
            //开起录屏功能
            //9.0+函数(在10+版本被废弃,替换为startRecordingWithHandler:)
            [recorder startRecordingWithMicrophoneEnabled:YES handler:^(NSError * _Nullable error) {
                recorder.microphoneEnabled = YES;
                if (error) {
                    IsDecoderScreen = 0;
                    NSLog(@"========%@",error.description);
                    [self showAlert:@"录制失败" andMessage:@"启动录制失败请重试!"];
                    startRecordScreenBtn.backgroundColor = [UIColor greenColor];
                    [startRecordScreenBtn setTitle:@"录屏" forState:UIControlStateNormal];
                } else {
                    if (recorder.recording) {
                        startRecordScreenBtn.backgroundColor = [UIColor redColor];
                        [startRecordScreenBtn setTitle:@"结束录屏" forState:UIControlStateNormal];
                        //记录是否开始录屏 系统也有一个再带的检测是否在录屏的方法 (@property (nonatomic, readonly, getter=isRecording) BOOL recording;)
                        IsDecoderScreen = 1;
                    }
                }
            }];
            //10.0+函数
            //在此可以设置是否允许麦克风（传YES即是使用麦克风，传NO则不是用麦克风）
            //            recorder.microphoneEnabled = YES;
            //            recorder.cameraEnabled = YES;
//            [recorder startRecordingWithHandler:^(NSError * _Nullable error) {
//                
//                //在此可以设置是否允许麦克风（传YES即是使用麦克风，传NO则不是用麦克风）(ios 后被废弃了 下面的这个开始录屏)
//                //            [recorder startRecordingWithMicrophoneEnabled:YES handler:^(NSError * _Nullable error) {
//                recorder.microphoneEnabled = YES;
//                if (error) {
//                    IsDecoderScreen = 0;
//                    NSLog(@"========%@",error.description);
//                    [self showAlert:@"录制失败" andMessage:@"启动录制失败请重试!"];
//                    startRecordScreenBtn.backgroundColor = [UIColor greenColor];
//                    [startRecordScreenBtn setTitle:@"录屏" forState:UIControlStateNormal];
//                } else {
//                    if (recorder.recording) {
//                        startRecordScreenBtn.backgroundColor = [UIColor redColor];
//                        [startRecordScreenBtn setTitle:@"结束录屏" forState:UIControlStateNormal];
//                        //记录是否开始录屏 系统也有一个再带的检测是否在录屏的方法 (@property (nonatomic, readonly, getter=isRecording) BOOL recording;)
//                        IsDecoderScreen = 1;
//                    }
//                }
//            }];
        } else {
            [self showAlert:@"设备不支持录制" andMessage:@"升级ios系统"];
            return;
        }
    });
    
}

//结束录屏
- (void)stopRecording
{
    __weak typeof (self)weakSelf = self;
    [[RPScreenRecorder sharedRecorder] stopRecordingWithHandler:^(RPPreviewViewController *previewViewController, NSError *  error){
        _RPPreview = previewViewController;
        if (error) {
            NSLog(@"这里关闭有误%@",error.description);
            [self showAlert:@"结束录制失败" andMessage:@"本次保存失败!请重新录制"];
            startRecordScreenBtn.backgroundColor = [UIColor greenColor];
            [startRecordScreenBtn setTitle:@"录屏" forState:UIControlStateNormal];
        } else {
            [_RPPreview setPreviewControllerDelegate:self];
            startRecordScreenBtn.backgroundColor = [UIColor greenColor];
            [startRecordScreenBtn setTitle:@"录屏" forState:UIControlStateNormal];
            IsDecoderScreen = 0;
            //在结束录屏时显示预览画面
            [weakSelf showVideoPreviewController:_RPPreview withAnimation:YES];
        }
    }];
}

//显示视频预览页面,animation=是否要动画显示
- (void)showVideoPreviewController:(RPPreviewViewController *)previewController withAnimation:(BOOL)animation {
    if (previewController==nil) {
        return;
    }
    __weak typeof (self) weakSelf = self;
    //UI需要放到主线程
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect rect = previewController.view.frame;
        if (animation) {
            rect.origin.x += rect.size.width;
            previewController.view.frame = rect;
            rect.origin.x -= rect.size.width;
            [UIView animateWithDuration:0.3 animations:^(){
                previewController.view.frame = rect;
            } completion:^(BOOL finished){
            }];
        } else {
            previewController.view.frame = rect;
        }
        
        [weakSelf.view addSubview:previewController.view];
        [weakSelf addChildViewController:previewController];
    });
}

//关闭视频预览页面，animation=是否要动画显示
- (void)hideVideoPreviewController:(RPPreviewViewController *)previewController withAnimation:(BOOL)animation {
    //UI需要放到主线程
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect rect = previewController.view.frame;
        if (animation) {
            rect.origin.x += rect.size.width;
            [UIView animateWithDuration:0.3 animations:^(){
                previewController.view.frame = rect;
            } completion:^(BOOL finished){
                
                //移除页面
                [previewController.view removeFromSuperview];
                [previewController removeFromParentViewController];
            }];
        } else {
            //移除页面
            [previewController.view removeFromSuperview];
            [previewController removeFromParentViewController];
        }
    });
}

#pragma mark - RPPreviewViewControllerDelegate
//关闭的回调
- (void)previewControllerDidFinish:(RPPreviewViewController *)previewController {
    if (isSave == 1) {
        //这个地方我添加了一个延时,我发现这样保存不到系统相册的情况好多了
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self hideVideoPreviewController:_RPPreview withAnimation:YES];
        });
        
        isSave = 0;
    }else {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertAction *queding = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self hideVideoPreviewController:_RPPreview withAnimation:YES];
                //                dispatch_async(dispatch_get_main_queue(), ^{
                //                                [weakSelf.RPPreview dismissViewControllerAnimated:YES completion:nil];
                //                            });
                isSave = 0;
            }];
            UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"录制未保存\n确定要取消吗" preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:actionCancel];
            [alert addAction:queding];
            [self presentViewController:alert animated:NO completion:nil];
        });
    }
}
//选择了某些功能的回调（如分享和保存）
- (void)previewController:(RPPreviewViewController *)previewController didFinishWithActivityTypes:(NSSet <NSString *> *)activityTypes {
    __weak typeof (self)weakSelf = self;
    if ([activityTypes containsObject:@"com.apple.UIKit.activity.SaveToCameraRoll"]) {
        isSave = 1;
        NSLog(@"***************************");
        //这个地方我延时执行,等预览画面移除后再显示提示框
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf showAlert:@"保存成功" andMessage:@"已经保存到系统相册"];
                [self uploadVideoAsyn];//上传数据
            });
        });
    }
    if ([activityTypes containsObject:@"com.apple.UIKit.activity.CopyToPasteboard"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf showAlert:@"复制成功" andMessage:@"已经复制到粘贴板"];
        });
    }
}

#pragma mark ====RPScreenDelegate===
- (void)screenRecorderDidChangeAvailability:(RPScreenRecorder *)screenRecorder
{
    //    [screenRecorder addObserver:self forKeyPath:@"recording" options:NSKeyValueObservingOptionNew context:nil];
    //    [screenRecorder setValue:@"1" forKey:@"recording"];
    NSLog(@" delegate ======%@",screenRecorder);
}

- (void)screenRecorder:(RPScreenRecorder *)screenRecorder didStopRecordingWithError:(NSError *)error previewViewController:(nullable RPPreviewViewController *)previewViewController
{
    [_RPPreview setPreviewControllerDelegate:self];
    startRecordScreenBtn.backgroundColor = [UIColor greenColor];
    [startRecordScreenBtn setTitle:@"录屏" forState:UIControlStateNormal];
    IsDecoderScreen = 0;
    [self showVideoPreviewController:_RPPreview withAnimation:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"recording"]) {
        NSLog(@"keyPath === %@",object);
        if ([change valueForKey:@"recording"] == 0) {
            NSLog(@"可以录制");
        }else
        {
            NSLog(@"++++++++++++不可以");
        }
    }
}

//显示弹框提示
- (void)showAlert:(NSString *)title andMessage:(NSString *)message {
    if (!title) {
        title = @"";
    }
    if (!message) {
        message = @"";
    }
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleCancel handler:nil];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:actionCancel];
    [self presentViewController:alert animated:NO completion:nil];
}

//判断对应系统版本是否支持ReplayKit
- (BOOL)isSystemVersionOk {
    if ([[UIDevice currentDevice].systemVersion floatValue] < 9.0) {
        return NO;
    } else {
        return YES;
    }
}

- (void)uploadVideoAsyn{

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
