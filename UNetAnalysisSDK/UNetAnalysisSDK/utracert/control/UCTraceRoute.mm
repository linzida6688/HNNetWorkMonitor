//
//  UTraceRoute.m
//  PingDemo
//
//  Created by ethan on 08/08/2018.
//  Copyright © 2018 ucloud. All rights reserved.
//

#import "UCTraceRoute.h"
#import "UNetAnalysisConst.h"
#include "log4cplus.h"
#import "UNetQueue.h"
#import "UCDateTool.h"


/**
 @brief 枚举定义，定义icmp包的状态

 - UCTracertIcmpType_None: 无状态
 - UCTracertIcmpType_NoReply: 路由节点无响应
 - UCTracertIcmpType_Receive: 路由节点接收到了icmp包
 - UCTracertIcmpType_Dest: 到达目的主机地址
 */
typedef NS_ENUM(NSUInteger,UCTracertIcmpType)
{
    UCTracertIcmpType_None,
    UCTracertIcmpType_NoReply,
    UCTracertIcmpType_Receive,
    UCTracertIcmpType_Dest
};

@interface UCTraceRoute()
{
    int socket_client;
    struct sockaddr_in  remote_addr;   // server address
}

@property (nonatomic,strong) NSMutableDictionary *sendIcmpPacketDateDict;
@property (nonatomic,strong) NSMutableArray *hostList;
@property (atomic,assign)  int hostArrayIndex;
@property (nonatomic,assign) BOOL isStopTracert;
@property (nonatomic,assign) UCTracertIcmpType lastRecTracertIcmpType;
@end

@implementation UCTraceRoute

- (instancetype)init
{
    if ([super init]) {
        self.hostArrayIndex = 0;
        
        _isStopTracert = NO;
        _hostList = [NSMutableArray array];
        _sendIcmpPacketDateDict = [NSMutableDictionary dictionary];
        _lastRecTracertIcmpType = UCTracertIcmpType_None;
    }
    return self;
}

- (void)stopTracert
{
    self.isStopTracert = YES;
}

- (BOOL)isTracert
{
    return !self.isStopTracert;
}

- (void)addSendIcmpPacketDateToContainerWithSeq:(int)seq
{
    NSString *key = [NSString stringWithFormat:@"TracertSendIcmpPacketDate%d",seq];
    [_sendIcmpPacketDateDict setObject:[NSDate date] forKey:key];
}

- (NSDate *)getSendIcmpPacketDateFromContainerWithSeq:(int)seq
{
    NSString *key = [NSString stringWithFormat:@"TracertSendIcmpPacketDate%d",seq];
    return [_sendIcmpPacketDateDict objectForKey:key];
}

- (void)settingUHostSocketAddressWithHost:(NSString *)host
{
    const char *hostaddr = [host UTF8String];
    memset(&remote_addr, 0, sizeof(remote_addr));
    remote_addr.sin_addr.s_addr = inet_addr(hostaddr);
    
    if (remote_addr.sin_addr.s_addr == INADDR_NONE) {
        struct hostent *remoteHost = gethostbyname(hostaddr);
        remote_addr.sin_addr = *(struct in_addr *)remoteHost->h_addr;
    }
    
    struct timeval timeout;
    timeout.tv_sec = 0;
    timeout.tv_usec = 1000*kIcmpPacketTimeoutTime;
    
    socket_client = socket(AF_INET,SOCK_DGRAM,IPPROTO_ICMP);
    int res = setsockopt(socket_client, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));
    if (res < 0) {
        log4cplus_warn("UNetTracert", "tracert %s , set timeout error..\n",[host UTF8String]);
    }
    remote_addr.sin_family = AF_INET;
}

- (BOOL)verificationHosts:(NSArray *)hosts
{
    for (int i = 0; i < hosts.count; i++) {
        NSArray *address = [UCNetDiagnosisHelper resolveHost:hosts[i]];
        if (address.count > 0) {
            NSString *ipAddress = [address firstObject];
            [_hostList addObject:ipAddress];
        }else{
            log4cplus_warn("UNetTracert", "access %s DNS error , remove this ip..\n",[hosts[i] UTF8String]);
        }
    }
    
    if (_hostList.count == 0) {
        return NO;
    }
    return YES;
}

