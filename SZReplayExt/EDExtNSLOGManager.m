//
//  EDExtNSLOGManager.m
//  SZReplaykitDemo
//
//  Created by shizhongqiu on 2019/10/21.
//  Copyright © 2019 shizhongqiu. All rights reserved.
//

#import "EDExtNSLOGManager.h"
#import "EDAppGroupManager.h"
#import <UIKit/UIKit.h>
#import "sys/utsname.h"
#include <sys/param.h>
#include <sys/mount.h>
#include <stdio.h>

static NSString * const groupId = @"group.com.company.test"; // 换成自己开发者账号对应的groups
static NSString * const EDNSLOGDocumentDirectory = @"RUNNINGLOG";
static float const EDFreeDiskLimit = 500 *1024 *1024;    //500M
static float const EDSingleFileLimit = 100 * 1024 *1024; //100M

@interface EDExtNSLOGManager ()
{
    FILE * _currentStdout;
    FILE * _currentStderr;
}
@property (nonatomic, strong) NSString *currentLogFilePath; // 当前日志文件Path

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSString *timeFlag; // 标示
@property (nonatomic, strong) NSString *appLaunchTime; // App启动时间

@end

@implementation EDExtNSLOGManager

static EDExtNSLOGManager *manager = nil;
+ (instancetype)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EDExtNSLOGManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSDateFormatter *format=[[NSDateFormatter alloc] init];
        format.timeZone=[NSTimeZone localTimeZone];
        format.dateFormat=@"HH.mm";
        self.timeFlag = [format stringFromDate:[NSDate date]];
        
        NSDateFormatter *format2=[[NSDateFormatter alloc] init];
        format2.timeZone=[NSTimeZone localTimeZone];
        format2.dateFormat=@"YYYY-MM-DD HH:mm";
        self.appLaunchTime = [format2 stringFromDate:[NSDate date]];
        
        NSFileManager *fmManager = [NSFileManager defaultManager];
        BOOL isExist = [fmManager fileExistsAtPath:[self getLogDirectory]];
        if (!isExist) {
            [fmManager createDirectoryAtPath:[self getLogDirectory] withIntermediateDirectories:YES attributes:nil error:nil];
        }

    }
    return self;
}

// 开启日志
- (void)startSaveNSlog {
    // 清除7天前的日志
    [self cleanBeforeLogWithDays:7];
    
    long long freeDiskSize = [self checkFreeDiskSpaceInBytes];
    if (freeDiskSize > EDFreeDiskLimit) {
        // 开启日志
        [self redirectNSlogToDocumentFolder];
    }else {
        // 关闭日志
        NSLog(@"存储空间不足，关闭日志存储");
        [self closeSaveNSLog];
    }
    
    // 打印app及系统信息
    [self printAppAndSystemInfo];
    

    __weak typeof(self) weakSelf = self;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:30*60 repeats:YES block:^(NSTimer * _Nonnull timer) {
        __strong typeof(self) self = weakSelf;
        // 如果当前文件大小 大于100M 另起文件
        long long fileSize = [self getFileSizeForPath:self.currentLogFilePath];
        
        if (fileSize > EDSingleFileLimit) {
            long long freeDiskSize = [self checkFreeDiskSpaceInBytes];
            if (freeDiskSize > EDFreeDiskLimit) {
                NSLog(@"当前文件大小达到上限 切换文件");
                [self closeSaveNSLog];
                [self redirectNSlogToDocumentFolder];
                NSLog(@"App启动时间:%@",self.appLaunchTime);
            }else{
                NSLog(@"存储空间不足，关闭日志存储");
                [self closeSaveNSLog];
            }
            
        }
    }];
    
}

//运行日志
- (void)redirectNSlogToDocumentFolder
{
    // 日志文件path
    NSString *documentDirectory = [self getLogDirectory];
    NSString *fileName = [self getLogFileName];
    
    NSString *logFilePath = [documentDirectory stringByAppendingPathComponent:fileName];
    
    // 先删除已经存在的文件
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    [defaultManager removeItemAtPath:logFilePath error:nil];
    
    // 将log输入到文件 记录当前文件流
    _currentStdout = freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stdout);
    _currentStderr = freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
    
    // 记录当前日志文件Path
    self.currentLogFilePath = logFilePath;
    
    [[EDAppGroupManager sharedInstance] setObject:logFilePath forKey:@"EDExtNSLOG_CurrentLogFilePath_Key"];
    
 
}

// 获取日志文件夹Path
- (NSString *)getLogDirectory {
    NSURL *appGroupUrl = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:groupId];
    NSString *docmentPath= [[appGroupUrl URLByAppendingPathComponent:EDNSLOGDocumentDirectory] path];
    return docmentPath;
}

