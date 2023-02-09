//
//  ZJAppNetWork.m
//  ZJNetWork
//
//  Created by 张宇 on 2021/6/29.
//

#import "ZJAppNetWork.h"
#import <AFNetworking/AFNetworking.h>
#import "ZJMMKVManager.h"
#import <ZJAESEnDecrypt/ZJAESEnDecrypt.h>
#import "ZJAppNetWorkAgent.h"

/// 重新打印
#ifdef DEBUG
#define ZJNSLog(s, ...) printf("class: <%p %s:(%d) > method: %s \n%s\n", self, [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, __PRETTY_FUNCTION__, [[NSString stringWithFormat:(s), ##__VA_ARGS__] UTF8String] )
#define NSLog(...) NSLog(__VA_ARGS__);
#else
#define ZJNSLog(...)
#define NSLog(...)
#endif

static NSString *ZJNWServerErrorMsg = @"服务器异常";
static NSString *ZJNWAes128Key = @"payload";

@interface ZJAppNetWork ()

@property (nonatomic, copy, readwrite) NSString * requestId;
@property (nonatomic, strong, readwrite) ZJNetWorkResponseData * responseData;

/// 网络管理器
@property (nonatomic, strong) AFHTTPSessionManager *manager;

/// 当前运行的task
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;

@end

@implementation ZJAppNetWork

/// 开启网络请求访问
- (void)startRequest
{
    self.responseData = ZJNetWorkResponseData.alloc.init;
    
    /// 检查网络是否可以用 不可用不发起网络请求 并抛出异常提示
    if (![self checkNetworkIsAvailable]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(requestNETFaile:)]) {
                [self.delegate requestNETFaile:self];
            }
        });
        return;
    }
    
    /// 如果requestType = H5 默认开启缓存
    if (self.requestType == ZJNetWorkRequestTypeH5) {
        self.isCache = YES;
    }
    
    if (!_manager) {
        /// 配置安全协议
        self.manager.securityPolicy.validatesDomainName = self.validatesDomainName;

        /// 配置请求头类型+内容类型+token类型
        self.manager.requestSerializer = [self setRequestSerializerConfig];

        /// 配置接收类型 默认为json接收
        self.manager.responseSerializer = [self setResponseSerializerConfig];
        
        /// 入参URL地址优化处理
        self.requestUrl = [self setRequestURLConfig];
        
        self.isDebugLog = YES;
    }
    
    /// 入参优化处理
    self.parameters = [self setRequestParametersConfig];
    
    /// 访问唯一标识 暂用MMKV缓存Key
    self.requestId = [self setRequestIdConfig];
    
    [self gotoRequest];
    
    ZJNetWorkSingleton.shareSingleton.networkManager = self.manager;
}

- (void)cancleRequest
{
    if (_dataTask) {
        [ZJAppNetWorkAgent.sharedAgent removeRequest:self];
        [self.dataTask cancel];
    }
}

- (void)cancleAllRequest
{
    [ZJAppNetWorkAgent.sharedAgent removeRequest:self];
    for (NSURLSessionDataTask *dataTask in self.manager.dataTasks) {
        [dataTask cancel];
    }
}

/// 通过不同requestType调用不同的方法进行访问
- (void)gotoRequest
{
    /// 如果忽略缓存
    if (!self.isCache) {
        [self goOnRequest];
        return;
    }
    
    
    id localCache = [self archiveCache];
    /// 读取缓存为空
    if (!localCache) {
        [self goOnRequest];
        return;
    }
    
    /// 直接返回缓存并获取新数据更新缓存
    dispatch_async(dispatch_get_main_queue(), ^{
        [self successBlock:localCache dataType:ZJNetWorkResponseDataTypeCache];
    });
    
    [self goOnRequest];
}

/// 继续网络请求
- (void)goOnRequest
{
    /// 如果有可能取消当前的网络请求任务
    if (self.dataTask != nil && (self.dataTask.state == NSURLSessionTaskStateRunning || self.dataTask.state == NSURLSessionTaskStateSuspended)) {
        [self.dataTask cancel];
    }
    self.dataTask = nil;
    
    /// 发起网络请求
    switch (self.requestType) {
        case ZJNetWorkRequestTypePOST:
            [self POST];
            break;
        case ZJNetWorkRequestTypeGET:
            [self GET];
            break;
        case ZJNetWorkRequestTypeDELETE:
            [self DELETE];
            break;
        case ZJNetWorkRequestTypePUT:
            [self PUT];
            break;
        case ZJNetWorkRequestTypeBODY:
            [self BODY];
            break;
        case ZJNetWorkRequestTypePATCH:
            [self PATCH];
            break;
        case ZJNetWorkRequestTypeH5:
            [self H5];
            break;
        default:
            ZJNSLog(@"未配置对应访问方式");
            break;
    }
    
    ZJNetWorkSingleton.shareSingleton.networkManager = self.manager;
}

