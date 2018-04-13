//
//  QSSocketSend.h
//  socketClientV1.0
//
//  Created by Chad Pro on 16/9/26.
//  Copyright © 2016年 ChadPro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <string.h>

@interface QSSocketSend : NSObject

+(long int)sendData:(int)socketID data:(NSData *)data len:(int)length;

@end
