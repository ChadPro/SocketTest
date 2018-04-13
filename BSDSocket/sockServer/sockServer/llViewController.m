//
//  llViewController.m
//  sockServer
//
//  Created by Chad Pro on 16/9/18.
//  Copyright © 2016年 gdy. All rights reserved.
//

#import "llViewController.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <string.h>

@interface llViewController ()

@end

@implementation llViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *siteString=@"33333";
    NSLog(@"%@",siteString);
    int fd=socket(AF_INET, SOCK_STREAM, 0);
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_len=sizeof(addr);
    addr.sin_family=AF_INET;
    addr.sin_port=htons(siteString.intValue);
    addr.sin_addr.s_addr=INADDR_ANY;
    
    int err = bind(fd, (const struct sockaddr *)&addr, sizeof(addr));
    if(err==0){
       err = listen(fd, 5);
        if(err==0){
            
          
            while(true){//循环监听
                //peeraddr是客户端的连接地址
                struct sockaddr_in peeraddr;
                int peerfd;
                socklen_t addrLen;
                addrLen=sizeof(peeraddr);
                //接受客户单的请求，并建立连接
                peerfd=accept(fd, (struct sockaddr *)&peeraddr, &addrLen);
                
                if(peerfd != -1){
                    char buf[1024];
                    //Byte buf[1024];
                    //Byte test[1024];
                    //long int numOfdatas=0;
                    ssize_t count;
                    //size_t len = sizeof(buf);
                    do{
                        count=recv(peerfd,buf, 1024, 0);//返回读取的字节数
  
                            NSData *testData=[[NSData alloc]initWithBytes:buf length:sizeof(buf)];
                            
                            NSString *receivedStr=[[NSString alloc]initWithData:testData encoding:NSUTF8StringEncoding];
                            
                            NSString* strMsg = [NSString stringWithFormat:@"client:=====%@\n",receivedStr];
                        NSLog(@"%@",strMsg);
                        
                    
                    }while(strcmp(buf, "close") != 0);
                }
                close(fd);
                NSLog(@"close");
            }

            
            
            
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