#pragma mark -- POST/GET/DELETE/PUT/BODY
#pragma mark --

- (void)POST
{
    __weak __typeof(self)weakSelf = self;
    __block NSURLSessionDataTask *dataTask;
    dataTask = [self.manager POST:self.requestUrl parameters:self.parameters headers:self.header progress:^(NSProgress * _Nonnull uploadProgress) {
        __strong __typeof(weakSelf)self = weakSelf; if (!self) return;
        
        if (dataTask != self.dataTask) { return; }
        [self progessBlock:uploadProgress];
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        __strong __typeof(weakSelf)self = weakSelf; if (!self) return;
        
        if (task != self.dataTask) { return; }
        [self handleRequestSuccess:responseObject];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        __strong __typeof(weakSelf)self = weakSelf; if (!self) return;
        
        if (task != self.dataTask) { return; }
        [self faileBlock:error message:ZJNWServerErrorMsg];
    }];
    self.dataTask = dataTask;
    /// 因为使用了__weak self 会导致启用了缓存的网络请求第一次回调过后就被释放了（如果外部不持有），更新缓存的网络请求无法继续执行下一步操作了，此时 self = nil
    [ZJAppNetWorkAgent.sharedAgent addRequest:self];
}

- (void)GET
{
    __weak __typeof(self)weakSelf = self;
    __block NSURLSessionDataTask *dataTask;
    dataTask = [self.manager GET:self.requestUrl parameters:self.parameters headers:self.header progress:^(NSProgress * _Nonnull uploadProgress) {
        __strong __typeof(weakSelf)self = weakSelf; if (!self) return;
        
        if (dataTask != self.dataTask) { return; }
        [self progessBlock:uploadProgress];
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        __strong __typeof(weakSelf)self = weakSelf; if (!self) return;
        
        if (task != self.dataTask) { return; }
        [self handleRequestSuccess:responseObject];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        __strong __typeof(weakSelf)self = weakSelf; if (!self) return;
        
        if (task != self.dataTask) { return; }
        [self faileBlock:error message:ZJNWServerErrorMsg];
    }];
    self.dataTask = dataTask;
    [ZJAppNetWorkAgent.sharedAgent addRequest:self];
}

- (void)DELETE
{
    __weak __typeof(self)weakSelf = self;
    NSURLSessionDataTask *dataTask;
    dataTask = [self.manager DELETE:self.requestUrl parameters:self.parameters headers:self.header success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        __strong __typeof(weakSelf)self = weakSelf; if (!self) return;
        
        if (task != self.dataTask) { return; }
        [self handleRequestSuccess:responseObject];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        __strong __typeof(weakSelf)self = weakSelf; if (!self) return;
        
        if (task != self.dataTask) { return; }
        [self faileBlock:error message:ZJNWServerErrorMsg];
    }];
    self.dataTask = dataTask;
    [ZJAppNetWorkAgent.sharedAgent addRequest:self];
}

- (void)PUT
{
    __weak __typeof(self)weakSelf = self;
    NSURLSessionDataTask *dataTask;
    dataTask = [self.manager PUT:self.requestUrl parameters:self.parameters headers:self.header success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        __strong __typeof(weakSelf)self = weakSelf; if (!self) return;
        
        if (task != self.dataTask) { return; }
        [self handleRequestSuccess:responseObject];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        __strong __typeof(weakSelf)self = weakSelf; if (!self) return;
        
        if (task != self.dataTask) { return; }
        [self faileBlock:error message:ZJNWServerErrorMsg];
    }];
    self.dataTask = dataTask;
    [ZJAppNetWorkAgent.sharedAgent addRequest:self];
}

