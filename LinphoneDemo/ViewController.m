//
//  ViewController.m
//  LinphoneDemo
//
//  Created by 辜东明 on 2019/9/5.
//  Copyright © 2019 iFREEGROUP. All rights reserved.
//

#import "ViewController.h"
#import "DMLinphoneManager.h"

@interface ViewController ()<DMLinphoneManagerDelegateDelegate>
@property (weak, nonatomic) IBOutlet UITextField *accountTextField;
@property (weak, nonatomic) IBOutlet UITextField *passworkTestField;

@property (weak, nonatomic) IBOutlet UITextField *numberTextField;
@property (weak, nonatomic) IBOutlet UILabel *stateLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[DMLinphoneManager instance] addDelegate:self];
    
}

-(void)dealloc{
    [[DMLinphoneManager instance] removeDelegate:self];
}

#pragma mark - Action

- (IBAction)registe:(UIButton *)sender {
    [[DMLinphoneManager instance] registeByUserName:self.accountTextField.text pwd:self.passworkTestField.text];
}

- (IBAction)exit:(UIButton *)sender {
    [[DMLinphoneManager instance] logout];
}

- (IBAction)hangup:(UIButton *)sender {
    [[DMLinphoneManager instance] hangUpCall];
}

- (IBAction)call:(UIButton *)sender {
    [[DMLinphoneManager instance] callToPhone:self.numberTextField.text];
}

- (IBAction)answer:(UIButton *)sender {
    [[DMLinphoneManager instance] acceptCall];
}

#pragma mark - DMLinphoneManagerDelegateDelegate

//sip账号成功注册
- (void)DMLinphoneManagerRegistrationed{
    
    self.stateLabel.text = @"注册成功";
}

- (void)DMLinphoneManagerCleared{
    self.stateLabel.text = @"退出成功";
}

//初始化
- (void)DMLinphoneManagerCallInit{
    self.stateLabel.text = @"初始化";
}

//振铃
- (void)DMLinphoneManagerEarlyMedia{
    self.stateLabel.text = @"振铃";
}

//接通
- (void)DMLinphoneManagerConnected{
    self.stateLabel.text = @"接通,通话中。。。";
}

//结束错误
- (void)DMLinphoneManagerCallError{
    self.stateLabel.text = @"结束错误";
}

//结束通话
- (void)DMLinphoneManagerCallEnd{
    self.stateLabel.text = @"结束通话";
}

//通话已释放
- (void)DMLinphoneManagerCallReleased{
    self.stateLabel.text = @"通话已释放";
}

- (void)DMLinphoneManagerComingCall:(NSString*)phone{
    self.stateLabel.text = [NSString stringWithFormat:@"收到来电：%@",phone];
}

@end
