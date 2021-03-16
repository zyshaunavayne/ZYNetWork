//
//  ZYAppNetWork.m
//  ZYNetWork
//
//  Created by 张宇 on 2021/3/16.
//

#import "ZYAppNetWork.h"

@interface ZYAppNetWork ()

@property (nonatomic, copy, readwrite) NSString * _Nullable requestId;
@property (nonatomic, strong, nullable, readwrite) ZYNetWorkResponseData * responseData;

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
    
    //检查网络是否可以用 不可用不发起网络请求 并抛出异常提示
    if (![self checkNetworkIsAvailable]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(requestNETFaile:)]) {
                [self.delegate requestNETFaile:self];
            }
        });
        return;
    }
    
    if (!_manager) {
        //配置安全协议
        self.manager.securityPolicy.validatesDomainName = self.validatesDomainName;

        //配置请求头类型+内容类型+token类型
        self.manager.requestSerializer = [self setRequestSerializerConfig];

        //配置接收类型 默认为json接收
        self.manager.responseSerializer = [self setResponseSerializerConfig];
        
        //入参URL地址优化处理
        self.requestUrl = [self setRequestURLConfig];
    }
    
    //入参优化处理
    self.parameters = [self setRequestParametersConfig];
    
    //访问唯一标识 暂用MMKV缓存Key
    self.requestId = [self setRequestIdConfig];
    
    [self gotoRequest];
    
    ZYNetWorkSingleton.shareSingleton.networkManager = self.manager;
}

+ (void)startMoreRequest:(NSArray<ZYAppNetWork *> *)moreRequest
{
    dispatch_group_t group = dispatch_group_create();
    
    for (ZYAppNetWork *network in moreRequest) {
        dispatch_group_async(group,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_group_enter(group);
            [network startRequest];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                dispatch_group_leave(group);
            });
        });
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        for (ZYAppNetWork *network in moreRequest) {
            if (network.delegate && [network.delegate respondsToSelector:@selector(moreRequestEnd:)]) {
                [network.delegate moreRequestEnd:moreRequest];
                break;
            }
        }
    });
}

- (void)cancleRequest
{
    if (!_dataTask) {
        [self.dataTask cancel];
    }
}

- (void)cancleAllRequest
{
    for (NSURLSessionDataTask *dataTask in self.manager.dataTasks) {
        [dataTask cancel];
    }
}

/// 通过不同requestType调用不同的方法进行访问
- (void)gotoRequest
{
    //判断是否需要回调缓存
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self archiveCacheAndGotoSuccessDelegate];
    });
    
    //发起网络请求
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
        default:
            NSLog(@"未配置对应访问方式");
            break;
    }
    
//    ZYSingleton.shareSingleton.networkManager = self.manager;
}

#pragma mark -- POST/GET/DELETE/PUT/BODY
#pragma mark --

- (void)POST
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.dataTask = [self.manager POST:self.requestUrl parameters:self.parameters headers:self.header progress:^(NSProgress * _Nonnull uploadProgress) {
            [self progessBlock:uploadProgress];
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            [self handleRequestSuccess:responseObject];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [self faileBlock:error message:@"服务器异常"];
        }];
    });
}

- (void)GET
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.dataTask = [self.manager GET:self.requestUrl parameters:self.parameters headers:self.header progress:^(NSProgress * _Nonnull downloadProgress) {
            [self progessBlock:downloadProgress];
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            [self handleRequestSuccess:responseObject];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [self faileBlock:error message:@"服务器异常"];
        }];
    });
}

- (void)DELETE
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.dataTask = [self.manager DELETE:self.requestUrl parameters:self.parameters headers:self.header success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            [self handleRequestSuccess:responseObject];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [self faileBlock:error message:@"服务器异常"];
        }];
    });
}

- (void)PUT
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.dataTask = [self.manager PUT:self.requestUrl parameters:self.parameters headers:self.header success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            [self handleRequestSuccess:responseObject];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [self faileBlock:error message:@"服务器异常"];
        }];
    });
}

- (void)BODY
{
    NSMutableURLRequest *request = [self setBodyRequestConfig];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.dataTask = [self.manager dataTaskWithRequest:request uploadProgress:^(NSProgress * _Nonnull uploadProgress) {
            [self progessBlock:uploadProgress];
        } downloadProgress:^(NSProgress * _Nonnull downloadProgress) {
            [self progessBlock:downloadProgress];
        } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            if (!error) {
                [self handleRequestSuccess:responseObject];
            } else {
                [self faileBlock:error message:@"服务器异常"];
            }
        }];
        [self.dataTask resume];
    });
}

#pragma mark -- 基础方法配置
#pragma mark --

