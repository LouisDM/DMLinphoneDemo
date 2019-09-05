//
//  DMLinphoneManager.m
//  Demo4
//
//  Created by 辜东明 on 2019/5/22.
//  Copyright © 2019 iFREEGROUP. All rights reserved.
//

#import "DMLinphoneManager.h"


#import "Utils.h"

#define LC ([LinphoneManager getLc])
#define IFREEDOMAIN @"47.75.55.108:5060"//服务器地址
NSString *const ES_ON_REMOTE_OPEN_CEMERA = @"ES_ON_REMOTE_OPEN_CEMERA";
NSString *const ES_ON_CALL_COMMING = @"ES_ON_CALL_COMMING";
NSString *const ES_ON_CALL_END = @"ES_ON_CALL_END";
NSString *const ES_ON_CALL_STREAM_UPDATE = @"ES_ON_CALL_STREAM_UPDATE";

@interface DMLinphoneManager()

@property (nonatomic,weak)id<DMLinphoneManagerDelegateDelegate> delegate;

@end

@implementation DMLinphoneManager

static DMLinphoneManager* _instance = nil;

+(instancetype) instance
{
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        _instance = [[super allocWithZone:NULL] init] ;
    }) ;
    
    return _instance ;
}

+(id)allocWithZone:(struct _NSZone *)zone
{
    return [DMLinphoneManager instance];
}

-(id)copyWithZone:(struct _NSZone *)zone
{
    return [DMLinphoneManager instance];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[LinphoneManager instance] startLinphoneCore];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCallUpdate:) name:kLinphoneCallUpdate object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(registrationUpdate:) name:kLinphoneRegistrationUpdate object:nil];
        
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) logout {
    
    
    [[LinphoneManager instance] lpConfigSetBool:FALSE forKey:@"pushnotification_preference"];

    LinphoneSipTransports transportValue = {-1, -1, -1, -1};

    if (linphone_core_set_sip_transports(LC, &transportValue)) {
        NSLog(@"cannot set transport");
    }

    [[LinphoneManager instance] lpConfigSetString:@"" forKey:@"sharing_server_preference"];
    [[LinphoneManager instance] lpConfigSetBool:FALSE forKey:@"ice_preference"];
    [[LinphoneManager instance] lpConfigSetString:@"" forKey:@"stun_preference"];
    linphone_core_set_stun_server(LC, NULL);
    linphone_core_set_nat_policy(LC, NULL);
    
    linphone_core_clear_all_auth_info(LC);
    linphone_core_clear_proxy_config(LC);
    linphone_core_clear_call_logs(LC);
    
}

- (void) callToPhone: (NSString*) phone {
    LinphoneCall *call = [[LinphoneManager instance] callByUsername:phone];
    
    if (call == nil) {
        NSLog(@"拨打失败");
    } else {
        NSLog(@"正在拨叫...\naddress:%@", phone);
    }
}

- (void) acceptCall{
    LinphoneCall* currentcall = linphone_core_get_current_call(LC);
    if(currentcall){
        [[LinphoneManager instance] acceptCall:currentcall evenWithVideo:true];
    }
}

- (void) hangUpCall {
    LinphoneCore* lc = [LinphoneManager getLc];
    LinphoneCall* currentcall = linphone_core_get_current_call(lc);
    if (linphone_core_is_in_conference(lc) || // In conference
        (linphone_core_get_conference_size(lc) > 0) // Only one conf
        ) {
        linphone_core_terminate_conference(lc);
    } else if(currentcall != NULL) { // In a call
        linphone_call_terminate(currentcall);
    } else {
        const MSList* calls = linphone_core_get_calls(lc);
        if (bctbx_list_size(calls) == 1) { // Only one call
            linphone_call_terminate(currentcall);
        }
    }
    NSLog(@"挂断");
}

/**
 *  添加委托
 *
 *  @param delegate 委托
 */
- (void)addDelegate:(id<DMLinphoneManagerDelegateDelegate>)delegate{
    self.delegate = delegate;
}

/**
 *  移除委托
 *
 *  @param delegate 委托
 */
- (void)removeDelegate:(id<DMLinphoneManagerDelegateDelegate>)delegate{
    self.delegate = nil;
}

