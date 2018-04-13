//
//  QSSocketSend.m
//  socketClientV1.0
//
//  Created by Chad Pro on 16/9/26.
//  Copyright © 2016年 ChadPro. All rights reserved.
//

#import "QSSocketSend.h"



@implementation QSSocketSend
/*
 *
 *传送数据data
 *发送长度len
 *实际总发送长度totalLen
 *打包后数据总长度dataTotalLen
*/
+(long int)sendData:(int)socketID data:(NSData *)data len:(int)length{
    
    
    //Byte *dataBytes=(Byte *)data.bytes;
    
    //初始化参数
    long int totalLen=0;
    int firstBagLen=14;
    int bagLen=0;
    int lastBagLen=0;
    int exitBagLen=5;
    //完整包数量
    long int bagsNum=data.length/length;
    NSLog(@"bags=%ld",bagsNum+1);
    //包长度
    bagLen=length+10;
    lastBagLen=data.length%length+10;
    //打包后总长度
    long int dataTotalLen=bagsNum*bagLen+lastBagLen+firstBagLen+exitBagLen;
    
    Byte dataBytes[data.length];
    [data getBytes:dataBytes length:data.length];

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
    Byte firstBagBytes[firstBagLen];
    //桢头
    firstBagBytes[0]=9;
    //数据总长度
    firstBagBytes[1]=data.length/255/255/255%255;
    firstBagBytes[2]=data.length/255/255%255;
    firstBagBytes[3]=data.length/255%255;
    firstBagBytes[4]=data.length%255;
    //数据包数量
    firstBagBytes[5]=(bagsNum+1)/255/255/255%255;
    firstBagBytes[6]=(bagsNum+1)/255/255%255;
    firstBagBytes[7]=(bagsNum+1)/255%255;
    firstBagBytes[8]=(bagsNum+1)%255;
    //完整包长度
    firstBagBytes[9]=length/255%255;
    firstBagBytes[10]=length%255;
    //last包长度
    firstBagBytes[11]=(lastBagLen-10)/255%255;
    firstBagBytes[12]=(lastBagLen-10)%255;
    //桢尾
    firstBagBytes[13]=10;
    //发送
    ssize_t firstBagCount=send(socketID, firstBagBytes,14, 0);
    totalLen=totalLen+(long int)firstBagCount;
    
    
    //**************数据包(完整)****************
    /*   字节数：bagLen
     *   1个字节桢头11
     *   4个字节地址信息
     *   4个字节的包序号
     *   1个字节桢尾12
     *
     */
    //用包序号做循环
    //NSLog(@"bagsNum=%ld",bagsNum);
    for(long int i=0;i<bagsNum;i++)
    {
    Byte bagBytes[bagLen];
    memset(bagBytes, 0, bagLen);
    //桢头
    bagBytes[0]=11;
    //地址信息（暂不使用）
    bagBytes[1]=0;
    bagBytes[2]=0;
    bagBytes[3]=0;
    bagBytes[4]=0;
    //包序号
    bagBytes[5]=(i+1)/255/255/255%255;
    bagBytes[6]=(i+1)/255/255%255;
    bagBytes[7]=(i+1)/255%255;
    bagBytes[8]=(i+1)%255;
    //包数据
        for(int j=0;j<length;j++){
            bagBytes[9+j]=dataBytes[i*length+j];
            //NSLog(@"%d",bagBytes[j+9]);
        }
    //桢尾
    bagBytes[bagLen-1]=12;
    //发送数据
   ssize_t bagCount=send(socketID, bagBytes, bagLen, 0);
        //NSLog(@"bag=%ld",i+1);
        //NSLog(@"bagCount=%ld",bagCount);
   totalLen=totalLen+(long int)bagCount;
    
    }
    
    //**************数据包(last包)****************
    /*   字节数：lastBagLen
     *   1个字节桢头13
     *   4个字节地址信息
     *   4个字节的包序号
     *   1个字节桢尾14
     *
     */
    Byte lastBagBytes[lastBagLen];
    memset(lastBagBytes, 0, lastBagLen);
    //头桢
    lastBagBytes[0]=13;
    //地址信息
    lastBagBytes[1]=0;
    lastBagBytes[2]=0;
    lastBagBytes[3]=0;
    lastBagBytes[4]=0;
    //包序号
    lastBagBytes[5]=(bagsNum+1)/255/255/255%255;
    lastBagBytes[6]=(bagsNum+1)/255/255%255;
    lastBagBytes[7]=(bagsNum+1)/255%255;
    lastBagBytes[8]=(bagsNum+1)%255;
    //包数据
    for(int i=0;i<lastBagLen;i++){
        lastBagBytes[9+i]=dataBytes[bagsNum*length+i];
    }
    //尾桢
    lastBagBytes[lastBagLen-1]=14;
    //发数据
    ssize_t lastBagCount=send(socketID, lastBagBytes, lastBagLen, 0);
    totalLen=totalLen+(long int)lastBagCount;
    //NSLog(@"lastBagCount=%ld",lastBagCount);
    
    //**************exit包****************
    /*   字节数：5
     *   1个字节桢头15
     *
     */
    Byte exitBagBytes[exitBagLen];
    exitBagBytes[0]=15;
    exitBagBytes[1]='e';
    exitBagBytes[2]='x';
    exitBagBytes[3]='i';
    exitBagBytes[4]='t';
    ssize_t exitBagCount=send(socketID, exitBagBytes, exitBagLen, 0);
    totalLen=totalLen+(long int)exitBagCount;
    //NSLog(@"exitBagCount=%ld",exitBagCount);
    
    
    //关闭socket连接
    close(socketID);
    
    //如果实际发送数据与打包总数据相等，返回数据量
    if (totalLen==dataTotalLen) {
        return totalLen;
    }
    
    return totalLen;
}



@end
