//
//  QSSocketRecv.h
//  sockServer
//
//  Created by Chad Pro on 16/9/27.
//  Copyright © 2016年 gdy. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <string.h>

@interface QSSocketRecv : NSObject

+(NSMutableData *)recvData:(NSMutableData *)data withSocketID:(int)socketID;

@end
