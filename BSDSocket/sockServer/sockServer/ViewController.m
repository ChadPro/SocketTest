//
//  ViewController.m
//  sockServer
//
//  Created by gdy on 2016/7/19.
//  Copyright © 2016年 gdy. All rights reserved.
//

#import "ViewController.h"

#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <string.h>


typedef NS_ENUM(NSInteger,ServerType) {
    ServerTypeTCP,
    ServerTypeUDP
};

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UITextField *textF;
@property (weak, nonatomic) IBOutlet UITextField *IPTextF;
@property (weak, nonatomic) IBOutlet UITextField *portTF;
@property (weak, nonatomic) IBOutlet UIButton *btnSend;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;


@property (nonatomic, assign)int fd;
@property (nonatomic, assign)int udpFd;

@property (nonatomic, assign)struct sockaddr_in ser_addr;

@property (nonatomic, assign)ServerType serType;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    Byte testByte[]={'1','2','3','4','5'};
    NSData *testData=[[NSData alloc]initWithBytes:testByte length:sizeof(testByte)];
    NSString *string=[[NSString alloc]initWithData:testData encoding:NSUTF8StringEncoding];
}
- (IBAction)btnClick:(id)sender {
    if (_textF.text.length == 0) {
        NSLog(@"内容为空");
        return;
    }
    else{
        if (self.serType == ServerTypeTCP) {
            ssize_t count = send(self.fd, [_textF.text UTF8String], 1024, 0);//返回发送的字节数
            NSString* strMsg = [NSString stringWithFormat:@"      %@~~~~~server\n",_textF.text];
            _textView.text = [_textView.text stringByAppendingString:strMsg];
        }
        else if(self.serType == ServerTypeUDP){
            struct sockaddr_in ser_addr;
            socklen_t addrlen=sizeof(struct sockaddr_in);
            bzero(&ser_addr,addrlen);
            ser_addr.sin_family=AF_INET;
            ser_addr.sin_addr.s_addr=inet_addr([_IPTextF.text UTF8String]);
            ser_addr.sin_port=htons(_portTF.text.intValue);
        
            ser_addr = self.ser_addr;
            sendto(self.udpFd,[_textF.text UTF8String],1024,0,(struct sockaddr*)&ser_addr,addrlen);
            
            NSString* logStr = [NSString stringWithFormat:@"     %@:~~~~~%@\n",_textF.text,_IPTextF.text];
            _textView.text = [_textView.text stringByAppendingString:logStr];
        }
    }
    
    _textF.text = nil;
}
- (IBAction)startServer:(id)sender {
    [NSThread detachNewThreadSelector:@selector(startTCPServer) toTarget:self withObject:nil];

}

- (IBAction)startUDPServer:(id)sender {
    //connect/recv/send都是阻塞式的，所以需要将这些操作放在非UI线程中进行。
    [NSThread detachNewThreadSelector:@selector(startUDPSer) toTarget:self withObject:nil];
}