- (void)registrationUpdate: (NSNotification*) notification {
    NSDictionary* userInfo = [notification userInfo];
    NSLog(@"registrationUpdate:%@",userInfo);
    
    if([userInfo[@"state"] integerValue] == LinphoneRegistrationOk){
        NSLog(@"注册成功");
        if ([self.delegate respondsToSelector:@selector(DMLinphoneManagerRegistrationed)])
        {
            [self.delegate DMLinphoneManagerRegistrationed];
        }
    }if([userInfo[@"state"] integerValue] == LinphoneRegistrationCleared){
        NSLog(@"退出成功");
        if ([self.delegate respondsToSelector:@selector(DMLinphoneManagerCleared)])
        {
            [self.delegate DMLinphoneManagerCleared];
        }
    }
}

- (void)onCallUpdate: (NSNotification*) notification {
    NSDictionary* userInfo = [notification userInfo];
    NSValue* c = [userInfo valueForKey:@"call"];
    //    int state = (int)[userInfo valueForKey:@"state"];
    LinphoneCallState state = [[userInfo objectForKey:@"state"] intValue];
    NSString* message = [userInfo valueForKey:@"message"];
    NSLog(@"========== state: %d, message: %@", state, message);
    LinphoneCall* call = c.pointerValue;
    
    NSDictionary *dict = @{@"call" : [NSValue valueWithPointer:call],
                           @"state" : [NSNumber numberWithInt:state],
                           @"message" : message};
    NSLog(@"onCallUpdate dict:%@",dict);
    switch (state) {
        case LinphoneCallIncomingReceived:
            [NSNotificationCenter.defaultCenter postNotificationName:ES_ON_CALL_COMMING object: self userInfo:dict];
        case LinphoneCallOutgoingInit:
        case LinphoneCallConnected:
        case LinphoneCallStreamsRunning: {
            // check video
//            if (![self isVideoEnabled:call]) {
//                const LinphoneCallParams *param = linphone_call_get_current_params(call);
//                const LinphoneCallAppData *callAppData =
//                (__bridge const LinphoneCallAppData *)(linphone_call_get_user_data(call));
//                if (state == LinphoneCallStreamsRunning && callAppData->videoRequested &&
//                    linphone_call_params_low_bandwidth_enabled(param)) {
//                    // too bad video was not enabled because low bandwidth
//
//                    NSLog(@"带宽太低，无法开启视频通话");
//
//                    callAppData->videoRequested = FALSE; /*reset field*/
//                }
//            }
            [NSNotificationCenter.defaultCenter postNotificationName:ES_ON_CALL_STREAM_UPDATE object:self userInfo:dict];
            break;
        }
        case LinphoneCallUpdatedByRemote: {
//            const LinphoneCallParams *current = linphone_call_get_current_params(call);
//            const LinphoneCallParams *remote = linphone_call_get_remote_params(call);
//
//            /* remote wants to add video */
//            if ((linphone_core_video_display_enabled([LinphoneManager getLc]) && !linphone_call_params_video_enabled(current) &&
//                 linphone_call_params_video_enabled(remote)) &&
//                (!linphone_core_get_video_policy([LinphoneManager getLc])->automatically_accept ||
//                 (([UIApplication sharedApplication].applicationState != UIApplicationStateActive) &&
//                  floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_x_Max))) {
//                     linphone_call_defer_update(call);
//
//
//                     [NSNotificationCenter.defaultCenter postNotificationName:ES_ON_REMOTE_OPEN_CEMERA object: self userInfo:dict];
//
//                     //                     [self allowToOpenCameraByRemote:call];
//
//                 } else if (linphone_call_params_video_enabled(current) && !linphone_call_params_video_enabled(remote)) {
//
//                 }
            break;
        }
        case LinphoneCallUpdating:
            break;
        case LinphoneCallPausing:
        case LinphoneCallPaused:
            break;
        case LinphoneCallPausedByRemote:
            break;
        case LinphoneCallEnd://LinphoneCallEnd
            [NSNotificationCenter.defaultCenter postNotificationName:ES_ON_CALL_END object: self userInfo:NULL];
        case LinphoneCallError:
        default:
            break;
    }
    //区分上层逻辑代理
    switch (state) {
        case LinphoneCallOutgoingInit:
        {
            if ([self.delegate respondsToSelector:@selector(DMLinphoneManagerCallInit)])
            {
                [self.delegate DMLinphoneManagerCallInit];
            }
        }
            break;
        case LinphoneCallOutgoingEarlyMedia:
        {
            if ([self.delegate respondsToSelector:@selector(DMLinphoneManagerEarlyMedia)])
            {
                [self.delegate DMLinphoneManagerEarlyMedia];
            }
        }
            break;
        case LinphoneCallConnected:
        {
            if ([self.delegate respondsToSelector:@selector(DMLinphoneManagerConnected)])
            {
                [self.delegate DMLinphoneManagerConnected];
            }
        }
            break;
        case LinphoneCallError:
        {
            if ([self.delegate respondsToSelector:@selector(DMLinphoneManagerCallError)])
            {
                [self.delegate DMLinphoneManagerCallError];
            }
        }
            break;
        case LinphoneCallEnd:
        {
            if ([self.delegate respondsToSelector:@selector(DMLinphoneManagerCallEnd)])
            {
                [self.delegate DMLinphoneManagerCallEnd];
            }
        }
            break;
        case LinphoneCallReleased:
        {
            if ([self.delegate respondsToSelector:@selector(DMLinphoneManagerCallReleased)])
            {
                [self.delegate DMLinphoneManagerCallReleased];
            }
        }
            break;
        case LinphoneCallIncomingReceived:
        {
            NSLog(@"2232LinphoneCallIncomingReceived");
            LinphoneCall* currentcall = linphone_core_get_current_call(LC);
            if(currentcall){}
            const LinphoneAddress *addr = linphone_call_get_remote_address(currentcall);
            char *uri = linphone_address_as_string(addr);
            NSString *number = [NSString stringWithUTF8String:uri];
            ms_free(uri);
            NSLog(@"收到来电：%@",number);
            if ([self.delegate respondsToSelector:@selector(DMLinphoneManagerComingCall:)])
            {
                [self.delegate DMLinphoneManagerComingCall:number];
            }
            
        }
            break;
        case LinphoneCallIncomingEarlyMedia:
        {
            NSLog(@"2232LinphoneCallIncomingEarlyMedia");
        }
            break;
        case LinphoneCallStateIdle:
        case LinphoneCallStateOutgoingProgress:
        case LinphoneCallStateOutgoingRinging:
        case LinphoneCallStateStreamsRunning:
        case LinphoneCallStatePausing:
        case LinphoneCallStatePaused:
        case LinphoneCallStateResuming:
        case LinphoneCallStateReferred:
        case LinphoneCallStatePausedByRemote:
        case LinphoneCallStateUpdatedByRemote:
        case LinphoneCallStateUpdating:
        case LinphoneCallStateEarlyUpdatedByRemote:
        case LinphoneCallStateEarlyUpdating:
            break;
    }
    
}