- (void)BODY
{
    NSMutableURLRequest *request = [self setBodyRequestConfig];
    
    __weak __typeof(self)weakSelf = self;
    __block NSURLSessionDataTask *dataTask;
    dataTask = [self.manager dataTaskWithRequest:request uploadProgress:^(NSProgress * _Nonnull uploadProgress) {
        __strong __typeof(weakSelf)self = weakSelf; if (!self) return; if (!self) return;
        
        if (dataTask != self.dataTask) { return; }
        [self progessBlock:uploadProgress];
    } downloadProgress:^(NSProgress * _Nonnull downloadProgress) {
        __strong __typeof(weakSelf)self = weakSelf; if (!self) return;
        
        if (dataTask != self.dataTask) { return; }
        [self progessBlock:downloadProgress];
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        __strong __typeof(weakSelf)self = weakSelf; if (!self) return;
        
        if (dataTask != self.dataTask) { return; }
        
        if (!error) {
            [self handleRequestSuccess:responseObject];
        } else {
            [self faileBlock:error message:ZJNWServerErrorMsg];
        }
    }];
    self.dataTask = dataTask;
    [self.dataTask resume];
    [ZJAppNetWorkAgent.sharedAgent addRequest:self];
}

- (void)PATCH
{
    __weak __typeof(self)weakSelf = self;
    NSURLSessionDataTask *dataTask;
    dataTask = [self.manager PATCH:self.requestUrl parameters:self.parameters headers:self.header success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        __strong __typeof(weakSelf)self = weakSelf; if (!self) return;
        
        if (task != self.dataTask) { return; }
        [self handleRequestSuccess:responseObject];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        __strong __typeof(weakSelf)self = weakSelf; if (!self) return;

        if (task != self.dataTask) { return; }
        [self faileBlock:error message:ZJNWServerErrorMsg];
    }];
    self.dataTask = dataTask;
    [ZJAppNetWorkAgent.sharedAgent addRequest:self];
}

- (void)H5
{
    __weak __typeof(self)weakSelf = self;
    __block NSURLSessionDataTask *dataTask;
    dataTask = [self.manager GET:self.requestUrl parameters:@{} headers:self.header progress:^(NSProgress * _Nonnull uploadProgress) {
        __strong __typeof(weakSelf)self = weakSelf; if (!self) return;
        
        if (dataTask != self.dataTask) { return; }
        [self progessBlock:uploadProgress];
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        __strong __typeof(weakSelf)self = weakSelf; if (!self) return;
        
        if (task != self.dataTask) { return; }
        [self handleRequestSuccess:responseObject];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        __strong __typeof(weakSelf)self = weakSelf; if (!self) return;
        
        if (task != self.dataTask) { return; }
        [self faileBlock:error message:ZJNWServerErrorMsg];
    }];
    self.dataTask = dataTask;
    [ZJAppNetWorkAgent.sharedAgent addRequest:self];
}

#pragma mark -- 基础方法配置
#pragma mark --

/// 检测网络状态
- (BOOL)checkNetworkIsAvailable
{
//    if ([[ZJNetWorkSingleton shareSingleton].networkType isEqualToString:@"-1"]) {
//        NSMutableDictionary *faileDic = NSMutableDictionary.alloc.init;
//        [faileDic setObject:@"未连接到网络" forKey:@"msg"];
//        [faileDic setObject:@"faile" forKey:@"state"];
//        [faileDic setObject:NSDictionary.dictionary forKey:@"data"];
//        self.responseData.responseStatus = ZJNetWorkResponseFaileAndNET;
//        [self clearResponseDataConfig];
//        self.responseData.faileNETResponse = faileDic;
//        return NO;
//    }
    return YES;
}

- (AFHTTPSessionManager *)manager
{
    if (!_manager) {
        _manager = AFHTTPSessionManager.manager;
    }
    return _manager;
}

- (ZJNetWorkResponseData *)responseData
{
    if (!_responseData) {
        _responseData = ZJNetWorkResponseData.alloc.init;
    }
    return _responseData;
}

/// 移除responseData数据层，不移除状态
- (void)clearResponseDataConfig
{
    self.responseData.progress = nil;
    self.responseData.successResponse = nil;
    self.responseData.faileResponse = nil;
    self.responseData.faileNETResponse = nil;
    self.responseData.error = nil;
}

