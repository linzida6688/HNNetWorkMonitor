//
//  UCNetClient.h
//  UNetAnalysisSDK
//
//  Created by ethan on 26/07/2018.
//  Copyright © 2018 ucloud. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger,UCTriggerDetectType)
{
    UCTriggerDetectType_Auto,
    UCTriggerDetectType_Manual
};

#pragma mark - HiNow回调方法
typedef NS_ENUM(NSUInteger,NetWorkStatus) {
    NetWorkStatus_Unknown = 0, //其他网络
    NetWorkStatus_None    = 1, //无网络
    NetWorkStatus_WiFi    = 2, //Wifi网络
    NetWorkStatus_WLAN    = 3, //蜂窝网络
};
typedef void(^NetWorkStatusBlock)(NetWorkStatus netStatus);
@interface UCNetClient : NSObject

#pragma mark - HiNow回调方法
@property(nonatomic, copy) NetWorkStatusBlock _Nullable netWorkStatusBlock;

+ (instancetype _Nonnull)shareInstance;
- (int)registSdkWithAppKey:(NSString * _Nonnull)appkey
               publicToken:(NSString * _Nonnull)publicToken;
- (void)startDetect;
- (void)settingCustomerIpList:(NSArray *_Nullable)customerIpList;
- (void)settingUserDefineJsonFields:(NSString * _Nullable)fields;
- (void)closePingAndTracert;
- (void)closeAutoDetech;
@end