- (void)startTracerouteHosts:(NSArray *)hostlist
{
    if (![self verificationHosts:hostlist]) {
        self.isStopTracert = YES;
        log4cplus_warn("UNetTracert", "there is no valid domain in the domain list , traceroute complete..\n");
        return;
    }
    self.hostArrayIndex = 0;
    
    [UNetQueue unet_trace_async:^{
        [self settingUHostSocketAddressWithHost:self.hostList[self.hostArrayIndex]];
        [self startTracert:self->socket_client andRemoteAddr:self->remote_addr];
    }];
}

- (void)startTracert:(int)socketClient andRemoteAddr:(struct sockaddr_in)remoteAddr
{
    if (self.isStopTracert) {
        return;
    }
    
    int ttl = 1;
    int continuousLossPacketRoute = 0;
    UCTracertIcmpType rec = UCTracertIcmpType_NoReply;
    log4cplus_info("UNetTracert", "begin tracert ip: %s",[self.hostList[self.hostArrayIndex] UTF8String]);
    do {
        rec = UCTracertIcmpType_NoReply;
        int setTtlRes = setsockopt(socketClient,
                                   IPPROTO_IP,
                                   IP_TTL,
                                   &ttl,sizeof(ttl));
        if (setTtlRes < 0) {
            log4cplus_warn("UNetTracert", "set TTL for icmp packet error..\n");
        }
        
        uint16_t identifier = (uint16_t)(5000 + self.hostArrayIndex + ttl);
        UICMPPacket_Tracert *packet = [UCNetDiagnosisHelper constructTracertICMPPacketWithSeq:ttl andIdentifier:identifier];
        
        for (int trytime= 0; trytime < kTracertSendIcmpPacketTimes; trytime++) {
            [self addSendIcmpPacketDateToContainerWithSeq:trytime];
            size_t sent = sendto(socketClient, packet, sizeof(UICMPPacket_Tracert), 0, (struct sockaddr *)&remoteAddr, sizeof(struct sockaddr_in));
            if ((int)sent < 0) {
                log4cplus_warn("UNetTracert", "send icmp packet failed, error info :%s\n",strerror(errno));
                continue;
            }
        }
        rec = [self receiverRemoteIpTracertRes:ttl];
        if (self.lastRecTracertIcmpType == UCTracertIcmpType_None) {
            self.lastRecTracertIcmpType = rec;
        }
        
        if (rec == UCTracertIcmpType_NoReply){
            continuousLossPacketRoute++;
            if (self.lastRecTracertIcmpType == UCTracertIcmpType_NoReply) {
                if (continuousLossPacketRoute == kTracertRouteCount_noRes) {
                    log4cplus_info("UNetTracert", "%d consecutive routes are not responding ,and end the tracert ip: %s\n",kTracertRouteCount_noRes,[self.hostList[self.hostArrayIndex] UTF8String]);
                    rec = UCTracertIcmpType_Dest;
                    self.lastRecTracertIcmpType = UCTracertIcmpType_None;
                    
                    UCTracerRouteResModel *record = [[UCTracerRouteResModel alloc] init:ttl+1 count:kTracertSendIcmpPacketTimes];
                    record.beginTime = [UCDateTool currentTimestamp];
                    record.dstIp = self.hostList[self.hostArrayIndex];
                    record.status = UCTracertStatus_Finish;
                    [self.delegate tracerouteWithUCTraceRoute:self tracertResult:record];
                }
            }
        }else{
            continuousLossPacketRoute = 0;
        }
        self.lastRecTracertIcmpType = rec;
        free(packet);
        usleep(500);
        
    } while (++ttl <= kTracertMaxTTL && (rec == UCTracertIcmpType_Receive || rec == UCTracertIcmpType_NoReply) && !self.isStopTracert);
    
    if (rec == UCTracertIcmpType_Dest) {
        log4cplus_info("UNetTracert", "done tracert , ip :%s",[self.hostList[self.hostArrayIndex] UTF8String]);
        self.hostArrayIndex++;
        
        if (self.hostArrayIndex == self.hostList.count) {
            log4cplus_info("UNetTracert", "complete tracert..\n");
            shutdown(socket_client, SHUT_RDWR);
            self.isStopTracert = YES;
            [self.delegate tracerouteFinishedWithUCTraceRoute:self];
            return;
        }
        [self settingUHostSocketAddressWithHost:self.hostList[self.hostArrayIndex]];
        [self startTracert:socket_client andRemoteAddr:remote_addr];
    }
}

