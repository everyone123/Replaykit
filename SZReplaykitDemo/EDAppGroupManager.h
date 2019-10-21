//
//  EDAppGroupManager.h
//  SZReplaykitDemo
//
//  Created by shizhongqiu on 2019/10/21.
//  Copyright © 2019 shizhongqiu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *const AppGroupUserDefault_SaveLog_Key = @"AppGroupUserDefault_SaveLog_Key";

@interface EDAppGroupManager : NSObject
// 初始化 manager
+ (instancetype)sharedInstance;

#pragma mark - - UserDefaults
- (BOOL)setObject:(nullable id)value forKey:(NSString *_Nullable)defaultName;

- (nullable id)objectForKey:(NSString *_Nullable)defaultName;

@end

NS_ASSUME_NONNULL_END