- (void)startTCPServer{
    self.serType = ServerTypeTCP;
    //创建并初始化socket，返回socket的文件描述符（-1表示失败）
    /*
     AF_INET  地址描述，目前只支持这一种
     SOCK_STREAM  socket类型
     */
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    NSString* logStr = nil;
    if (fd == -1) {
        printf("创建socket失败...\n");
        logStr = @"创建socket失败...\n";
        dispatch_async(dispatch_get_main_queue(), ^{
            _textView.text = [_textView.text stringByAppendingString:logStr];
        });
        return;
    }
    else{
        printf("socket 创建成功... fd = %d\n",fd);
        logStr = @"创建socket成功...\n";
        dispatch_async(dispatch_get_main_queue(), ^{
            _textView.text = [_textView.text stringByAppendingString:logStr];
        });
    }
    
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_len = sizeof(addr);
    addr.sin_family = AF_INET;
    addr.sin_port = htons(_portTF.text.intValue);
    //addr.sin_addr.s_addr = inet_addr([_IPTextF.text UTF8String]);//0.0.0.0,本机任意地址（可能有多个网卡）
    addr.sin_addr.s_addr=INADDR_ANY;
    
    //将socket与特定主机和端口绑定
    int err = bind(fd, (const struct sockaddr *)&addr, sizeof(addr));
    if (err != 0) {
        printf("socket绑定失败...\n");
        logStr = @"socket绑定失败...\n";
        dispatch_async(dispatch_get_main_queue(), ^{
            _textView.text = [_textView.text stringByAppendingString:logStr];
        });
        return;
    }
    else{
        printf("socket绑定成功...\n");
        logStr = @"socket绑定成功...\n";
        dispatch_async(dispatch_get_main_queue(), ^{
            _textView.text = [_textView.text stringByAppendingString:logStr];
        });
    }
    
    //监听客户端的请求
    err = listen(fd, 5);//5：最大连接个数
    
    if (err != 0) {
        printf("监听失败...\n");
        logStr = @"监听失败...\n";
        dispatch_async(dispatch_get_main_queue(), ^{
            _textView.text = [_textView.text stringByAppendingString:logStr];
        });
        return;
    }
    else{
        printf("socket监听成功...\n");
        logStr = @"socket监听成功...\n";
        dispatch_async(dispatch_get_main_queue(), ^{
            _textView.text = [_textView.text stringByAppendingString:logStr];
        });
    }
    
    while(true){//循环监听
        NSLog(@"hello,world");
        struct sockaddr_in peeraddr;
        int peerfd;
        socklen_t addrLen;
        addrLen=sizeof(peeraddr);
        //接受客户单的请求，并建立连接
        peerfd=accept(fd, (struct sockaddr *)&peeraddr, &addrLen);//peeraddr是客户端的连接地址
        NSLog(@"test log");
        self.fd = peerfd;
        if(peerfd != -1){
            //char buf[1024];
            Byte buf[1024];
            Byte test[1024];
            NSMutableData *bufData=[[NSMutableData alloc]init];
            long int numOfdatas=0;
            ssize_t count;
            //size_t len = sizeof(buf);
            Byte midBuf[1024];
            int midBufLen=0;
            int numOflongBuf=0;
            do{
                ssize_t count=recv(peerfd,buf, 7, 0);//返回读取的字节数
                //*****************
                /*
                NSLog(@"recv byteNum=%zd",count);
                //NSString* receivedStr = [NSString stringWithUTF8String:buf];
                if(buf[0]=='q'&&buf[1]=='s'){
                int numPerBag=buf[2]*255+buf[3];
                numOfdatas=numOfdatas+numPerBag;
                int site=buf[4]*255*255*255+buf[5]*255*255+buf[6]*255+buf[7]-1;
                    NSLog(@"site=%d",site);
                for(int i=0;i<numPerBag;i++){
                    //test[site+i]=buf[site+i+8];
                    test[site*numPerBag+i]=buf[i+8];
                }
                }
                 */
                //********************
                
                
                //判断是否接收到数据
                if(count>0){
                    //上一buf尾部剩余加上新buf--longBuf[]
                    Byte longBuf[midBufLen+(int)count];
                    numOflongBuf=midBufLen+(int)count;                    if(1){
                        for(int i=0;i<midBufLen;i++){
                            longBuf[i]=midBuf[i];
                        }
                        for(int i=midBufLen;i<count+midBufLen;i++){
                            longBuf[i]=buf[i-midBufLen];
                        }
                       // NSLog(@"count=%zd",count);
                       // NSLog(@"longBufNum=%lu",sizeof(longBuf));
                        //解包
                        int totalByte=midBufLen+(int)count;
                       // NSLog(@"totalByte=%d",totalByte);
                        while (totalByte>0) {
                            if(longBuf[midBufLen+(int)count-totalByte]=='q'&&longBuf[midBufLen+(int)count-totalByte+1]=='s'){
                                NSLog(@"解包开始");
                                int numOfbag=longBuf[midBufLen+(int)count-totalByte+2]*255+longBuf[midBufLen+(int)count-totalByte+3];
                                NSLog(@"numOfbag=%d",numOfbag);
                                if(totalByte>=(numOfbag+8)){
                                int site=longBuf[midBufLen+(int)count-totalByte+4]*255*255*255+longBuf[midBufLen+(int)count-totalByte+5]*255*255+longBuf[midBufLen+(int)count-totalByte+6]*255+longBuf[midBufLen+(int)count-totalByte+7]-1;
                                    NSLog(@"site=%d",site);
                                for(int i=0;i<numOfbag;i++){
                                    test[site*numOfbag+i]=longBuf[i+8+midBufLen+(int)count-totalByte];
                                }
                                }else{
                                    midBufLen=totalByte;
                                    for(int j=0;j<midBufLen;j++){
                                        midBuf[j]=longBuf[numOflongBuf-midBufLen+j];
                                        
                                    }
                                    numOflongBuf=0;
                                    break;
                                }
                                totalByte=totalByte-numOfbag-8;
                            }
                            if(totalByte==0){
                                midBufLen=0;
                            }
                            
                        }
                    }
                    
                    
                    
                }
                
                
                
                
                
         //       NSLog(@"numOfdatas=%ld",numOfdatas);
         //       NSLog(@"test");
                
                if(1){
                NSData *testData=[[NSData alloc]initWithBytes:test length:20];

                NSString *receivedStr=[[NSString alloc]initWithData:testData encoding:NSUTF8StringEncoding];
                
                NSString* strMsg = [NSString stringWithFormat:@"client:=====%@\n",receivedStr];
                dispatch_async(dispatch_get_main_queue(), ^{
                    _textView.text = [_textView.text stringByAppendingString: strMsg];
                });
                }
            }while(strcmp(buf, "exit") != 0);
        }
        close(fd);
    
    }
}

