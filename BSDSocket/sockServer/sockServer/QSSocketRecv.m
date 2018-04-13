//
//  QSSocketRecv.m
//  sockServer
//
//  Created by Chad Pro on 16/9/27.
//  Copyright © 2016年 gdy. All rights reserved.
//

#import "QSSocketRecv.h"

@implementation QSSocketRecv

+(NSMutableData *)recvData:(NSMutableData *)data withSocketID:(int)socketID{
    NSMutableData *byteData=[[NSMutableData alloc]init];
    
    //接受缓存
    Byte recvBuf[1024];
    //中间缓存
    Byte midBuf[1024];
    long int midBufLen=0;
    //合成缓存数组
    Byte mixBuf[2048];
    long int mixBufLen=0;
    //实际数据总长度
    long int dataLen=0;
    //数据包数量
    long int bagsNum=0;
    //完整包长度
    int bagLen=0;
    //last包长度
    int lastBagLen=0;
    //已经读取数据长度
    long int bytesLen=0;
    //接收状态
    BOOL state=YES;
    
    //循环接收
    do{
    //读取TCP缓存至recvBuf
    ssize_t recvCount=recv(socketID, recvBuf, 1024, 0);
    
    //判断是否有数据接收
    if(recvCount>0){
        //判断是否有中间缓存  ＊可改进＊
        if(midBufLen>0){
            for(int i=0;i<midBufLen;i++){
                mixBuf[i]=midBuf[i];
            }
            for (int i=0;i<recvCount;i++) {
                mixBuf[midBufLen+i]=recvBuf[i];
                mixBufLen=midBufLen+(long int)recvCount;
            }
        }else{
            for (int i=0;i<recvCount;i++) {
                mixBuf[i]=recvBuf[i];
        }
        }
        //*************开始解包**************
        //用bytesLen判断是否还有数据需要解包，如果没有再读入新数据
        while (bytesLen>0) {
            
        //**************头包****************
        /*   字节数：14
         *   1个字节桢头9
         *   4个字节的数据总长度 data.length
         *   4个字节的数据包总数量 (bagsNum+1)
         *   2个字节完整包长度
         *   2个字节last包长度
         *   1个字节桢尾10
         *
         */
        if (mixBuf[0]==9&&mixBufLen>13&&dataLen==0) {
            //读取实际数据总长度
            dataLen=mixBuf[1]*255*255*255+mixBuf[2]*255*255+mixBuf[3]*255+mixBuf[4];
            [byteData setLength:dataLen];
            [byteData resetBytesInRange:NSMakeRange(0, dataLen)];
            //读取数据包数量
            bagsNum=mixBuf[5]*255*255*255+mixBuf[6]*255*255+mixBuf[7]*255+mixBuf[8];
            //读取完整包长度
            bagLen=mixBuf[9]*255+mixBuf[10];
            //读取last包长度
            lastBagLen=mixBuf[11]*255+mixBuf[12];
            
            bytesLen=bytesLen+14;
          }
        
          //**************数据包(完整)****************
           /*   字节数：bagLen
            *   1个字节桢头11
            *   4个字节地址信息
            *   4个字节的包序号
            *   1个字节桢尾12
            *
           */
            //如果mixBuf剩余数据大于一个包长度，解包
            if((mixBufLen-bytesLen)>=bagLen&&mixBuf[bytesLen]==11&&dataLen>0){
                int bag=mixBuf[bytesLen+5]*255*255*255+mixBuf[bytesLen+6]*255*255+mixBuf[bytesLen+7]*255+mixBuf[bytesLen+8];
                Byte bagdata[bagLen-10];
                for(int i=0;i<bagLen;i++){
                    bagdata[i]=mixBuf[bytesLen+9+i];
                }
                [byteData replaceBytesInRange:NSMakeRange(bagLen*(bag-1), bagLen) withBytes:bagdata];
                bytesLen=bytesLen+bagLen;
            }
            
            //**************数据包(last包)****************
            /*   字节数：lastBagLen
             *   1个字节桢头13
             *   4个字节地址信息
             *   4个字节的包序号
             *   1个字节桢尾14
             *
             */
            if((mixBufLen-bytesLen)>=lastBagLen&&mixBuf[bytesLen]==13&&dataLen>0){
                int bag=mixBuf[bytesLen+5]*255*255*255+mixBuf[bytesLen+6]*255*255+mixBuf[bytesLen+7]*255+mixBuf[bytesLen+8];
                Byte bagdata[lastBagLen-10];
                for(int i=0;i<bagLen;i++){
                    bagdata[i]=mixBuf[bytesLen+9+i];
                }
                [byteData replaceBytesInRange:NSMakeRange(lastBagLen*(bag-1), lastBagLen) withBytes:bagdata];
                bytesLen=bytesLen+lastBagLen;
            }
            
            //**************exit包****************
            /*   字节数：5
             *   1个字节桢头15
             *
             */
            if(mixBuf[bytesLen]==15&&mixBuf[bytesLen+1]=='e'&&mixBuf[bytesLen=2]=='x'&&mixBuf[bytesLen+3]=='i'&&mixBuf[bytesLen+4]=='t'){
                //关闭循环
                state=FALSE;
                break;
            }
            
            //对剩余包的处理
            if(mixBuf[bytesLen]==11&&(mixBufLen-bytesLen)<bagLen){
                for(long int i=bytesLen;i<mixBufLen;i++){
                    midBuf[i-bytesLen]=mixBuf[i];
                }
                midBufLen=mixBufLen-bytesLen;
                break;
            }
            if(mixBuf[bytesLen]==13&&(mixBufLen-bytesLen)<lastBagLen){
                for(long int i=bytesLen;i<mixBufLen;i++){
                    midBuf[i-bytesLen]=mixBuf[i];
                }
                midBufLen=mixBufLen-bytesLen;
                break;
            }
        
       }
    }
        //关闭socket
        close(socketID);
        
    }while (state==FALSE);
    
    return byteData;
}

@end
