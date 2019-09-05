//
//  DMLinphoneManager.h
//  Demo4
//
//  Created by 辜东明 on 2019/5/22.
//  Copyright © 2019 iFREEGROUP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LinphoneManager.h"

typedef struct LinphoneCall ESCall;

extern NSString *const ES_ON_REMOTE_OPEN_CEMERA;
extern NSString *const ES_ON_CALL_COMMING;
extern NSString *const ES_ON_CALL_END;
extern NSString *const ES_ON_CALL_STREAM_UPDATE;


@protocol DMLinphoneManagerDelegateDelegate <NSObject>

@optional

//sip账号成功注册
- (void)DMLinphoneManagerRegistrationed;

//sip账号成功退出
- (void)DMLinphoneManagerCleared;

//初始化
- (void)DMLinphoneManagerCallInit;

//振铃
- (void)DMLinphoneManagerEarlyMedia;

//接通
- (void)DMLinphoneManagerConnected;

//结束错误
- (void)DMLinphoneManagerCallError;

//结束通话
- (void)DMLinphoneManagerCallEnd;

//通话已释放
- (void)DMLinphoneManagerCallReleased;

//收到来电
- (void)DMLinphoneManagerComingCall:(NSString*)phone;

@end

@interface DMLinphoneManager : NSObject

/**
 单例
 
 @return 返回实例
 */
+ (instancetype) instance;

/**
 *  添加委托
 *
 *  @param delegate 委托
 */
- (void)addDelegate:(id<DMLinphoneManagerDelegateDelegate>)delegate;

/**
 *  移除委托
 *
 *  @param delegate 委托
 */
- (void)removeDelegate:(id<DMLinphoneManagerDelegateDelegate>)delegate;

/**
 登录sip服务器
 @param username 用户名
 @param pwd 密码
 @param displayName 显示名
 */

- (void)registeByUserName:(NSString *)userName pwd:(NSString *)pwd;
/**
 退出登录，注销账户
 */
- (void) logout;


/**
 拨打电话
 
 @param phone 用户名 （号码）
 */
- (void) callToPhone: (NSString*) phone;

/**
 接听电话
 */
- (void) acceptCall;
/**
 挂断
 */
- (void) hangUpCall;

/**
 是否注册
 */
- (BOOL)resignActive;

/**
 通话中输入数字
 */
- (void)dtmf:(NSString *)dtmf;

/**
 设置扬声器
 */
- (void)setSpeaker:(BOOL)open;

/**
 设置静音
 */
- (void)setMute:(BOOL)mute;

/**
 获取当前通话callid
 */
- (NSString*)getCurrentCallId;

/**
 当前网络状态
 */
- (NetworkType)network;

@end

