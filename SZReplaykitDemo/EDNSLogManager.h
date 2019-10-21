//
//  EDNSLogManager.h
//  eDriveGWM
//
//  Created by shizhongqiu on 2019/9/12.
//  Copyright © 2019 carbit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface EDNSLogManager : NSObject
// 初始化 manager
+ (instancetype)sharedInstance;

// 开始存储NSLOG
- (void)startSaveNSlog;

// 获取所有日志文件Path
- (NSArray *)getAllLogFilePath;

// 删除所有日志文件
- (void)deletAllLog;


@end

NS_ASSUME_NONNULL_END