- (void)callPhoneWithPhoneNumber:(NSString *)phone withVideo:(BOOL)video{
    LinphoneProxyConfig *cfg = linphone_core_get_default_proxy_config(LC);
    if (!cfg) {
        return;
    }
    LinphoneRegistrationState *state = (enum _LinphoneRegistrationState *)linphone_proxy_config_get_state(cfg);
    
    if (state == (enum _LinphoneRegistrationState *)LinphoneRegistrationNone) {
        NSLog(@"1");
    }
    if (state == (enum _LinphoneRegistrationState *)LinphoneRegistrationProgress) {
        NSLog(@"2");
    }
    if (state == (enum _LinphoneRegistrationState *)LinphoneRegistrationOk) {
        NSLog(@"3");
    }
    if (state == (enum _LinphoneRegistrationState *)LinphoneRegistrationCleared) {
        NSLog(@"4");
    }
    if (state == (enum _LinphoneRegistrationState *)LinphoneRegistrationFailed) {
        NSLog(@"5");
    }
    if (!phone || [phone isEqualToString:@""])
        return;
    LinphoneAddress *addr = [LinphoneUtils normalizeSipOrPhoneAddress:phone];
    NSString *string = [NSString stringWithUTF8String:linphone_address_as_string_uri_only(addr)];
    NSLog(@"%@",string);
    [LinphoneManager.instance call:addr];
    if (addr)
        linphone_address_unref(addr);
}


#pragma mark - 注册

- (void)registeByUserName:(NSString *)userName pwd:(NSString *)pwd{
    if(userName.length && pwd.length){
        [self registeByUserName:userName pwd:pwd domain:IFREEDOMAIN tramsport:@"udp"];
    }
}

