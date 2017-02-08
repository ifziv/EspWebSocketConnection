//  EspWebSocketConnection.m
//  WebSocketDemoForIOS
//
//  Created by 白 桦 on 9/21/15.
//  Copyright (c) 2015 白 桦. All rights reserved.
//

#import "EspWebSocketConnection.h"

#import "SRWebSocket.h"
#import "EspWebSocketState.h"

@interface EspWebSocketConnection()

@property (atomic, strong) __block NSCondition *condition;

@property (nonatomic, assign) __block BOOL isConnectSuc;

@property (nonatomic, assign) __block BOOL isConnectFinished;

@property (atomic, strong) SRWebSocket *websocket;

@property (nonatomic, strong) EspWebSocketState *webSocketState;

@property (nonatomic, strong) NSTimer *heartbeatTimer;

@property (nonatomic, strong) NSTimer *connectFailTimer;

@end

@implementation EspWebSocketConnection

- (id)init
{
    self = [super init];
    if (self) {
        self.isConnectFinished = NO;
        self.isConnectSuc = NO;
        self.condition = [[NSCondition alloc]init];
        self.websocket = nil;
        self.webSocketState = [[EspWebSocketState alloc]init];
    }
    return self;
}

- (void)dealloc
{
    [self disconnect];
}

- (void) __signal
{
    [self.condition lock];
    [self.condition signal];
    [self.condition unlock];
}

- (void) __wait
{
    [self.condition lock];
    [self.condition wait];
    [self.condition unlock];
}

- (void) __connectSuc
{
    self.isConnectFinished = YES;
    self.isConnectSuc = YES;
    [self.webSocketState setConnected];

    // wake up connect blocking thread
    [self __signal];
}

- (void) __connectFail
{
    self.isConnectFinished = YES;
    self.isConnectSuc = NO;
    [self.webSocketState setDisconnected];
    
    // wake up connect blocking thread
    [self __signal];
}

- (void) __clearConnectState
{
    self.isConnectFinished = NO;
    self.isConnectSuc = NO;
    [self.webSocketState setDisconnected];
}

#pragma SRWebSocketDelegate implement
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    NSLog(@"收到数据了，注意 message 是 id 类型的，学过C语言的都知道，id 是 (void *)void* 就厉害了，二进制数据都可以指着，不详细解释 void* 了");
    NSLog(@"我这后台约定的 message 是 json 格式数据收到数据，就按格式解析吧，然后把数据发给调用层");
    NSLog(@"message:%@",message);

    if ([self.delegate respondsToSelector:@selector(webSocket:didReceiveMessage:)])
    {
        NSLog(@"EspWebSocketConnection didReceiveMessage");
        [self.delegate webSocket:self didReceiveMessage:message];
    }
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    NSLog(@"连接成功，可以立刻登录你公司后台的服务器了，还有开启心跳");

    if ([self.delegate respondsToSelector:@selector(webSocketDidOpen:)])
    {
        NSLog(@"EspWebSocketConnection didOpen");
        [self.delegate webSocketDidOpen:self];
    }
    [self __connectSuc];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self sendHeartbeatConncetion];
        self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(sendHeartbeatConncetion) userInfo:nil repeats:true];
        [[NSRunLoop currentRunLoop] run];
        
    });
}

-(void)sendHeartbeatConncetion
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:@{@"name":@"zhiwei",@"pwd":@"hello006",@"macaddress":@"skajamaadas"} options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    [self sendTextMessage:jsonString];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    NSLog(@"连接失败，这里可以实现掉线自动重连，要注意以下几点");
    NSLog(@"1.判断当前网络环境，如果断网了就不要连了，等待网络到来，在发起重连");
    NSLog(@"2.判断调用层是否需要连接。");
    NSLog(@"3.连接次数限制，如果连接失败了，重试10次左右就可以了，不然就死循环了。或者每隔1，2，4，8，10，10秒重连...f(x) = f(x-1) * 2, (x<5)  f(x)=10, (x>=5)");
    if ([self.delegate respondsToSelector:@selector(webSocket:didFailWithError:)])
    {
        NSLog(@"EspWebSocketConnection didFail");
        [self.delegate webSocket:self didFailWithError:error];
    }
    if (!self.isConnectFinished)
    {
        [self __connectFail];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    NSLog(@"连接断开，清空socket对象，清空该清空的东西，还有关闭心跳！");
    if ([self.delegate respondsToSelector:@selector(webSocket:didCloseWithCode:reason:wasClean:)])
    {
        NSLog(@"EspWebSocketConnection didClose");
        [self.delegate webSocket:self didCloseWithCode:code reason:reason wasClean:wasClean];
    }
    if (!self.isConnectFinished)
    {
        [self __connectFail];
    }
    
    [self disconnect];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload
{
    NSLog(@"EspWebSocketConnection didReceivePong");
}

#pragma implement EspWebSocketConnectiong.h
- (void) connectWithUrl:(NSString *)wsUrl
{
    NSLog(@"EspWebSocketConnection connectWithUrl:%@",wsUrl);
    // disconnect current connection
    [self disconnect];
    
    NSURL *url = [NSURL URLWithString:wsUrl];
    
    // clear connect state
    [self __clearConnectState];
    
    // init ws
    self.websocket = [[SRWebSocket alloc]initWithURL:url];
    self.websocket.delegate = self;
    
    NSString *scheme = [url scheme];
    if (![scheme isEqualToString:@"ws"] && ![scheme isEqualToString:@"wss"])
    {
        NSLog(@"unsupported scheme for WebSockets URI");
        assert(0);
    }
    
    if ([[url port]intValue] == 9000)
    {
        if (![scheme isEqualToString:@"ws"])
        {
            NSLog(@"port 9000 only support ws");
            assert(0);
        }
    }
    else if ([[url port]intValue] == 9443)
    {
        if (![scheme isEqualToString:@"wss"])
        {
            NSLog(@"port 9443 only support wss");
            assert(0);
        }
    }
    // open
    [self.websocket open];
}

- (BOOL) connectBlockingWithUrl:(NSString*)wsUrl
{
    if ([[NSThread currentThread] isEqual:[NSThread mainThread]])
    {
        NSLog(@"don't call connectBlockingWithUrl in main Thread,call connectWithUrl instead of it");
        assert(0);
    }
    [self connectWithUrl:wsUrl];
    
    // blocking until connect suc or fail
    NSLog(@"EspWebSocketConnection wait start");
    [self __wait];
    NSLog(@"EspWebSocketConnection wait end");
    return self.isConnectSuc;
}

- (void) disconnect
{
    if (self.websocket!=nil)
    {
        self.websocket.delegate = nil;
        [self.websocket close];
        
        [self.heartbeatTimer invalidate];
        self.heartbeatTimer = nil;
        [self.webSocketState setDisconnected];
    }
}

- (void) sendBinaryMessage:(NSData *)data
{
    [self.websocket send:data];
}

- (void) sendTextMessage:(NSString *)message
{
    [self.websocket send:message];
}

@end
