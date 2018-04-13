//
//  ViewController.m
//  sockClient
//
//  Created by gdy on 2016/7/19.
//  Copyright © 2016年 gdy. All rights reserved.
//

#import "ViewController.h"

#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <ifaddrs.h>

typedef NS_ENUM(NSInteger,ServerType) {
    ServerTypeTCP,
    ServerTypeUDP
};

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UITextField *textF;
@property (weak, nonatomic) IBOutlet UITextField *ipTF;
@property (weak, nonatomic) IBOutlet UITextField *portTF;

@property (nonatomic, assign)int fd;
@property (nonatomic, assign)int udpFd;

@property (nonatomic, assign)ServerType serType;



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //transimission test and just for a test
}

- (IBAction)connectServer:(id)sender {
    //[NSThread detachNewThreadSelector:@selector(connectSer) toTarget:self withObject:nil];
    dispatch_queue_t qqqq=dispatch_queue_create("haha.test",DISPATCH_QUEUE_SERIAL);
    dispatch_async(qqqq, ^{
    
        [self connectSer];
    });
}

- (void)connectSer{
    self.serType = ServerTypeTCP;
    
    int err;
    int fd=socket(AF_INET, SOCK_STREAM, 0);
    self.fd = fd;
    BOOL success=(fd!=-1);
    struct sockaddr_in addr;
    NSString* logStr = nil;
    if (success) {
        printf("socket success...\n");
        logStr = @"socket success...\n";
        dispatch_async(dispatch_get_main_queue(), ^{
            _textView.text = [_textView.text stringByAppendingString:logStr];
        });
        memset(&addr, 0, sizeof(addr));
        addr.sin_len=sizeof(addr);
        addr.sin_family=AF_INET;
        addr.sin_addr.s_addr=INADDR_ANY;
        //err=bind(fd, (const struct sockaddr *)&addr, sizeof(addr));
        err=0;
        success=(err==0);
    }
    if (success) {
        //============================================================================
        struct sockaddr_in peeraddr;
        memset(&peeraddr, 0, sizeof(peeraddr));
        peeraddr.sin_len=sizeof(peeraddr);
        peeraddr.sin_family=AF_INET;
        peeraddr.sin_port=htons(_portTF.text.intValue);
        //            peeraddr.sin_addr.s_addr=INADDR_ANY;
        peeraddr.sin_addr.s_addr=inet_addr([_ipTF.text UTF8String]);
        //            这个地址是服务器的地址，
        socklen_t addrLen;
        addrLen =sizeof(peeraddr);
        printf("connecting...\n");
        logStr = @"connecting...\n";
        dispatch_async(dispatch_get_main_queue(), ^{
            _textView.text = [_textView.text stringByAppendingString:logStr];
        });
        err=connect(fd, (struct sockaddr *)&peeraddr, addrLen);
        if(err==-1){
            perror("Network test...\n");
        }
        success=(err==0);
        if (success) {
            err =getsockname(fd, (struct sockaddr *)&addr, &addrLen);
            success=(err==0);
            if (success) {
                printf("connect success,local address:%s,port:%d...\n",inet_ntoa(addr.sin_addr),ntohs(addr.sin_port));
                logStr = [NSString stringWithFormat:@"connect success,local address:%@,port:%d...\n",[NSString stringWithUTF8String:inet_ntoa(addr.sin_addr)],ntohs(addr.sin_port)];
                dispatch_async(dispatch_get_main_queue(), ^{
                    _textView.text = [_textView.text stringByAppendingString:logStr];
                });
                
                char buf[1024];
                do {
                    recv(fd, buf, sizeof(buf), 0);
                    NSString* strMsg = [NSString stringWithFormat:@"      %@~~~~~:server\n",[NSString stringWithUTF8String:buf]];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        _textView.text = [_textView.text stringByAppendingString: strMsg];
                    });
                } while (strcmp(buf, "exit")!=0);
            }
        }
        else{
            NSLog(@"connect failed");
        }
    }

}