- (id)setRequestSerializerConfig
{
    switch (self.requestSerializerType) {
        case ZJNetWorkRequestSerializerTypeJSON:
            return [self setJSONRequestSerializerConfig];
            break;
        case ZJNetWorkRequestSerializerTypeHTTP:
            return [self setHTTPRequestSerializerConfig];
            break;
        default:
            return [self setJSONRequestSerializerConfig];
            break;
    }
}

- (AFHTTPRequestSerializer *)setHTTPRequestSerializerConfig
{
    AFHTTPRequestSerializer *request = AFHTTPRequestSerializer.serializer;
    request.timeoutInterval = 30;
    //配置请求内容格式
    request = [self setRequestContentTypeConfigWith:request];
    //读取token信息
    request = [self setRequestTokenTypeConfigWith:request];
    return request;
}

- (AFJSONRequestSerializer *)setJSONRequestSerializerConfig
{
    AFJSONRequestSerializer *request = [AFJSONRequestSerializer serializer];
    request.timeoutInterval = 30;
    //配置请求内容格式
    request = [self setRequestContentTypeConfigWith:request];
    //读取token信息
    request = [self setRequestTokenTypeConfigWith:request];
    return request;
}

- (id)setRequestContentTypeConfigWith:(id)request
{
    switch (self.requestSerializerType) {
        case ZJNetWorkRequestSerializerTypeJSON:
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            break;
        case ZJNetWorkRequestSerializerTypeHTTP:
            [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            break;
        default:
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            break;
    }
    [request setValue:@"ios" forHTTPHeaderField:@"platform"];
    [request setValue:@"app-api-java" forHTTPHeaderField:@"type"];
    return request;
}

- (id)setRequestTokenTypeConfigWith:(id)request
{
    return request;
}

- (id)setResponseSerializerConfig
{
    switch (self.responseSerializerType) {
        case ZJNetWorkResponseSerializerTypeJSON:
            return [self JSONResponseSerializer];
            break;
        case ZJNetWorkResponseSerializerTypeHTTP:
            return [self HTTPResponseSerializer];
            break;
        default:
            return [self JSONResponseSerializer];
            break;
    }
}

- (AFJSONResponseSerializer *)JSONResponseSerializer
{
    AFJSONResponseSerializer *response = AFJSONResponseSerializer.serializer;
    response.removesKeysWithNullValues = NO;
    [response setAcceptableContentTypes:[NSSet setWithObjects:@"application/json",
                                             @"text/json",@"text/html",
                                             @"text/javascript",@"text/plain",@"image/jpeg",@"image/png",
                                             nil]];
    return response;
}

- (AFHTTPResponseSerializer *)HTTPResponseSerializer
{
    AFHTTPResponseSerializer *response = AFHTTPResponseSerializer.serializer;
    [response setAcceptableContentTypes:[NSSet setWithObjects:@"application/json",
                                             @"text/json",@"text/html",
                                             @"text/javascript",@"text/plain",@"image/jpeg",@"image/png",
                                             nil]];
    return response;
}

/// 需要对parameters进行处理的代码 可配置固定参数
- (id)setRequestParametersConfig
{
    NSString *string = @"";
    if (self.requestType == ZJNetWorkRequestTypePOST) {
        string = @"POST";
    } else if (self.requestType == ZJNetWorkRequestTypeGET) {
        string = @"GET";
    } else if (self.requestType == ZJNetWorkRequestTypePUT) {
        string = @"PUT";
    } else if (self.requestType == ZJNetWorkRequestTypeBODY) {
        string = @"BODY";
    } else if (self.requestType == ZJNetWorkRequestTypeDELETE) {
        string = @"DELETE";
    } else if (self.requestType == ZJNetWorkRequestTypeH5) {
        string = @"H5";
    } else {
        string = @"未知";
    }
    
    ZJNSLog(@" 请求配置信息打印 \n 请求方式 == %@ \n 请求入参 == %@ \n 请求URL地址 == %@ \n 请求Header信息 == %@",string,[self dicToJson:self.parameters],self.requestUrl,self.header);
    return self.parameters;
}

/// 需要对requestUrl进行处理的代码 可配置固定接口后缀
- (NSString *)setRequestURLConfig
{
    return self.requestUrl;
}

/// 构建body所需的request类型
- (NSMutableURLRequest *)setBodyRequestConfig
{
    NSMutableURLRequest *request = [[AFJSONRequestSerializer serializer] requestWithMethod:@"POST" URLString:self.requestUrl parameters:nil error:nil];
    for (NSString *key in self.header.allKeys) {
        [request setValue:self.header[key] forHTTPHeaderField:key];
    }
    [request setHTTPBody:[[self dicToJson:self.parameters] dataUsingEncoding:NSUTF8StringEncoding]];
    return request;
}

- (NSString *)setRequestIdConfig
{
    return [self setCacheKey];
}

/// 设置缓存的MMKV Key
- (NSString *)setCacheKey
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *key = @"";
    
    /// 读取header信息，例如；token、sign等
    for (NSString *headerKey in self.header.allKeys) {
        /// 因 签名随时间戳的变化而变化，所以签名不纳入key
        if (![headerKey isEqualToString:@"sign"]) {
            key = [NSString stringWithFormat:@"%@%@",key,self.header[headerKey]];
        }
    }
    NSString *mmkvKey = [NSString stringWithFormat:@"%@%@%@%@", self.requestUrl, key, [self.parameters description], [infoDictionary objectForKey:@"CFBundleShortVersionString"]];
    
    /// H5缓存不需要跟随token信息变化而变化
    if (self.requestType == ZJNetWorkRequestTypeH5) {
        mmkvKey = [NSString stringWithFormat:@"%@%@", self.requestUrl, [infoDictionary objectForKey:@"CFBundleShortVersionString"]];
    }
    return mmkvKey;
}

