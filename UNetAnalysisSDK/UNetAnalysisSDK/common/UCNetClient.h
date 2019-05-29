//
//  UCNetClient.h
//  UNetAnalysisSDK
//
//  Created by ethan on 26/07/2018.
//  Copyright © 2018 ucloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UCNetAnalysisManager.h"


@interface UCNetClient : NSObject

+ (instancetype _Nonnull)shareInstance;
- (int)registSdkWithAppKey:(NSString * _Nonnull)appkey
               publicToken:(NSString * _Nonnull)publicToken
         userDefinedFields:(NSDictionary * _Nullable)fields;
- (void)settingSDKLogLevel:(UCSDKLogLevel)logLevel;
- (void)settingCustomerIpList:(NSArray *_Nullable)customerIpList;
- (void)manualDiagNetStatus:(UCNetManualNetDiagCompleteHandler _Nonnull)completeHandler;
- (void)closePingAndTracert;
@end
