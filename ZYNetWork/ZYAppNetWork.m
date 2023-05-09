//
//  ZYAppNetWork.m
//  ZYNetWork
//
//  Created by 张宇 on 2023/2/9.
//

#import "ZYAppNetWork.h"
#import <AFNetworking/AFNetworking.h>
#import "ZYMMKVManager.h"
#import "ZYAppNetWorkAgent.h"

/// 重新打印
#ifdef DEBUG
#define ZYNSLog(s, ...) printf("class: <%p %s:(%d) > method: %s \n%s\n", self, [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, __PRETTY_FUNCTION__, [[NSString stringWithFormat:(s), ##__VA_ARGS__] UTF8String] )
#define NSLog(...) NSLog(__VA_ARGS__);
#else
#define ZYNSLog(...)
#define NSLog(...)
#endif

static NSString *ZYNWServerErrorMsg = @"服务器异常";

@interface ZYAppNetWork ()

@property (nonatomic, copy, readwrite) NSString * requestId;
@property (nonatomic, strong, readwrite) ZYNetWorkResponseData * responseData;

/// 网络管理器
@property (nonatomic, strong) AFHTTPSessionManager *manager;

/// 当前运行的task
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;

@end

@implementation ZYAppNetWork

/// 开启网络请求访问
- (void)startRequest
{
    self.responseData = ZYNetWorkResponseData.alloc.init;
    
    /// 检查网络是否可以用 不可用不发起网络请求 并抛出异常提示
    if (![self checkNetworkIsAvailable]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(requestNETFaile:)]) {
                [self.delegate requestNETFaile:self];
            }
        });
        return;
    }
    
    /// 图片/附件模式 默认需要缓存，且会立即返回
    if (self.requestType == ZYNetWorkRequestTypeFILES) {
        self.isCache = YES;
        self.isDirectlyBackCahche = YES;
    }
    
    /// 当设置此属性时，默认会将isCache、isDirectlyBackCahche设置为NO。eg：子类中重写后，可能会有影响；在子类中手动改成NO即可。
    if (self.isNoBackToCache) {
        self.isCache = NO;
        self.isDirectlyBackCahche = NO;
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
    
    ZYNetWorkSingleton.shareSingleton.networkManager = self.manager;
}

- (void)cancleRequest
{
    if (_dataTask) {
        [ZYAppNetWorkAgent.sharedAgent removeRequest:self];
        [self.dataTask cancel];
    }
}

- (void)cancleAllRequest
{
    [ZYAppNetWorkAgent.sharedAgent removeRequest:self];
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
    } else {
        /// 如果为图片、附件，则不需要再继续发起访问，并发起success代理。防止重复性获取图片。
        if (self.requestType == ZYNetWorkRequestTypeFILES) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self successBlock:localCache dataType:ZYNetWorkResponseDataTypeCache];
            });
            return;
        }
    }
    
    /// 直接返回缓存并获取新数据更新缓存
    dispatch_async(dispatch_get_main_queue(), ^{
        [self successBlock:localCache dataType:ZYNetWorkResponseDataTypeCache];
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
        case ZYNetWorkRequestTypePOST:
            [self POST];
            break;
        case ZYNetWorkRequestTypeGET:
            [self GET];
            break;
        case ZYNetWorkRequestTypeDELETE:
            [self DELETE];
            break;
        case ZYNetWorkRequestTypePUT:
            [self PUT];
            break;
        case ZYNetWorkRequestTypeBODY:
            [self BODY];
            break;
        case ZYNetWorkRequestTypePATCH:
            [self PATCH];
            break;
        case ZYNetWorkRequestTypeFILES:
            [self FILES];
            break;
        case ZYNetWorkRequestTypeFORMDATA:
            [self FORMDATA];
            break;
        default:
            ZYNSLog(@"未配置对应访问方式");
            break;
    }
    
    ZYNetWorkSingleton.shareSingleton.networkManager = self.manager;
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
        [self faileBlock:error message:ZYNWServerErrorMsg];
    }];
    self.dataTask = dataTask;
    /// 因为使用了__weak self 会导致启用了缓存的网络请求第一次回调过后就被释放了（如果外部不持有），更新缓存的网络请求无法继续执行下一步操作了，此时 self = nil
    [ZYAppNetWorkAgent.sharedAgent addRequest:self];
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
        [self faileBlock:error message:ZYNWServerErrorMsg];
    }];
    self.dataTask = dataTask;
    [ZYAppNetWorkAgent.sharedAgent addRequest:self];
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
        [self faileBlock:error message:ZYNWServerErrorMsg];
    }];
    self.dataTask = dataTask;
    [ZYAppNetWorkAgent.sharedAgent addRequest:self];
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
        [self faileBlock:error message:ZYNWServerErrorMsg];
    }];
    self.dataTask = dataTask;
    [ZYAppNetWorkAgent.sharedAgent addRequest:self];
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
            [self faileBlock:error message:ZYNWServerErrorMsg];
        }
    }];
    self.dataTask = dataTask;
    [self.dataTask resume];
    [ZYAppNetWorkAgent.sharedAgent addRequest:self];
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
        [self faileBlock:error message:ZYNWServerErrorMsg];
    }];
    self.dataTask = dataTask;
    [ZYAppNetWorkAgent.sharedAgent addRequest:self];
}

