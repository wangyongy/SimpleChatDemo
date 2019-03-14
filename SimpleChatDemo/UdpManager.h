//
//  UdpManager.h
//  SimpleChatDemo
//
//  Created by 王勇 on 2019/3/14.
//  Copyright © 2019年 王勇. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MessageModel:NSObject

@property (nonatomic, copy) NSString *message;

@property(nonatomic,assign) NSInteger role;

@end

@interface UdpManager : NSObject

+ (void)initSocketWithReceiveHandle:(dispatch_block_t)receiveHandle;

+ (void)sendMessage:(NSString *)message;

+ (NSMutableArray *)messageArray;

+ (instancetype)shareManager;
@end

NS_ASSUME_NONNULL_END