- (void)registeByUserName:(NSString *)userName pwd:(NSString *)pwd domain:(NSString *)domain tramsport:(NSString *)transport{
    
    //设置超时
    linphone_core_set_inc_timeout(LC, 60);
    
    //部分手机本身端口问题 设置随机端口号
    LinphoneSipTransports transportValue = {-1, -1, -1, -1};
    
    linphone_core_set_sip_transports(LC, &transportValue);
    
    //创建配置表
    LinphoneProxyConfig *proxyCfg = linphone_core_create_proxy_config(LC);
    
    //初始化电话号码
    linphone_proxy_config_normalize_phone_number(proxyCfg,userName.UTF8String);
    
    //创建地址
    NSString *address = [NSString stringWithFormat:@"sip:%@@%@",userName,domain];//如:sip:123456@sip.com
    LinphoneAddress *identify = linphone_address_new(address.UTF8String);
    
    linphone_proxy_config_set_identity_address(proxyCfg, identify);
    
    linphone_proxy_config_set_route(
                                    proxyCfg,
                                    [NSString stringWithFormat:@"%s;transport=%s", domain.UTF8String, transport.lowercaseString.UTF8String]
                                    .UTF8String);
    linphone_proxy_config_set_server_addr(
                                          proxyCfg,
                                          [NSString stringWithFormat:@"%s;transport=%s", domain.UTF8String, transport.lowercaseString.UTF8String]
                                          .UTF8String);
    
    linphone_proxy_config_enable_register(proxyCfg, TRUE);
    
    
    //创建证书
    LinphoneAuthInfo *info = linphone_auth_info_new(userName.UTF8String, nil, pwd.UTF8String, nil, nil, linphone_address_get_domain(identify));
    
    //添加证书
    linphone_core_add_auth_info(LC, info);
    
    //销毁地址
    linphone_address_unref(identify);
    
    //注册
    linphone_proxy_config_enable_register(proxyCfg, 1);
    
    // 设置一个SIP路线  外呼必经之路
    linphone_proxy_config_set_route(proxyCfg,domain.UTF8String);
    
    //添加到配置表,添加到linphone_core
    linphone_core_add_proxy_config(LC, proxyCfg);
    
    //设置成默认配置表
    linphone_core_set_default_proxy_config(LC, proxyCfg);
    
    
    //设置音频编码格式
    [self synchronizeCodecs:linphone_core_get_audio_codecs(LC)];
    //设置视频编码格式
//    [self synchronizeVideoCodecs:linphone_core_get_video_codecs(LC)];
    
}
#pragma mark - 设置音频编码格式
- (void)synchronizeCodecs:(const MSList *)codecs {
    
    PayloadType *pt;
    const MSList *elem;
    
    for (elem = codecs; elem != NULL; elem = elem->next) {
        
        pt = (PayloadType *)elem->data;
        
        NSString *sreung = [NSString stringWithFormat:@"%s", pt->mime_type];
        NSString *normalBt = [NSString stringWithFormat:@"%d",pt->clock_rate];
        if ([sreung isEqualToString:@"speex"]) {
            
            linphone_core_enable_payload_type(LC,pt, YES);
            
        }
        else
        {
            
            linphone_core_enable_payload_type(LC, pt, 0);
        }
        bool_t abool = linphone_core_payload_type_enabled(LC, pt);
        
        NSLog(@"编码:%@,状态:%hhu",sreung,abool);
    }
    
}
//#pragma mark - 设置视频编码格式
//- (void)synchronizeVideoCodecs:(const MSList *)codecs {
//
//    PayloadType *pt;
//    const MSList *elem;
//
//    for (elem = codecs; elem != NULL; elem = elem->next) {
//
//        pt = (PayloadType *)elem->data;
//        NSString *sreung = [NSString stringWithFormat:@"%s", pt->mime_type];
//        if ([sreung isEqualToString:@"H264"]) {
//
//            linphone_core_enable_payload_type(LC, pt, 1);
//
//        }else {
//
//            linphone_core_enable_payload_type(LC, pt, 0);
//        }
//    }
//}

- (void)dtmf:(NSString *)dtmf{
    char* digit = (char*)[dtmf cStringUsingEncoding:NSUTF8StringEncoding];
    linphone_call_send_dtmf(linphone_core_get_current_call(LC), *digit);
}

- (void)setSpeaker:(BOOL)open{
    [LinphoneManager.instance setSpeakerEnabled:open];
}

- (void)setMute:(BOOL)mute{
    linphone_core_enable_mic(LC, mute);
}

- (NSString*)getCurrentCallId{
    LinphoneCall* call = linphone_core_get_current_call(LC);
    NSString *callId = @"";
    if(call){
        LinphoneCallLog *callLog = linphone_call_get_call_log(call);
        callId = [NSString stringWithUTF8String:linphone_call_log_get_call_id(callLog)];
        
    }
    return callId;
}

- (BOOL)resignActive{
    return [[LinphoneManager instance] resignActive];
}

- (NetworkType)network {
    return [[LinphoneManager instance] network];
}
@end
