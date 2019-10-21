//
//  SampleHandler.m
//  SZReplayExt
//
//  Created by shizhongqiu on 2019/2/26.
//  Copyright © 2019年 shizhongqiu. All rights reserved.
//


#import "SampleHandler.h"
#import "EDExtNSLOGManager.h"
@implementation SampleHandler

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
    // 存储extension app log
    [[EDExtNSLOGManager sharedInstance] startSaveNSlog];
    NSLog(@"ReplayExt:broadcastStartedWithSetupInfo:%@",setupInfo);
   
}

- (void)broadcastPaused {
    // User has requested to pause the broadcast. Samples will stop being delivered.
    NSLog(@"ReplayExt:broadcastPaused");
}

- (void)broadcastResumed {
    // User has requested to resume the broadcast. Samples delivery will resume.
    NSLog(@"ReplayExt:broadcastResumed");
}

- (void)broadcastFinished {
    // User has requested to finish the broadcast.
    NSLog(@"ReplayExt:broadcastFinished");
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    NSLog(@"ReplayExt:processSampleBuffer:%@ %d",sampleBuffer,sampleBufferType);
    switch (sampleBufferType) {
        case RPSampleBufferTypeVideo:
            // Handle video sample buffer
            break;
        case RPSampleBufferTypeAudioApp:
            // Handle audio sample buffer for app audio
            break;
        case RPSampleBufferTypeAudioMic:
            // Handle audio sample buffer for mic audio
            break;
            
        default:
            break;
    }
}

@end
