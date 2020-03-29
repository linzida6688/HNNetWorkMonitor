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
typedef NS_ENUM(NSUInteger,HiNowNetWorkStatus) {
    HiNowNetWorkStatus_Unknown = 0, //其他网络
    HiNowNetWorkStatus_None    = 1, //无网络
    HiNowNetWorkStatus_WiFi    = 2, //Wifi网络
    HiNowNetWorkStatus_WLAN    = 3, //蜂窝网络
};
typedef void(^HiNowNetWorkStatusBlock)(HiNowNetWorkStatus netStatus);
@interface UCNetClient : NSObject

#pragma mark - HiNow回调方法
@property(nonatomic, copy) HiNowNetWorkStatusBlock _Nullable hiNowNetWorkStatusBlock;

+ (instancetype _Nonnull)shareInstance;
- (int)registSdkWithAppKey:(NSString * _Nonnull)appkey
               publicToken:(NSString * _Nonnull)publicToken;
- (void)startDetect;
- (void)settingCustomerIpList:(NSArray *_Nullable)customerIpList;
- (void)settingUserDefineJsonFields:(NSString * _Nullable)fields;
- (void)closePingAndTracert;
- (void)closeAutoDetech;
@end
