//
//  ViewController.m
//  EspWebSocketConnection
//
//  Created by zivInfo on 16/12/16.
//  Copyright © 2016年 xiwangtech.com. All rights reserved.
//

#import "ViewController.h"

#import "EspWebSocketConnection.h"

@interface ViewController ()
{
    EspWebSocketConnection *webSocketState;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    webSocketState = [[EspWebSocketConnection alloc]init];
    
    
    UIButton *btnLogin = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btnLogin.frame = CGRectMake(30.0, 175.0, 260.0, 45.0);
    [btnLogin setBackgroundColor:[UIColor colorWithRed:73.0/255.0 green:189.0/255.0 blue:204.0/255.0 alpha:1.0]];
    btnLogin.layer.cornerRadius = 4.0;
    [btnLogin setTitle:@"连接" forState:UIControlStateNormal];
    [btnLogin setTintColor:[UIColor whiteColor]];
    [btnLogin addTarget:self action:@selector(conncetion) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnLogin];
    
    UIButton *btnLogin1 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btnLogin1.frame = CGRectMake(30.0, 235.0, 260.0, 45.0);
    [btnLogin1 setBackgroundColor:[UIColor colorWithRed:73.0/255.0 green:189.0/255.0 blue:204.0/255.0 alpha:1.0]];
    btnLogin1.layer.cornerRadius = 4.0;
    [btnLogin1 setTitle:@"断开" forState:UIControlStateNormal];
    [btnLogin1 setTintColor:[UIColor whiteColor]];
    [btnLogin1 addTarget:self action:@selector(disConncetion) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnLogin1];
    
}

-(void)conncetion
{
    // ws://iot.espressif.cn:9000 is like http,
    // wss://iot.espressif.cn:9443 is like https
    NSString *url = @"ws://192.168.1.20:9502";
    [webSocketState connectWithUrl:url];

}

-(void)disConncetion
{
    [webSocketState disconnect];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
