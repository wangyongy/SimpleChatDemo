//
//  UdpManager.m
//  SimpleChatDemo
//
//  Created by 王勇 on 2019/3/14.
//  Copyright © 2019年 王勇. All rights reserved.
//

#import "UdpManager.h"
#import "GCDAsyncUdpSocket.h"
#include <stdlib.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>

#define test_port  12000

#define test_host  @"10.208.61.53"

//#define UseGCDUdpSocket

@implementation MessageModel

- (instancetype)initWithMessage:(NSString *)message role:(NSInteger)role
{
    self = [super init];
    
    if (self) {
        
        self.role = role;
        
        self.message = message;
    }
    return self;
}

@end

@interface UdpManager ()<GCDAsyncUdpSocketDelegate>

{
    GCDAsyncUdpSocket *_receiveSocket;
    
    int _listenfd;
    
    struct sockaddr_in _addr;
    
    NSString * _destHost;
    
    NSInteger _destPort;
    
    void(^_sendBlock)(NSString *);
    
    dispatch_block_t _receiveBlock;
}

@property (nonatomic, strong) NSMutableArray <MessageModel *>* messageArray;

@end
@implementation UdpManager

#pragma mark - public
+ (void)initSocketWithReceiveHandle:(dispatch_block_t)receiveHandle
{
    
    [[self shareManager] initSocket];
    
    [UdpManager shareManager]->_receiveBlock = receiveHandle;
}

+ (NSMutableArray *)messageArray
{
    return [[self shareManager] messageArray];
}
+ (void)sendMessage:(NSString *)message
{
    [[self shareManager] sendMessage:message];
}
#pragma mark - private
- (void)initSocket
{
    _destHost = test_host;
    
    _destPort = test_port;
    
#ifdef UseGCDUdpSocket
    
    [self initGCDSocket];
    
#else
    
    //因为要一直循环调用recvfroml函数来接收消息，所以放在子线程中
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        [self initCSocket];
    });
    
#endif
    
}
- (void)initGCDSocket
{
    _receiveSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self
                                                   delegateQueue:dispatch_get_global_queue(0, 0)];
    NSError *error;
    
    // 绑定一个端口(可选),如果不绑定端口, 那么就会随机产生一个随机的唯一的端口
    // 端口数字范围(1024,2^16-1)
    [_receiveSocket bindToPort:test_port error:&error];
    
    if (error) {
        NSLog(@"服务器绑定失败");
    }
    // 开始接收对方发来的消息
    [_receiveSocket beginReceiving:nil];
}
- (void)initCSocket
{
    
    char receiveBuffer[1024];
    
    __uint32_t nSize = sizeof(struct sockaddr);
    
    if ((_listenfd = socket(AF_INET, SOCK_DGRAM, 0)) == -1)
    {
        /* handle exception */
        perror("socket() error. Failed to initiate a socket");
    }
    
    bzero(&_addr, sizeof(_addr));
    
    _addr.sin_family = AF_INET;
    
    _addr.sin_port = htons(_destPort);
    
    if(bind(_listenfd, (struct sockaddr *)&_addr, sizeof(_addr)) == -1)
    {
        perror("Bind() error.");
    }
    
    _addr.sin_addr.s_addr = inet_addr([_destHost UTF8String]);//ip可是是本服务器的ip，也可以用宏INADDR_ANY代替，代表0.0.0.0，表明所有地址
   
    while(true){
        
        long strLen = recvfrom(_listenfd, receiveBuffer, sizeof(receiveBuffer), 0, (struct sockaddr *)&_addr, &nSize);
        
        NSString * message = [[NSString alloc] initWithBytes:receiveBuffer length:strLen encoding:NSUTF8StringEncoding];

        _destPort = ntohs(_addr.sin_port);
        
        _destHost = [[NSString alloc] initWithUTF8String:inet_ntoa(_addr.sin_addr)];
        
        NSLog(@"来自%@---%zd:%@",_destHost,_destPort,message);
        
        [self.messageArray addObject:[[MessageModel alloc] initWithMessage:message role:0]];
        
        if (_receiveBlock) _receiveBlock();
    }
}
- (void)sendMessage:(NSString *)message
{
    NSData *sendData = [message dataUsingEncoding:NSUTF8StringEncoding];
    
    [self.messageArray addObject:[[MessageModel alloc] initWithMessage:message role:1]];
    
#ifdef UseGCDUdpSocket
    
    // 该函数只是启动一次发送 它本身不进行数据的发送, 而是让后台的线程慢慢的发送 也就是说这个函数调用完成后,数据并没有立刻发送,异步发送
    [_receiveSocket sendData:sendData toHost:_destHost port:_destPort withTimeout:60 tag:500];
    
#else
    
    sendto(_listenfd, [sendData bytes], [sendData length], 0, (struct sockaddr *)&_addr, sizeof(struct sockaddr));
    
#endif
}
- (NSMutableArray *)messageArray
{
    if (_messageArray == nil) {
        
        _messageArray = [NSMutableArray array];
    }
    
    return  _messageArray;
}

#pragma mark - GCDAsyncUdpSocketDelegate
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    _destPort = [GCDAsyncUdpSocket portFromAddress:address];
    
    _destHost = [GCDAsyncUdpSocket hostFromAddress:address];
    
    NSLog(@"来自%@---%zd:%@",_destHost,_destPort,message);
    
    [self.messageArray addObject:[[MessageModel alloc] initWithMessage:message role:0]];
    
    if (_receiveBlock) _receiveBlock();
}
#pragma mark - single
+ (instancetype)shareManager
{
    static dispatch_once_t onceToken;
    
    static id manager = nil;
    
    dispatch_once(&onceToken, ^{
        
        manager = [[self alloc] init];
    });
    
    return manager;
}
@end
