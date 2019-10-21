//
//  BroadcastSetupViewController.m
//  SZReplayExtSetupUI
//
//  Created by shizhongqiu on 2019/2/26.
//  Copyright © 2019年 shizhongqiu. All rights reserved.
//

#import "BroadcastSetupViewController.h"

@implementation BroadcastSetupViewController

-(void)viewDidLoad {
    NSLog(@"ReplayExtSetupUI:ViewDidLoad");
}
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"ReplayExtSetupUI:viewWillAppear");
    // 必须调用[self userDidFinishSetup] ，调用进程里面的didFinishWithBroadcastController (下一步启动录制时用到)才能回调
    //必须在viewWillAppear中才能调用，在viewDidLoad中无法生效
    [self userDidFinishSetup];
    
}



// Call this method when the user has finished interacting with the view controller and a broadcast stream can start
- (void)userDidFinishSetup {
    
    NSLog(@"ReplayExtSetupUI:userDidFinishSetup");
    // URL of the resource where broadcast can be viewed that will be returned to the application
    NSURL *broadcastURL = [NSURL URLWithString:@"http://apple.com/broadcast/streamID"];
    
    // Dictionary with setup information that will be provided to broadcast extension when broadcast is started
    NSDictionary *setupInfo = @{ @"broadcastName" : @"example" };
    
    // Tell ReplayKit that the extension is finished setting up and can begin broadcasting
    [self.extensionContext completeRequestWithBroadcastURL:broadcastURL setupInfo:setupInfo];
}

- (void)userDidCancelSetup {
    // Tell ReplayKit that the extension was cancelled by the user
    [self.extensionContext cancelRequestWithError:[NSError errorWithDomain:@"YourAppDomain" code:-1 userInfo:nil]];
}

@end