/// 缓存数据
/// @param success 需要缓存的数据
- (BOOL)saveCache:(id _Nullable)success
{
    if (success) {
        [ZJMMKVManager.getMMKV setObject:success forKey:[self setCacheKey]];
        ZJNSLog(@" 接口缓存 \n 接口：%@ \n 缓存成功！！",self.requestUrl);
        return YES;
    }
    ZJNSLog(@" 接口缓存 \n 接口：%@ \n 缓存失败！！",self.requestUrl);
    return NO;
}

/// 获取缓存数据
- (id)archiveCache
{
    id localCache = [ZJMMKVManager.getMMKV getObjectOfClass:NSDictionary.class forKey:[self setCacheKey]];
    return localCache;
}

/// 比较当前缓存与网络请求成功后数据是否一致
/// if YES 不需要再次刷新回调代理，else NO 需要刷新当前页面并更新缓存
- (BOOL)compareLoaclCacheWithRequestDataIsSame:(id)successResponse
{
    id localCache = [self archiveCache];
    if (localCache) {
        if ([localCache isEqual:successResponse]) {
            return YES;
        }else{
            return NO;
        }
    }else{
        return NO;
    }
}

/// 访问成功
/// @param success 访问成功的数据
/// @param dataType 返回参数来源
- (void)successBlock:(id _Nullable)success dataType:(ZJNetWorkResponseDataType)dataType
{
    self.responseData.responseStatus = ZJNetWorkResponseSuccess;
    [self clearResponseDataConfig];
    self.responseData.successResponse = success;
  
    /// 判断原本的本地缓存是否需要加解密（不读取缓存时，不会走这到success中）
    self.responseData.isEncryption = [self.responseData.successResponse[@"isEncryption"] integerValue] == 1 ? YES : NO;
    
    /// 判断是否需要解密
    if (self.responseData.isEncryption) {
        /// 解密
        [self requestSuccessResponseDataForDecrypttion];
    }
    
    if (self.requestType != ZJNetWorkRequestTypeH5) {
        if (self.isDebugLog) {
            ZJNSLog(@"请求成功！\n 请求接口：%@ \n 请求成功：%@",self.requestUrl,[self dicToJson:self.responseData.successResponse]);
        }
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(requestSuccess:)]) {
        self.responseData.responseDataType = dataType;
        [self.delegate requestSuccess:self];
    }
}

/// 访问进度
/// @param progress 进度
- (void)progessBlock:(NSProgress * _Nonnull)progress
{
    // 刷新频率高 异步处理(进度回调'AFNetworking'内部回调默认在异步)
    ZJNSLog(@" 请求地址：%@ \n 访问进度：%@",self.requestUrl,progress.localizedDescription);
    self.responseData.progress = progress;
    self.responseData.responseStatus = ZJNetWorkResponseRequesting;
    if (self.delegate && [self.delegate respondsToSelector:@selector(requestProgress:)]) {
        [self.delegate requestProgress:self];
    }
}