- (void)FILES
{
    __weak __typeof(self)weakSelf = self;
    NSURLSessionDownloadTask *dataTask;
    dataTask = [self.manager downloadTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.requestUrl]] progress:^(NSProgress * _Nonnull downloadProgress) {
        [weakSelf progessBlock:downloadProgress];
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        NSURL *fileUrl = [documentsDirectoryURL URLByAppendingPathComponent:[weakSelf.requestUrl lastPathComponent]];
        return fileUrl;
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        if (!error) {
            /// 构造所需的success返回类型
            NSMutableDictionary *success = NSMutableDictionary.alloc.init;
            [success setValue:@(200) forKey:@"code"];
            [success setValue:@"请求成功" forKey:@"message"];
            
            /// 构造data中数据
            NSMutableDictionary *dic = NSMutableDictionary.alloc.init;
            NSData *data = [NSData dataWithContentsOfURL:filePath];
            NSString *base64String = [weakSelf dataToBase64str:data];
            [dic setValue:base64String forKey:@"file"];
            
            [success setValue:dic forKey:@"data"];
            
            [weakSelf handleRequestSuccess:success];
        } else {
            [weakSelf faileBlock:error message:@"下载失败!"];
        }
    }];
    [dataTask resume];
    self.dataTask = (NSURLSessionDataTask *)dataTask;
    [ZYAppNetWorkAgent.sharedAgent addRequest:self];
}

- (void)FORMDATA
{
    __weak __typeof(self)weakSelf = self;
    NSURLSessionDataTask *dataTask;
    dataTask = [self.manager POST:self.requestUrl parameters:self.parameters headers:self.header constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        if (weakSelf.formDataType == ZYNetWorkFormDataTypePhoto) {
            for (UIImage *image in weakSelf.formDataArray) {
                [formData appendPartWithFileData:UIImageJPEGRepresentation(image,
                                                                           1.0)
                                            name:weakSelf.formDataName
                                        fileName:[NSString stringWithFormat:@"%@.png",weakSelf.formDataFileName] ? : @"test.png"
                                        mimeType:@"image/png"];
            }
        } else {
            NSLog(@"formDataType == 未知类型");
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
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
        
        [self faileBlock:error message:ZYNWServerErrorMsg];
    }];
    [dataTask resume];
    self.dataTask = dataTask;
    [ZYAppNetWorkAgent.sharedAgent addRequest:self];
}

#pragma mark -- 基础方法配置
#pragma mark --

