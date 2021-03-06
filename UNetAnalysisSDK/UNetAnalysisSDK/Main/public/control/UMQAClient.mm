//
//  UMQAClient.m
//  UNetAnalysisSDK
//
//  Created by ethan on 2018/10/9.
//  Copyright © 2018 ucloud. All rights reserved.
//

#import "UMQAClient.h"
#import "UNetAnalysisConst.h"
#import "UCNetClient.h"
#import "UNetTools.h"
#import "UNetAppInfo.h"
#import "log4cplus.h"
#import "UCNetLog.h"
#import <UIKit/UIKit.h>

@implementation UMQAClient

static UMQAClient *sdkManager_instance = nil;

+ (instancetype)shareInstance
{
    static dispatch_once_t ucloudNetAnalysis_onceToken;
    dispatch_once(&ucloudNetAnalysis_onceToken, ^{
        sdkManager_instance = [[super allocWithZone:NULL] init];
#pragma mark - HiNow回调方法
        [[UCNetClient shareInstance] setNetWorkStatusBlock:^(NetWorkStatus netStatus) {
            sdkManager_instance.netWorkStatus = (HiNowNetWorkStatus)netStatus;
            if(sdkManager_instance.hiNowNetWorkStatusBlock) {
                sdkManager_instance.hiNowNetWorkStatusBlock((HiNowNetWorkStatus)netStatus);
            }
        }];
    });
    return sdkManager_instance;
}

+(id)allocWithZone:(struct _NSZone *)zone
{
    return [UMQAClient shareInstance];
}

- (id)copyWithZone:(struct _NSZone *)zone
{
    return [UMQAClient shareInstance];
}

- (void)uNetSettingSDKLogLevel:(UCSDKLogLevel)logLevel
{
    [UCNetLog settingSDKLogLevel:logLevel];
}

+ (BOOL)validRegistParamsWithAppKey:(NSString *)appkey
                        appSecret:(NSString * _Nonnull)appSecret
                    completeHandler:(UCNetErrorHandler _Nonnull)completeHandler
{
    if (!completeHandler) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"no UCNetRegisterSdkCompleteHandler"
                                     userInfo:nil];
        return NO;
    }
    NSString *errorInfo = nil;
    if ([UNetTools un_isEmpty:appkey]) {
        errorInfo = @"no APPKEY";
    }else if(![UNetTools validAppkey:appkey]){
        errorInfo = @"APPKEY error";
    }
    else if ([UNetTools un_isEmpty:appSecret]) {
        errorInfo = @"no APPSECRET";
    }else if(![UNetTools validRSAPublicKey:appSecret]){
        errorInfo = @"APPSECRET error";
    }
    if (errorInfo) {
        log4cplus_warn("UNetSDK", "regist sdk error , error info->%s",[errorInfo UTF8String]);
        completeHandler([UCError sysErrorWithInvalidArgument:errorInfo]);
        return NO;
    }
    return YES;
}

- (void)uNetRegistSdkWithAppKey:(NSString * _Nonnull)appkey
                    appSecret:(NSString * _Nonnull)appSecret
                completeHandler:(UCNetErrorHandler _Nonnull)completeHandler
{
    
    if (![[self class] validRegistParamsWithAppKey:appkey appSecret:appSecret completeHandler:completeHandler]) {
        return;
    }
    int res = [[UCNetClient shareInstance] registSdkWithAppKey:appkey
                                                   publicToken:appSecret];
    if (res == 0) {
        completeHandler(nil);
    }
}

- (void)uNetSettingUserDefineFields:(NSDictionary<NSString*,NSString*> * _Nullable)fields
                            handler:(UCNetErrorHandler _Nonnull)handler
{
    if (!handler) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"no UCNetParamSettingHandler"
                                     userInfo:nil];
        return;
    }
    NSString *jsonFields = nil;
    if ([fields isKindOfClass:[NSDictionary class]] && fields.count > 0) {
        NSString *errorInfo = [UNetTools validOptReportField:fields];
        if(errorInfo){
            log4cplus_warn("UNetSDK", "setting user defined fields , error info->%s",[errorInfo UTF8String]);
            handler([UCError sysErrorWithInvalidArgument:errorInfo]);
            return;
        }
        log4cplus_debug("UNetSDK", "setting user defined field success...\n");
        handler(nil);
        jsonFields = [UNetTools userDefinedFieldsConvertDictToJson:fields];
        [[UCNetClient shareInstance] settingUserDefineJsonFields:jsonFields];
    }else{
        log4cplus_debug("UNetSDK", "does not setting user defined fields...\n");
    }
}

- (void)uNetCloseAutoDetectNet
{
    [[UCNetClient shareInstance] closeAutoDetech];
}

- (void)uNetSettingCustomerIpList:(NSArray *_Nullable)customerIpList
{
    [[UCNetClient shareInstance] settingCustomerIpList:customerIpList];
}

- (void)uNetStartDetect
{
    [[UCNetClient shareInstance] startDetect];
}

- (void)uNetStopDataCollectionWhenAppWillResignActive
{
    [[UCNetClient shareInstance] closePingAndTracert];
}

- (void)uNetAppDidEnterBackground
{
    if ([UNetAppInfo uIosVersion].intValue >= 12) {
        __block UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"UNetSDK_BK_Task" expirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        }];
    }
}

- (NSString * _Nonnull)uNetSdkVersion
{
    return KSDKVERSION;
}

@end