-(int)lenOfbuf:(Byte *)bytes{
    int len=0;
    Byte b1=bytes[2];
    Byte b2=bytes[3];
    Byte b3=bytes[4];
    Byte b4=bytes[5];
    
    return len;
}

- (void)startUDPSer{
    self.serType = ServerTypeUDP;
    
    int ser_sockfd;
    size_t len;
    socklen_t addrlen;
    char buf[100];
    struct sockaddr_in ser_addr;
    /*建立socket*/
    ser_sockfd=socket(AF_INET,SOCK_DGRAM,0);
    self.udpFd = ser_sockfd;
    if(ser_sockfd<0)
    {
        printf("I cannot socket success\n");
        dispatch_async(dispatch_get_main_queue(), ^{
            _textView.text = [_textView.text stringByAppendingString:@"创建socke失败...\n"];
        });
        return;
    }
    else{
        dispatch_async(dispatch_get_main_queue(), ^{
            _textView.text = [_textView.text stringByAppendingString:@"创建socke成功...\n"];
        });
    }
    /*填写sockaddr_in 结构*/
    addrlen=sizeof(struct sockaddr_in);
    bzero(&ser_addr,addrlen);
    ser_addr.sin_family=AF_INET;
    ser_addr.sin_addr.s_addr=inet_addr([_IPTextF.text UTF8String]);
    ser_addr.sin_port=htons(_portTF.text.intValue);
    /*绑定客户端*/
    if(bind(ser_sockfd,(struct sockaddr *)&ser_addr,addrlen)<0)
    {
        printf("connect");
        dispatch_async(dispatch_get_main_queue(), ^{
            _textView.text = [_textView.text stringByAppendingString:@"绑定socke失败...\n"];
        });
        return;
    }
    else{
        dispatch_async(dispatch_get_main_queue(), ^{
            _textView.text = [_textView.text stringByAppendingString:@"绑定socke成功...\n"];
        });
    }
    
    while(1)
    {
        bzero(buf,sizeof(buf));
        len=recvfrom(ser_sockfd,buf,sizeof(buf),0,(struct sockaddr*)&ser_addr,&addrlen);
        
        self.ser_addr = ser_addr;//客户端地址
        
        NSString* fromStr = [NSString stringWithUTF8String:inet_ntoa(ser_addr.sin_addr)];
        NSString* strMsg = [fromStr stringByAppendingString:[NSString stringWithFormat:@"~~~~~~:%@\n",[NSString stringWithUTF8String:buf]]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _textView.text = [_textView.text stringByAppendingString:strMsg];
        });
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