/// 访问失败
/// @param error 失败error
/// @param message 失败原因
- (void)faileBlock:(NSError * _Nonnull)error message:(NSString *)message
{
    ZJNSLog(@" 接口访问失败！\n 接口：%@ \n 入参：%@\n 访问方式：%ld \n 失败原因 == %@",self.requestUrl,self.parameters,self.requestType,error.description);

    NSMutableDictionary *faileDic = NSMutableDictionary.alloc.init;
    [faileDic setObject:message ? message : @"访问失败！" forKey:@"msg"];
    [faileDic setObject:@"fail" forKey:@"state"];
    
    ///错误信息解密
    BOOL isEncryption = NO;
    if (self.dataTask) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)self.dataTask.response;
        NSDictionary *dic = [response allHeaderFields];
        id encryption = dic[@"isEncryption"] ? dic[@"isEncryption"] : @"0";
        isEncryption = [encryption integerValue] == 1 ? YES : NO;
    }
    if (isEncryption) {
        NSData *secretData = [ZJAESDecrypt ZJAes128_decrypt:[ZJAESTools ZJAesDataForHexString:[error.userInfo objectForKey:ZJNWAes128Key]]];
        id data = secretData ? [ZJAESTools ZJAesDataForAnys:secretData] : nil;
        [faileDic setObject:data ? : NSDictionary.new forKey:@"data"];
    } else {
        [faileDic setObject:[error.userInfo objectForKey:@"data"] ? : NSDictionary.new forKey:@"data"];
    }
    
    
    [faileDic setObject:[error.userInfo objectForKey:@"code"] ? [error.userInfo objectForKey:@"code"] : @"-100" forKey:@"code"];
    [faileDic setObject:[error.userInfo objectForKey:@"errCode"] ? [error.userInfo objectForKey:@"errCode"] : @"-100" forKey:@"errCode"];
    if ([[faileDic objectForKey:@"code"] integerValue] == 500) { /// 此处若code/errCode数据类型不正确，可能存在崩溃异常。
        [faileDic setObject:[faileDic objectForKey:@"errCode"] forKey:@"code"];
    }
    [self handleCodeConfig:[[faileDic objectForKey:@"code"] integerValue]];

    self.responseData.responseStatus = ZJNetWorkResponseFaileAndServer;
    [self clearResponseDataConfig];
    self.responseData.error = error;
    self.responseData.faileResponse = faileDic;
    if (self.delegate && [self.delegate respondsToSelector:@selector(requestFaile:)]) {
        [self.delegate requestFaile:self];
    }
    
    [ZJAppNetWorkAgent.sharedAgent removeRequest:self];
}

- (void)handleCodeConfig:(NSInteger)code
{
    /// 在对应的中间层处理这块的逻辑
}

/// 处理访问成功数据
- (void)handleRequestSuccess:(id)responseObject
{
    NSDictionary *dic = [self returnRequestResult:responseObject];
    
    BOOL isEncryption = NO;
    if (self.dataTask) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)self.dataTask.response;
        NSDictionary *dic = [response allHeaderFields];
        id encryption = dic[@"isEncryption"] ? dic[@"isEncryption"] : @"0";
        isEncryption = [encryption integerValue] == 1 ? YES : NO;
    }
    
    /// 新增加密 是否需要解密字典到数据中 isEncryption =  YES ，需要解密，默认不需要
    NSMutableDictionary *saveDic = [NSMutableDictionary.alloc initWithDictionary:dic];
    [saveDic setValue:@(isEncryption) forKey:@"isEncryption"];
    dic = (NSDictionary *)saveDic;
    
    if ([self checkReuqestResultCorrect:dic]) { //是否请求成功 赋值self.requestData 否则self.requestData = nil
        if (self.isCache) {
            if (![self compareLoaclCacheWithRequestDataIsSame:dic]) {
                /// H5专用
                if (self.requestType == ZJNetWorkRequestTypeH5) {
                    if (![self archiveCache]) {
                        [self successBlock:dic dataType:ZJNetWorkResponseDataTypeCache];
                    }
                }else {
                    [self successBlock:dic dataType:ZJNetWorkResponseDataTypeNetWork];
                }
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self saveCache:dic];
                });
            }
        }else {
            [self successBlock:dic dataType:ZJNetWorkResponseDataTypeNetWork];
        }
        [ZJAppNetWorkAgent.sharedAgent removeRequest:self];
    }else{
        [self faileBlock:[NSError errorWithDomain:@"" code:-100 userInfo:dic] message:[dic objectForKey:@"msg"]];
    }
}