/// 检测网络状态
- (BOOL)checkNetworkIsAvailable
{
    if ([[ZYNetWorkSingleton shareSingleton].networkType isEqualToString:@"-1"]) {
        NSMutableDictionary *faileDic = NSMutableDictionary.alloc.init;
        [faileDic setObject:@"未连接到网络" forKey:@"msg"];
        [faileDic setObject:@"faile" forKey:@"state"];
        [faileDic setObject:NSDictionary.dictionary forKey:@"data"];
        self.responseData.responseStatus = ZYNetWorkResponseFaileAndNET;
        [self clearResponseDataConfig];
        self.responseData.faileNETResponse = faileDic;
        return NO;
    }
    return YES;
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
            return [self setAutoRequestSerializerConfig];
            break;
    }
}

- (AFHTTPRequestSerializer *)setHTTPRequestSerializerConfig
{
    AFHTTPRequestSerializer *request = AFHTTPRequestSerializer.serializer;
    request.timeoutInterval = 30;
    [request setValue:@"ios" forHTTPHeaderField:@"platform"];
    [request setValue:@"app-api-java" forHTTPHeaderField:@"type"];
    //配置请求内容格式
    request = [self setRequestContentTypeConfigWith:request];
    //配置Token
    request = [self setRequestTokenTypeConfigWith:request];
    return request;
}

- (AFJSONRequestSerializer *)setJSONRequestSerializerConfig
{
    AFJSONRequestSerializer *request = [AFJSONRequestSerializer serializer];
    request.timeoutInterval = 30;
    [request setValue:@"ios" forHTTPHeaderField:@"platform"];
    [request setValue:@"app-api-java" forHTTPHeaderField:@"type"];
    //配置请求内容格式
    request = [self setRequestContentTypeConfigWith:request];
    //配置Token
    request = [self setRequestTokenTypeConfigWith:request];
    return request;
}

- (id)setAutoRequestSerializerConfig
{
    if (self.contentType == ZYNetWorkContentTypeJSON) {
        return [self setJSONRequestSerializerConfig];
    }else{
        return [self setHTTPRequestSerializerConfig];
    }
}

- (id)setRequestContentTypeConfigWith:(id)request
{
    if (self.contentType == ZYNetWorkContentTypeJSON) {
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    } else if (self.contentType == ZYNetWorkContentTypeFORM){
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    } else {}
    return request;
}

- (id)setRequestTokenTypeConfigWith:(id)request
{
    [request setValue:[self setTokenCofig] forHTTPHeaderField:@"Authorization"];
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
    response.removesKeysWithNullValues = YES;
    [response setAcceptableContentTypes:[NSSet setWithObjects:@"application/json",
                                             @"text/json",@"text/html",
                                             @"text/javascript",@"text/plain",
                                             nil]];
    return response;
}

- (AFHTTPResponseSerializer *)HTTPResponseSerializer
{
    AFHTTPResponseSerializer *response = AFHTTPResponseSerializer.serializer;
    [response setAcceptableContentTypes:[NSSet setWithObjects:@"application/json",
                                             @"text/json",@"text/html",
                                             @"text/javascript",@"text/plain",
                                             nil]];
    return response;
}

//需要对parameters进行处理的代码 可配置固定参数
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
    } else {
        string = @"未知";
    }
    
    NSLog(@" 请求配置 \n 请求方式 == %@ \n 请求入参 == %@ \n 请求URL地址 == %@",string,self.parameters,self.requestUrl);
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
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:[self setTokenCofig] forHTTPHeaderField:@"Authorization"];
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
    NSString *mmkvKey = [NSString stringWithFormat:@"%@%@%@", self.requestUrl, [self setTokenCofig], [self.parameters description]];
    return mmkvKey;
}

/// 获取token值
- (NSString *)setTokenCofig
{
    NSString *token = @"";
    switch (self.tokenType) {
            
        default: // 默认token
            token = @"";
            break;
    }
    
    return token;
}

/// 缓存数据
/// @param success 需要缓存的数据
- (BOOL)saveCache:(id _Nullable)success
{
    if (success) {
        [MMKVManager.getMMKV setObject:success forKey:[self setCacheKey]];
        NSLog(@" 接口缓存 \n 接口：%@ \n 缓存成功！！",self.requestUrl);
        return YES;
    }
    NSLog(@" 接口缓存 \n 接口：%@ \n 缓存失败！！",self.requestUrl);
    return NO;
}

/// 获取缓存数据
- (id)archiveCache
{
    id localCache = [MMKVManager.getMMKV getObjectOfClass:NSDictionary.class forKey:[self setCacheKey]];
    return localCache;
}

