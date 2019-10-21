//
//  EDNSLogManager.h
//  eDriveGWM
//
//  Created by shizhongqiu on 2019/9/12.
//  Copyright © 2019 carbit. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EDNSLogManager : NSObject
AS_SINGLETON(EDNSLogManager);

// 开始存储NSLOG
- (void)startSaveNSlog;

// 存储DeviceToken
- (void)storeDeviceToken:(NSString *)token;

// 存储UUID
- (void)storeUUID;

// 获取所有日志文件Path
- (NSArray *)getAllLogFilePath;

// 删除所有日志文件
- (void)deletAllLog;

// 存储崩溃信息
- (void)storeExceptionInfo:(NSString *)exceptionInfo;

@end

NS_ASSUME_NONNULL_END