- (NSString *)dataToBase64str:(NSData *)data
{
    /// 转成base64Str
    NSString *base64String = [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    /// 外部使用时，解base64方法
    /*/
     
     NSData *data = [[NSData alloc] initWithBase64EncodedString:base64String options:NSDataBase64DecodingIgnoreUnknownCharacters];
     
     /// webView加载PDF文件示例
     [webView loadData:data MIMEType:@"application/pdf" characterEncodingName:@"UTF-8" baseURL:[NSURL fileURLWithPath:NSTemporaryDirectory()]];
     */
    return base64String;
}

/// 检测网络状态
- (BOOL)checkNetworkIsAvailable
{
//    if ([[ZYNetWorkSingleton shareSingleton].networkType isEqualToString:@"-1"]) {
//        NSMutableDictionary *faileDic = NSMutableDictionary.alloc.init;
//        [faileDic setObject:@"未连接到网络" forKey:@"msg"];
//        [faileDic setObject:@"faile" forKey:@"state"];
//        [faileDic setObject:NSDictionary.dictionary forKey:@"data"];
//        self.responseData.responseStatus = ZYNetWorkResponseFaileAndNET;
//        [self clearResponseDataConfig];
//        self.responseData.faileNETResponse = faileDic;
//        return NO;
//    }
    return  YES;
}

- (AFHTTPSessionManager *)manager
{
    if (!_manager) {
        _manager = AFHTTPSessionManager.manager;
    }
    return _manager;
}

- (ZYNetWorkResponseData *)responseData
{
    if (!_responseData) {
        _responseData = ZYNetWorkResponseData.alloc.init;
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
        case ZYNetWorkRequestSerializerTypeJSON:
            return [self setJSONRequestSerializerConfig];
            break;
        case ZYNetWorkRequestSerializerTypeHTTP:
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
        case ZYNetWorkRequestSerializerTypeJSON:
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            break;
        case ZYNetWorkRequestSerializerTypeHTTP:
            [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            break;
        default:
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            break;
    }
    return request;
}

- (id)setRequestTokenTypeConfigWith:(id)request
{
    return request;
}

- (id)setResponseSerializerConfig
{
    switch (self.responseSerializerType) {
        case ZYNetWorkResponseSerializerTypeJSON:
            return [self JSONResponseSerializer];
            break;
        case ZYNetWorkResponseSerializerTypeHTTP:
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
    response.removesKeysWithNullValues = self.removesNullValues;
    [response setAcceptableContentTypes:[NSSet setWithObjects:@"application/json",
                                             @"text/json",@"text/html",
                                             @"text/javascript",@"text/plain",@"image/jpeg",@"image/png",@"application/x-json",
                                             nil]];
    return response;
}

- (AFHTTPResponseSerializer *)HTTPResponseSerializer
{
    AFHTTPResponseSerializer *response = AFHTTPResponseSerializer.serializer;
    [response setAcceptableContentTypes:[NSSet setWithObjects:@"application/json",
                                             @"text/json",@"text/html",
                                             @"text/javascript",@"text/plain",@"image/jpeg",@"image/png",@"application/x-json",
                                             nil]];
    return response;
}

/// 需要对parameters进行处理的代码 可配置固定参数
- (id)setRequestParametersConfig
{
    NSString *string = @"";
    if (self.requestType == ZYNetWorkRequestTypePOST) {
        string = @"POST";
    } else if (self.requestType == ZYNetWorkRequestTypeGET) {
        string = @"GET";
    } else if (self.requestType == ZYNetWorkRequestTypePUT) {
        string = @"PUT";
    } else if (self.requestType == ZYNetWorkRequestTypeBODY) {
        string = @"BODY";
    } else if (self.requestType == ZYNetWorkRequestTypeDELETE) {
        string = @"DELETE";
    }  else if (self.requestType == ZYNetWorkRequestTypeFILES) {
        string = @"FILES";
    }  else if (self.requestType == ZYNetWorkRequestTypeFORMDATA) {
        string = @"FORMDATA";
    } else {
        string = @"未知";
    }
    
    ZYNSLog(@" 请求配置信息打印 \n 请求方式 == %@ \n 请求入参 == %@ \n 请求URL地址 == %@ \n 请求Header信息 == %@",string,[self dicToJson:self.parameters],self.requestUrl,self.header);
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
    NSString *key = @"";
    /// 读取header信息，例如；token、sign等
    for (NSString *headerKey in self.header.allKeys) {
        /// 因 签名随时间戳的变化而变化，所以签名不纳入key
        key = [NSString stringWithFormat:@"%@%@",key,self.header[headerKey]];
    }
    
    NSString *mmkvKey = [NSString stringWithFormat:@"%@%@%@", self.requestUrl, key, [self.parameters description]];
    return mmkvKey;
}

/// 缓存数据
/// @param success 需要缓存的数据
- (BOOL)saveCache:(id _Nullable)success
{
    if (success) {
        [ZYMMKVManager.getMMKV setObject:success forKey:[self setCacheKey]];
        ZYNSLog(@" 接口缓存 \n 接口：%@ \n 缓存成功！！",self.requestUrl);
        return YES;
    }
    ZYNSLog(@" 接口缓存 \n 接口：%@ \n 缓存失败！！",self.requestUrl);
    return NO;
}

/// 获取缓存数据
- (id)archiveCache
{
    id localCache = [ZYMMKVManager.getMMKV getObjectOfClass:NSDictionary.class forKey:[self setCacheKey]];
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
- (void)successBlock:(id _Nullable)success dataType:(ZYNetWorkResponseDataType)dataType
{
    self.responseData.responseStatus = ZYNetWorkResponseSuccess;
    [self clearResponseDataConfig];
    self.responseData.successResponse = success;
  
    /// 判断原本的本地缓存是否需要加解密（不读取缓存时，不会走这到success中）
    self.responseData.isEncryption = [self.responseData.successResponse[@"isEncryption"] integerValue] == 1 ? YES : NO;
    
    /// 判断是否需要解密
    if (self.responseData.isEncryption) {
        /// 解密
        [self requestSuccessResponseDataForDecrypttion];
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
    ZYNSLog(@" 请求地址：%@ \n 访问进度：%@",self.requestUrl,progress.localizedDescription);
    self.responseData.progress = progress;
    self.responseData.responseStatus = ZYNetWorkResponseRequesting;
    if (self.delegate && [self.delegate respondsToSelector:@selector(requestProgress:)]) {
        [self.delegate requestProgress:self];
    }
}

/// 访问失败
/// @param error 失败error
/// @param message 失败原因
- (void)faileBlock:(NSError * _Nonnull)error message:(NSString *)message
{
    ZYNSLog(@" 接口访问失败！\n 接口：%@ \n 入参：%@\n 访问方式：%ld \n 失败原因 == %@",self.requestUrl,self.parameters,self.requestType,error.description);

    NSMutableDictionary *faileDic = NSMutableDictionary.alloc.init;
    [faileDic setObject:message ? message : @"访问失败！" forKey:@"msg"];
    [faileDic setObject:[error.userInfo objectForKey:@"data"] ? : NSDictionary.new forKey:@"data"];
    [faileDic setObject:[error.userInfo objectForKey:@"code"] ? [error.userInfo objectForKey:@"code"] : @"-100" forKey:@"code"];
    [self handleCodeConfig:[[faileDic objectForKey:@"code"] integerValue]];
    self.responseData.responseStatus = ZYNetWorkResponseFaileAndServer;
    [self clearResponseDataConfig];
    self.responseData.error = error;
    self.responseData.faileResponse = faileDic;
    if (self.delegate && [self.delegate respondsToSelector:@selector(requestFaile:)]) {
        [self.delegate requestFaile:self];
    }
    
    [ZYAppNetWorkAgent.sharedAgent removeRequest:self];
}

- (void)handleCodeConfig:(NSInteger)code
{
    /// 在对应的中间层处理这块的逻辑
}

/// 处理访问成功数据
- (void)handleRequestSuccess:(id)responseObject
{
    NSDictionary *dic = [self returnRequestResult:responseObject];
    if ([self checkReuqestResultCorrect:dic]) { //是否请求成功 赋值self.requestData 否则self.requestData = nil
        if (self.isCache) {
            if (![self compareLoaclCacheWithRequestDataIsSame:dic]) {
                [self successBlock:dic dataType:ZYNetWorkResponseDataTypeNetWork];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self saveCache:dic];
                });
            }
        } else {
            [self successBlock:dic dataType:ZYNetWorkResponseDataTypeNetWork];
            if (self.isNoBackToCache) { /// 不管是否开启有缓存，都会进行缓存操作，且不返回缓存数据
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self saveCache:dic];
                });
            }
        }
        [ZYAppNetWorkAgent.sharedAgent removeRequest:self];
    }else{
        [self faileBlock:[NSError errorWithDomain:@"" code:[[dic objectForKey:@"code"] integerValue] userInfo:dic] message:[dic objectForKey:@"msg"]];
    }
}