/// 比较当前缓存与网络请求成功后数据是否一致
/// if YES 不需要再次刷新回调代理，else NO 需要刷新当前页面并更新缓存
- (BOOL)compareLoaclCacheWithRequestDataIsSame
{
    id localCache = [self archiveCache];
    if (localCache) {
        if ([localCache isEqual:self.responseData.successResponse]) {
            return YES;
        }else{
            return NO;
        }
    }else{
        return NO;
    }
}

/// 获取缓存数据并回调成功代理
- (void)archiveCacheAndGotoSuccessDelegate
{
    if (self.isCache) { //需要缓存时，可直接读取本地缓存 进行回调
        id localCache = [self archiveCache];
        if (localCache) {
            [self successBlock:localCache];
        }
    }
}

/// 访问成功
/// @param success 访问成功的数据
- (void)successBlock:(id _Nullable)success
{
    self.responseData.responseStatus = ZYNetWorkResponseSuccess;
    [self clearResponseDataConfig];
    self.responseData.successResponse = success;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(requestSuccess:)]) {
            [self.delegate requestSuccess:self];
        }
    });
}

/// 访问进度
/// @param progress 进度
- (void)progessBlock:(NSProgress * _Nonnull)progress
{
    //刷新频率高 异步处理
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@" 请求地址：%@ \n 访问进度：%@",self.requestUrl,progress.localizedDescription);
        self.responseData.progress = progress;
        self.responseData.responseStatus = ZYNetWorkResponseRequesting;
        self.responseData.successResponse = nil;
        self.responseData.faileResponse = nil;
        self.responseData.faileNETResponse = nil;
        if (self.delegate && [self.delegate respondsToSelector:@selector(requestProgress:)]) {
            [self.delegate requestProgress:self];
        }
    });
}

/// 访问失败
/// @param error 失败error
/// @param message 失败原因
- (void)faileBlock:(NSError * _Nonnull)error message:(NSString *)message
{
    NSLog(@" 接口访问失败！\n 接口：%@ \n 入参：%@\n 访问方式：%ld \n 失败原因 == %@",self.requestUrl,self.parameters,self.requestType,error.description);

    NSMutableDictionary *faileDic = NSMutableDictionary.alloc.init;
    [faileDic setObject:message ? message : @"访问失败！" forKey:@"msg"];
    [faileDic setObject:@"fail" forKey:@"state"];
    [faileDic setObject:NSDictionary.new forKey:@"data"];
    [faileDic setObject:[error.userInfo objectForKey:@"code"] forKey:@"code"];

    dispatch_async(dispatch_get_main_queue(), ^{
        self.responseData.responseStatus = ZYNetWorkResponseFaileAndServer;
        [self clearResponseDataConfig];
        self.responseData.error = error;
        self.responseData.faileResponse = faileDic;
        if (self.delegate && [self.delegate respondsToSelector:@selector(requestFaile:)]) {
            [self.delegate requestFaile:self];
        }
    });
}

/// 处理访问成功数据
- (void)handleRequestSuccess:(id)responseObject
{
    NSDictionary *dic = [self returnRequestResult:responseObject];
    if ([self checkReuqestResultCorrect:dic]) { //是否请求成功 赋值self.requestData 否则self.requestData = nil
        if (self.isCache) {
            if (![self compareLoaclCacheWithRequestDataIsSame]) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self saveCache:dic];
                });
                [self successBlock:dic];
            }
        }else{
            [self successBlock:dic];
        }
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
    
    NSLog(@"请求成功！\n 请求接口：%@ \n 请求成功：%@",self.requestUrl,[self dicToJson:dictionary]);
    return dictionary;
}

/// 字典转json字符串
- (NSString *)dicToJson:(id)dic
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString;
    if (!jsonData) {
        NSLog(@"%@",error);
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
    NSLog(@" 网络请求被释放了 \n 请求地址：%@,",self.dataTask.currentRequest.URL.absoluteString);
}

+ (void)cancleAppAllRequest
{
    if (ZYNetWorkSingleton.shareSingleton.networkManager) {
        NSLog(@"networkManager == %@",ZYNetWorkSingleton.shareSingleton.networkManager.dataTasks);
        for (NSURLSessionDataTask *dataTask in ZYNetWorkSingleton.shareSingleton.networkManager.dataTasks) {
            if (dataTask) {
                [dataTask cancel];
                NSLog(@" 取消网络请求 \n 请求地址：%@,",dataTask.currentRequest.URL.absoluteString);
            }
        }
        ZYNetWorkSingleton.shareSingleton.networkManager = AFHTTPSessionManager.new;
    }
}

@end