- (UCTracertIcmpType)receiverRemoteIpTracertRes:(int)ttl
{
    UCTracertIcmpType res = UCTracertIcmpType_Receive;
    char buff[200];
    socklen_t addrLen = sizeof(struct sockaddr_in);
    
    UCTracerRouteResModel *record = [[UCTracerRouteResModel alloc] init:ttl count:kTracertSendIcmpPacketTimes];
    record.dstIp = self.hostList[self.hostArrayIndex];
    record.beginTime = [UCDateTool currentTimestamp];
    
    int tracert_recev_index = 0;
    int tracert_recev_route_index = 0;
    int reacert_recev_route_timeout_index = 0;
    while (YES) {
        size_t resultLen = recvfrom(socket_client, buff, sizeof(buff), 0, (struct sockaddr*)&remote_addr, &addrLen);
        if ((int)resultLen < 0) {
            reacert_recev_route_timeout_index++;
            if (reacert_recev_route_timeout_index == kTracertSendIcmpPacketTimes) {
                res = UCTracertIcmpType_NoReply;
                break;
            }
            continue;
        }else{
            NSString* remoteAddress = nil;
            char ip[INET_ADDRSTRLEN] = {0};
            inet_ntop(AF_INET, &((struct sockaddr_in *)&remote_addr)->sin_addr.s_addr, ip, sizeof(ip));
            remoteAddress = [NSString stringWithUTF8String:ip];
            
            // [remoteAddress isEqualToString:self.hostList[self.hostArrayIndex]]
            if ([UCNetDiagnosisHelper isTimeoutPacket:buff len:(int)resultLen]) {
                NSDate *startTime = [self getSendIcmpPacketDateFromContainerWithSeq:tracert_recev_route_index];
                NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:startTime];
                if (duration*1000 > kIcmpPacketTimeoutTime) {
                    duration = kIcmpPacketTimeoutTime/1000;
                }
                
                // Arriving at the intermediate routing node
                record.durations[tracert_recev_route_index] = duration;
                record.ip = remoteAddress;
//                log4cplus_info("UNetTracert", "tracert %s , duration:%f",[remoteAddress UTF8String],duration*1000);
                tracert_recev_route_index++;
                if (tracert_recev_route_index == kTracertSendIcmpPacketTimes) {
                    break;
                }
            }
            else if([UCNetDiagnosisHelper isValidPingResponseWithBuffer:(char *)buff len:(int)resultLen])
            {
                /*
                 这段逻辑用语避免ping的干扰。如果不加这段逻辑，可能会出现的现象是：
                 对一个ip列表做tracert和ping，那么在ping执行的过程中，会导致此时的tracert结果不准
                 
                 原因:
                 ping&tracert 同时做的时候，ping线程和tracert线程都会接到同一主机返回的icmp包，所以在此处过滤掉ping的icmp包
                 
                 注意:这种case一般是不容易被发现的，因为ping很快，只要ping做完之后，接下来的tracert就是正常的
                 */
            }
            else if ([UCNetDiagnosisHelper isEchoReplayPacket:buff len:(int)resultLen] && [remoteAddress isEqualToString:self.hostList[self.hostArrayIndex]])
            {
                // to dst server
                NSDate *startTime = [self getSendIcmpPacketDateFromContainerWithSeq:tracert_recev_index];
                NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:startTime];
                if (duration*1000 > kIcmpPacketTimeoutTime) {
                    duration = kIcmpPacketTimeoutTime/1000;
                }
                
                record.durations[tracert_recev_index] = duration;
                record.ip = remoteAddress;
                record.status = UCTracertStatus_Finish;
//                log4cplus_info("UNetTracert", "tracert %s , duration:%f",[remoteAddress UTF8String],duration*1000);
                tracert_recev_index++;
                if (tracert_recev_index == kTracertSendIcmpPacketTimes) {
                    close(socket_client);
                    res = UCTracertIcmpType_Dest;
                    
                    break;
                }
            } else {
                // failed
            }
        }
        
        usleep(500);
    }
    
    [self.delegate tracerouteWithUCTraceRoute:self tracertResult:record];
    return res;
}

@end
