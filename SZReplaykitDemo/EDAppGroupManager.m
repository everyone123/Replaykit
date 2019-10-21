//
//  EDAppGroupManager.m
//  SZReplaykitDemo
//
//  Created by shizhongqiu on 2019/10/21.
//  Copyright © 2019 shizhongqiu. All rights reserved.
//

#import "EDAppGroupManager.h"
static NSString * const groupId = @"group.com.company.test"; // 换成自己开发者账号对应的groups

@interface EDAppGroupManager ()
@property (nonatomic, strong) NSUserDefaults * appGroupUserDefaults;
@end

@implementation EDAppGroupManager

// 初始化 manager
static EDAppGroupManager *manager = nil;
+ (instancetype)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EDAppGroupManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.appGroupUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:groupId];
    }
    return self;
}

- (BOOL)setObject:(nullable id)value forKey:(NSString *_Nullable)defaultName{
    if (!value || !defaultName) {
        return NO;
    }
    [self.appGroupUserDefaults setObject:value forKey:defaultName];
    return YES;
}

- (nullable id)objectForKey:(NSString *_Nullable)defaultName{
    if (!defaultName) {
        return nil;
    }
    return [self.appGroupUserDefaults objectForKey:defaultName];
}

@end