- (IBAction)connectUDPServer:(id)sender {
    [NSThread detachNewThreadSelector:@selector(connectUDPSer) toTarget:self withObject:nil];
}

- (void)connectUDPSer{
    self.serType = ServerTypeUDP;
    int cli_sockfd;
    int len;
    socklen_t addrlen;
    char seraddr[14];
    struct sockaddr_in cli_addr;
    char buffer[256];
    /* 建立socket*/
    cli_sockfd=socket(AF_INET,SOCK_DGRAM,0);
    self.udpFd = cli_sockfd;
    if(cli_sockfd<0)
    {
        printf("I cannot socket success\n");
        dispatch_async(dispatch_get_main_queue(), ^{
            _textView.text = [_textView.text stringByAppendingString:@"创建socket失败\n"];
        });
    }
    else{
        dispatch_async(dispatch_get_main_queue(), ^{
            _textView.text = [_textView.text stringByAppendingString:@"创建socket成功\n"];
        });
    }
    /* 填写sockaddr_in*/
    addrlen=sizeof(struct sockaddr_in);
    bzero(&cli_addr,addrlen);
    cli_addr.sin_family=AF_INET;
    cli_addr.sin_addr.s_addr=inet_addr([_ipTF.text UTF8String]);
    cli_addr.sin_port=htons(_portTF.text.intValue);
    bzero(buffer,sizeof(buffer));
    
    while(1){
        len=recvfrom(cli_sockfd,buffer,sizeof(buffer),0,(struct sockaddr*)&cli_addr,&addrlen);
        NSString *logStr = [NSString stringWithFormat:@"     %@:~~~~~%@\n",[NSString stringWithUTF8String:buffer],_ipTF.text];
        dispatch_async(dispatch_get_main_queue(), ^{
            _textView.text = [_textView.text stringByAppendingString:logStr];
        });
    }
}
/*分包发送函数
 *datas总数据
 *num每一包数据量
*/
-(void)sendData:(NSData *)datas numInBag:(int)num{
    //总数据数量numOfdata
    NSInteger numOfdata=[datas length];
    //包的数量numOfbag
    NSInteger numOfbag=numOfdata/num;
    //最后一包数据数量lastnumOfdata
    NSInteger lastnumOfdata=numOfdata%num;
    Byte *dataBytes=(Byte *)[datas bytes];
    //发送数据 bagnum--包的序号
    for(int bagnum=1;bagnum<numOfbag+1;bagnum++){
        Byte databyte[num+8];
        //起始标记qs--2个字节
        databyte[0]='q';
        databyte[1]='s';
        //数据长度--2个字节
        int b3=num/255%255;
        int b4=num%255;
        databyte[2]=b3;
        databyte[3]=b4;
        //数据位置起始位置 即包号bagnum
        int b5=bagnum/255/255/255%255;
        int b6=bagnum/255/255%255;
        int b7=bagnum/255%255;
        int b8=bagnum%255;
        databyte[4]=b5;
        databyte[5]=b6;
        databyte[6]=b7;
        databyte[7]=b8;
        //数据
        for(int ii=0;ii<num;ii++){
            databyte[ii+8]=dataBytes[(bagnum-1)*num+ii];
        }
        send(self.fd, databyte, num+8, 0);
    }
    
    //发送最后一包数据
    Byte lastBag[lastnumOfdata+8];
    //起始
    lastBag[0]='q';
    lastBag[1]='s';
    //数据长度
   long int b3=lastnumOfdata/255%255;
   long int b4=lastnumOfdata%255;
    lastBag[2]=b3;
    lastBag[3]=b4;
    //数据位置
    long int b5=(numOfbag+1)/255/255/255%255;
    long int b6=(numOfbag+1)/255/255%255;
    long int b7=(numOfbag+1)/255%255;
    long int b8=(numOfbag+1)%255;
    lastBag[4]=b5;
    lastBag[5]=b6;
    lastBag[6]=b7;
    lastBag[7]=b8;
    for(int ii=0;ii<lastnumOfdata;ii++){
        lastBag[ii+8]=dataBytes[(numOfbag)*num+ii];
    }
    ssize_t lastSend=send(self.fd, lastBag, lastnumOfdata+8, 0);
    //forTest 结束标志 待定
    Byte endBytes[3]={'e','n','d'};
   // ssize_t endSend=send(self.fd, endBytes, 3, 0);
    //NSLog(@"lastSend=%zd,endSend=%zd",lastSend,endSend);
}