// 获取日志文件名
- (NSString *)getLogFileName {
    
    NSDateFormatter *format=[[NSDateFormatter alloc] init];
    format.timeZone=[NSTimeZone localTimeZone];
    format.dateFormat=@"yyyy.MM.dd.HH.mm.ss";
    NSString *time=[format stringFromDate:[NSDate date]];
    NSString *fileName = [NSString stringWithFormat:@"RUNLOG %@&%@&Ext.txt",time,self.timeFlag];
    
    return fileName;
}

// 关闭日志存储
- (void)closeSaveNSLog {
    if (_currentStdout) {
       fclose(_currentStdout);
    }
    
    if (_currentStderr) {
        fclose(_currentStderr);
    }
    
}

#pragma mark - - 日志管理 获取/删除
// 为什么不使用实例方法
// 避免EDExtNSLOGManager在两个进程里各初始化一遍
// EDExtNSLOGManager 在extension app内初始化了，如果在app内使用EDExtNSLOGManager的实例方法，
// 也会再次初始化EDExtNSLOGManager，这样会造成一定的资源浪费
// 获取所有日志Path
+ (NSArray *)getAllLogFilePath {
    NSURL *appGroupUrl = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:groupId];
    NSString *documentsPath = [[appGroupUrl URLByAppendingPathComponent:EDNSLOGDocumentDirectory] path];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *allLogNameArray = [[[fileManager contentsOfDirectoryAtPath:documentsPath error:&error] reverseObjectEnumerator] allObjects];
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (NSString *fileName in allLogNameArray) {
        if ([[fileName pathExtension] isEqualToString:@"txt"]){
            [array addObject:[documentsPath stringByAppendingPathComponent:fileName]];
        }
    }
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)];
    NSArray *fileArray = [NSMutableArray arrayWithArray:[array sortedArrayUsingDescriptors:@[sortDescriptor]]];
    return fileArray;
    
}
// 删除所有日志
+ (void)deletAllLog{
    NSURL *appGroupUrl = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:groupId];
    NSString *documentsPath = [[appGroupUrl URLByAppendingPathComponent:EDNSLOGDocumentDirectory] path];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *allPath = [[[fm contentsOfDirectoryAtPath:documentsPath error:nil] reverseObjectEnumerator] allObjects];
    // 在App内执行delete方法时，重新初始化了manager，因而currentLogFilePath直接获取不到
    NSString *currentLog = [[EDAppGroupManager sharedInstance] objectForKey:@"EDExtNSLOG_CurrentLogFilePath_Key"];
    // 删除当前所有日志，除正在写入的日志外
    for (NSString *fileName in allPath) {
        if ([fileName containsString:@"RUNLOG"] && ![currentLog containsString:fileName]){
            NSString *logPath = [documentsPath stringByAppendingPathComponent:fileName];
            [fm removeItemAtPath:logPath error:nil];
        }

    }
    
}

#pragma mark - - 打印系统信息
// 打印系统信息
- (void)printAppAndSystemInfo {
    
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    
    NSLog(@"App版本 VersionName:%@ , VersionCode:%@ , 包名:%@",[infoDictionary objectForKey:@"CFBundleShortVersionString"],[infoDictionary objectForKey:@"CFBundleVersion"],[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"]);
    
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    NSLog(@"iOS系统版本:%@ , iPhone手机型号:%@",[[UIDevice currentDevice] systemVersion],deviceString);
}

#pragma mark - - 清除几天前的日志
// 清除几天前的日志
- (void)cleanBeforeLogWithDays:(int)days {
   
    NSString *documentsPath = [self getLogDirectory];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *allLogNameArray = [[[fileManager contentsOfDirectoryAtPath:documentsPath error:nil] reverseObjectEnumerator] allObjects];
    
    for (NSString *logName in allLogNameArray) {
        if ([logName containsString:@"RUNLOG"]){
            NSString *logPath = [documentsPath stringByAppendingPathComponent:logName];
            if ([fileManager fileExistsAtPath:logPath]){
                
                NSDate *logCreateDate = [[fileManager attributesOfItemAtPath:logPath error:nil] fileCreationDate];
                NSDate *currentDate = [NSDate date];
                NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
                NSDateComponents *delta = [calendar components:NSCalendarUnitDay fromDate:logCreateDate toDate:currentDate options:0];
                if (delta.day>days) {
                    [[NSFileManager defaultManager] removeItemAtPath:logPath error:nil];
                }
                
            }
        }
        
    }
    
    
}


#pragma mark - -  文件大小
// 获取文件的大小
- (long long)getFileSizeForPath:(NSString *)logPath {
    long long fileSize = 0;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:logPath]){
        fileSize = [[fileManager attributesOfItemAtPath:logPath error:nil] fileSize];
    }
    NSLog(@"当前文件大小:%lld",fileSize);
    return fileSize;
}

// 获取手机存储空间
- (long long)checkFreeDiskSpaceInBytes{
    struct statfs buf;
    long long freeSpace = -1;
    if (statfs("/var", &buf) >= 0) {
        freeSpace = (long long)(buf.f_bsize * buf.f_bavail);
    }
    NSLog(@"当前存储空间:%lld",freeSpace);
    return freeSpace;
}

@end