/// 检验并处理返回结果
/// @param success 请求成功
- (NSDictionary *)returnRequestResult:(id)success
{
    NSDictionary *dictionary = nil;
    if ([success isKindOfClass:NSDictionary.class]) {
        dictionary = (NSDictionary*)success;
    } else {
        if (success) {
            dictionary = [NSJSONSerialization JSONObjectWithData:success options:kNilOptions error:nil];
        } else {
            dictionary = nil;
        }
    }
    ZYNSLog(@" 请求地址：%@ \n 请求结果：%@",self.requestUrl,[self dicToJson:dictionary]);
    return dictionary;
}

/// 解密
- (void)requestSuccessResponseDataForDecrypttion
{
  
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
        ZYNSLog(@"%@",error);
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
    return YES;
}

- (void)dealloc
{
    ZYNSLog(@" 网络请求被释放了 \n 请求地址：%@,",self.dataTask.currentRequest.URL.absoluteString);
}

+ (void)cancleAppAllRequest
{
    if (ZYNetWorkSingleton.shareSingleton.networkManager) {
        ZYNSLog(@"networkManager == %@",ZYNetWorkSingleton.shareSingleton.networkManager.dataTasks);
        for (NSURLSessionDataTask *dataTask in ZYNetWorkSingleton.shareSingleton.networkManager.dataTasks) {
            if (dataTask) {
                [dataTask cancel];
                ZYNSLog(@" 取消网络请求 \n 请求地址：%@,",dataTask.currentRequest.URL.absoluteString);
            }
        }
        ZYNetWorkSingleton.shareSingleton.networkManager = AFHTTPSessionManager.new;
    }
}

@end


