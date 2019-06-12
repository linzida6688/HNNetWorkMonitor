//
//  UNetTools.h
//  UNetAnalysisSDK
//
//  Created by ethan on 2019/1/3.
//  Copyright © 2019 ucloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UNetTools : NSObject

/**
 判断字符串是否为空(内部使用)

 @param str 待拍判断的字符串
 @return YES:是空串； NO:非空串
 */
+ (BOOL)un_isEmpty:(NSString *)str;


/**
 @brief 把用户自定义的上报字段转化为json格式

 @param fields 用户自定义字段
 @return json字符串
 */
+ (NSString *)userDefinedFieldsConvertDictToJson:(NSDictionary *)fields;

/**
 @brief 校验用户可选上报字段(内部使用)

 @param fields 用户要上报的字段集合
 @return 如果返回nil，则表示上报字段内容合法；如果不为空，则返回内容即是非法信息。
 */
+ (NSString *)validOptReportField:(NSDictionary *)fields;


/**
 @brief 校验appkey(内部使用)

 @param appkey appkey
 @return YES:校验成功； NO:校验失败
 */
+ (BOOL)validAppkey:(NSString *)appkey;


/**
 @brief 校验RSA加密的公钥(内部使用)

 @param publicKey RSA公钥
 @return YES:校验通过； NO:校验失败
 */
+ (BOOL)validRSAPublicKey:(NSString *)publicKey;


/**
 @brief 校验ip地址(内部使用)

 @param ip ip地址
 @return YES:校验通过； NO:校验失败
 */
+ (BOOL)validIPAddress:(NSString *)ip;


/**
 @brief 格式化时区  GMT+8 => +0800

 @param gmtTime 时区
 @return 格式化后的时区
 */
+ (NSString *)formartTimeZone:(NSString *)gmtTime;


/**
 @brief 获取uuid

 @return uuid
 */
+ (NSString *)uuidStr;
@end

NS_ASSUME_NONNULL_END