/// 检验并处理返回结果
/// @param success 请求成功
- (NSDictionary *)returnRequestResult:(id)success
{
    NSDictionary *dictionary = nil;
    if ([success isKindOfClass:NSDictionary.class]) {
        dictionary = (NSDictionary*)success;
    }else{
        if (success) {
            dictionary = [NSJSONSerialization JSONObjectWithData:success options:kNilOptions error:nil];
        }else{
            dictionary = nil;
        }
    }
    
    NSDictionary *dic = dictionary;
    if (dictionary && [dictionary isKindOfClass:NSDictionary.class]) {
        NSMutableDictionary *curDic = [NSMutableDictionary.alloc initWithDictionary:dictionary];
        NSArray *keys = dictionary.allKeys;
        if ([keys containsObject:ZJNWAes128Key]) {
            [curDic setObject:@"已屏蔽加密信息!" forKey:ZJNWAes128Key];
        }
        dic = (NSDictionary *)curDic;
    }
    
    
    return dictionary;
}

/// 解密
- (void)requestSuccessResponseDataForDecrypttion
{
    NSString *payload = self.responseData.successResponse[ZJNWAes128Key];
    if (payload != nil) {
        NSData *messageData = [ZJAESDecrypt ZJAes128_decrypt:[ZJAESTools ZJAesDataForHexString:payload]];
        id data = [ZJAESTools ZJAesDataForAnys:messageData];
        NSMutableDictionary *dic = [NSMutableDictionary.alloc initWithDictionary:self.responseData.successResponse];
        [dic setValue:data forKey:@"data"];
        [dic setValue:@"数据已解密!>>>请查看data!" forKey:ZJNWAes128Key];
        self.responseData.successResponse = (NSDictionary *)dic;
    }
}

/// 字典转json字符串
- (NSString *)dicToJson:(id)dic
{
    if (dic == nil) {
        return @"";
    }
    NSError *error;
#pragma mark - dic为空它不闪退吗？
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString;
    if (!jsonData) {
        ZJNSLog(@"%@",error);
    }else{
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
    NSRange range = {0,jsonString.length};
    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
    NSRange range2 = {0,mutStr.length};
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    return mutStr;
}

/// 检测数据访问成功后对应的数据状态
- (BOOL)checkReuqestResultCorrect:(NSDictionary *)dic
{
    BOOL isOk = NO;
    BOOL isHaveCode = NO;
    BOOL isHaveState = NO;
    for (NSString *key in dic.allKeys) {
        if ([key isEqualToString:@"code"]) {
            isHaveCode = YES;
        } else if ([key isEqualToString:@"state"]) {
           isHaveState = YES;
        }
    }
    
    if (isHaveState) {
        if ([[dic objectForKey:@"state"] isEqualToString:@"ok"]) {
            isOk = YES;
        }
    }

    else if (isHaveCode) {
        id code = [dic objectForKey:@"code"];
        if (![code isKindOfClass:NSString.class]) {
            if ([code intValue] == 200 || [code intValue] == 0) {
                isOk = YES;
            }
        }
        
        if (self.requestType == ZJNetWorkRequestTypeH5) {
            if ([code intValue] == 200) {
                isOk = YES;
            }
        }
    }
    
    return isOk;
}

- (void)dealloc
{
    ZJNSLog(@" 网络请求被释放了 \n 请求地址：%@,",self.dataTask.currentRequest.URL.absoluteString);
}

+ (void)cancleAppAllRequest
{
    if (ZJNetWorkSingleton.shareSingleton.networkManager) {
        ZJNSLog(@"networkManager == %@",ZJNetWorkSingleton.shareSingleton.networkManager.dataTasks);
        for (NSURLSessionDataTask *dataTask in ZJNetWorkSingleton.shareSingleton.networkManager.dataTasks) {
            if (dataTask) {
                [dataTask cancel];
                ZJNSLog(@" 取消网络请求 \n 请求地址：%@,",dataTask.currentRequest.URL.absoluteString);
            }
        }
        ZJNetWorkSingleton.shareSingleton.networkManager = AFHTTPSessionManager.new;
    }
}

@end


