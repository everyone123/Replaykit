//
//  ViewController.m
//  SZReplaykitDemo
//
//  Created by shizhongqiu on 2019/2/26.
//  Copyright © 2019年 shizhongqiu. All rights reserved.
//

#import "ViewController.h"
#import "EDAppGroupManager.h"

#import <ReplayKit/ReplayKit.h>
#import "EDNSLogManager.h"
#import "EDExtNSLOGManager.h"

#define SYSTEM_VERSION_GE_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#define KScreenWidth [UIScreen mainScreen].bounds.size.width
#define KScreenHeight [UIScreen mainScreen].bounds.size.height

@interface ViewController ()<RPBroadcastActivityViewControllerDelegate, RPBroadcastControllerDelegate>
@property (nonatomic, weak)   RPBroadcastController *broadcastController;
@property (nonatomic, strong) UIButton *shareBtn;
@property (nonatomic, strong) UIWindow *overlayWindow;
@property (nonatomic, weak)   UIView   *cameraPreview;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"HostApp:当前VC ViewController");
    self.view.backgroundColor = [UIColor whiteColor];
    [self initUI];
    
}

-(void)initUI {
    NSLog(@"HostApp:初始化 UI");
    if(SYSTEM_VERSION_GE_TO(@"10.0")) {
        [self setupBroadcastUI];
    }
    
    self.shareBtn = [[UIButton alloc] initWithFrame:CGRectMake((KScreenWidth -100)/2, 100, 100, 100)];
    _shareBtn.backgroundColor = [UIColor greenColor];
    _shareBtn.layer.cornerRadius = 50;
    _shareBtn.layer.masksToBounds = YES;
    [_shareBtn setTitle:@"分享" forState:UIControlStateNormal];
    [_shareBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _shareBtn.titleLabel.font = [UIFont systemFontOfSize:18];
    [_shareBtn addTarget:self action:@selector(shareBtnClicked:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:_shareBtn];
    
    
    UIButton *testBtn = [[UIButton alloc] initWithFrame:CGRectMake((KScreenWidth -100)/2, 300, 100, 100)];
    testBtn.backgroundColor = [UIColor greenColor];
    testBtn.layer.cornerRadius = 50;
    testBtn.layer.masksToBounds = YES;
    [testBtn setTitle:@"获取日志" forState:UIControlStateNormal];
    [testBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    testBtn.titleLabel.font = [UIFont systemFontOfSize:18];
    [testBtn addTarget:self action:@selector(testBtnClicked:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:testBtn];
    
}

- (void)setupBroadcastUI {
    UIViewController *rootViewController = [[UIViewController alloc] init];
    self.overlayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.overlayWindow.hidden = NO;
    self.overlayWindow.userInteractionEnabled = NO;
    self.overlayWindow.backgroundColor = nil;
    self.overlayWindow.rootViewController = rootViewController;
    
    RPScreenRecorder * recorder = [RPScreenRecorder sharedRecorder];
    
    if([recorder respondsToSelector:@selector(setCameraEnabled:)]) {
        // This test will fail on devices < iOS 9
        [RPScreenRecorder sharedRecorder].microphoneEnabled = YES;
        [RPScreenRecorder sharedRecorder].cameraEnabled = YES;
        [[AVAudioSession sharedInstance] requestRecordPermission: ^(BOOL granted){
        }];
    }
}

-(void)shareBtnClicked:(UIButton *)btn {
    [self toggleBroadcast];
}

- (void)testBtnClicked:(UIButton *)btn {
    NSLog(@"HostApp:testBtnClicked");
    
    NSMutableArray * appLogArraym = [[NSMutableArray alloc] initWithArray:[[EDNSLogManager sharedInstance] getAllLogFilePath]];
    NSMutableArray * extLogArraym = [[NSMutableArray alloc] initWithArray:[EDExtNSLOGManager getAllLogFilePath]];
        [appLogArraym addObjectsFromArray:extLogArraym];
    
    NSArray * sortedPaths = [appLogArraym sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSString *firstPath = (NSString *)obj1;
        NSString *secondPath = (NSString *)obj2;
        NSString *firstFileName = [firstPath lastPathComponent];
        NSString *secondFileName = [secondPath lastPathComponent];
        return [firstFileName compare:secondFileName];
    }];
    // 读取其中一个文件的内容
    NSString *text = [NSString stringWithContentsOfFile:[sortedPaths lastObject] encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"所有的日志文件：%@",sortedPaths);
    
}

- (void)toggleBroadcast {
    __weak ViewController* bSelf = self;
    if (![RPScreenRecorder sharedRecorder].isRecording) {
        // iOS10中 由于录制作为一个外部的extension，可以供所有系统中app使用，所以不能直接启动这个录制的进程。需要首先启动支持录制的列表sheet
        [RPBroadcastActivityViewController loadBroadcastActivityViewControllerWithHandler:^(RPBroadcastActivityViewController * _Nullable broadcastActivityViewController, NSError * _Nullable error) {
            if (error) {
                NSLog(@"RPBroadcast err %@", [error localizedDescription]);
            }
            broadcastActivityViewController.delegate = bSelf;
            broadcastActivityViewController.modalPresentationStyle = UIModalPresentationPopover;
            [bSelf presentViewController:broadcastActivityViewController animated:YES completion:nil];
        }];
    } else {
        // We are currently broadcasting, disconnect.
        // 结束录屏
        NSLog(@"结束录屏");
        [self.broadcastController finishBroadcastWithHandler:^(NSError * _Nullable error) {
        }];
    }
}


#pragma mark - Broadcasting
- (void)broadcastActivityViewController:(RPBroadcastActivityViewController *) broadcastActivityViewController
       didFinishWithBroadcastController:(RPBroadcastController *)broadcastController
                                  error:(NSError *)error {
    
    // 回调中我们需要首先将sheet界面dismiss。 然后通过回调回来的broadcastController，调用接口启动录制，这里需要将broadcastController引用下来，用于我们在合适时机使用它结束录制
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [broadcastActivityViewController dismissViewControllerAnimated:YES
                                                            completion:nil];
    });
    
    NSLog(@"HostApp:BundleID %@", broadcastController.broadcastExtensionBundleID);
    self.broadcastController = broadcastController;
    if (error) {
        NSLog(@"BAC: %@ didFinishWBC: %@, err: %@",
              broadcastActivityViewController,
              broadcastController,
              error);
        return;
    }
    __weak ViewController* bSelf = self;
    [broadcastController startBroadcastWithHandler:^(NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
//            if (!error) {
//                bSelf.broadcastController.delegate = self;
//                bSelf.shareBtn.backgroundColor = [UIColor greenColor];
//
//                UIView* cameraView = [[RPScreenRecorder sharedRecorder] cameraPreviewView];
//                bSelf.cameraPreview = cameraView;
//                if(cameraView) {
//                    cameraView.frame = CGRectMake(30, 300, 164, 164);
//                    [bSelf.view addSubview:cameraView];
//                }
//            }
//            else {
//                bSelf.shareBtn.backgroundColor = [UIColor redColor];
//                NSLog(@"startBroadcast %@",error.localizedDescription);
//            }
        });
    }];
}

// Watch for service info from broadcast service
- (void)broadcastController:(RPBroadcastController *)broadcastController
       didUpdateServiceInfo:(NSDictionary <NSString *, NSObject <NSCoding> *> *)serviceInfo {
    NSLog(@"HostApp:didUpdateServiceInfo: %@", serviceInfo);
}

// Broadcast service encountered an error
- (void)broadcastController:(RPBroadcastController *)broadcastController
         didFinishWithError:(NSError *)error {
    NSLog(@"HostApp:didFinishWithError: %@", error);
}

@end