- (IBAction)btnClick:(id)sender {
    //********************
    NSString *testString=@"helloworldLY";
    NSData *testData=[testString dataUsingEncoding:NSUTF8StringEncoding];
    [self sendData:testData numInBag:3];
//    char b1[3]="zsq";
//    char b2[3]="wan";
//    char b3[3]="xwm";
//    char b4[5]="close";
//    send(self.fd, b1, 1024, 0);
//    //[NSThread sleepForTimeInterval:1];
//    send(self.fd, b2, 1024, 0);
//    //[NSThread sleepForTimeInterval:1];
//    send(self.fd, b3, 1024, 0);
//    //[NSThread sleepForTimeInterval:1];
//    send(self.fd, b4, 1024, 0);
//    NSString *testString=@"helloworld";
//    NSData *testData=[testString dataUsingEncoding:NSUTF8StringEncoding];
//    Byte *testByte=(Byte *)[testData bytes];
//    
//    Byte byte1[7];
//    byte1[0]='0';
//    byte1[6]='2';
//    Byte byte2[7];
//    byte2[0]='1';
//    byte2[6]='3';
//    for(int i=0;i<5;i++){
//        byte1[i+1]=testByte[i];
//    }
//    for(int j=5;j<10;j++){
//        byte2[j-4]=testByte[j];
//    }
//    
//    send(self.fd, byte1, 7, 0);
//    send(self.fd, byte2, 7, 0);

    
    
    //send(self.fd,testByte, sizeof(testByte)+1, 0);
    //********************
//    NSString *testString1=@"123456789";
//    NSData *testData1=[testString1 dataUsingEncoding:NSUTF8StringEncoding];
//    send(self.fd,(__bridge const void*)testData1,[testData1 length],0);
    //********************
//    if (_textF.text.length == 0) {
//        NSLog(@"内容为空");
//        return;
//    }
//    else{
//        if (self.serType == ServerTypeTCP) {
//            
//            send(self.fd, [_textF.text UTF8String], 1024, 0);
//            NSString* strMsg = [NSString stringWithFormat:@"client:=====%@\n",_textF.text];
//            _textView.text = [_textView.text stringByAppendingString:strMsg];
//        }
//        else if(self.serType == ServerTypeUDP){
//            /* 填写sockaddr_in*/
//            struct sockaddr_in cli_addr;
//            socklen_t addrlen=sizeof(struct sockaddr_in);
//            bzero(&cli_addr,addrlen);
//            cli_addr.sin_family=AF_INET;
//            cli_addr.sin_addr.s_addr=inet_addr([_ipTF.text UTF8String]);
//            cli_addr.sin_port=htons(_portTF.text.intValue);
//            /* 将字符串传送给server端*/
//            sendto(self.udpFd,[_textF.text UTF8String],1024,0,(struct sockaddr*)&cli_addr,addrlen);
//            
//            
//            NSString* logStr = [NSString stringWithFormat:@"%@~~~~~: %@\n",[self getIPAddress],_textF.text];
//            _textView.text = [_textView.text stringByAppendingString:logStr];
//            
//        }
//        
//        _textF.text = nil;
//    }
}

- (NSString *)getIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
