//
//  ZYNetWorkRequest.m
//  ZYNetWork
//
//  Created by 张宇 on 2021/6/29.
//

#import "ZYNetWorkRequest.h"
#import <MJExtension/MJExtension.h>

static NSString *ZYNWAes128Key = @"payload";

@interface ZYNetWorkRequest () <ZYAppNetWorkDelegate>
@property (nonatomic, strong) ZYNetWorkRequestSuccessBlock successBlock;
@property (nonatomic, strong) ZYNetWorkRequestFailureBlock failureBlock;
@property (nonatomic, strong) ZYNetWorkRequestCompletionBlock completionBlock;
@property (nonatomic, strong) id data;
@property (nonatomic, copy) ZYNetWorkRequestProgressBlock progressBlock;
@property (nonatomic, assign) BOOL isDirectlyBack;
@end

@implementation ZYNetWorkRequest

- (void)requestNWWithSuccess:(ZYNetWorkRequestSuccessBlock)success failure:(ZYNetWorkRequestFailureBlock)failure completion:(ZYNetWorkRequestCompletionBlock)completion
{
    self.delegate = self;
    
    _successBlock = success;
    _failureBlock = failure;
    if (completion) {
        _completionBlock = completion;
    }else{
        _completionBlock = ^(BOOL isCompletion) {};
    }
    
    [self startRequest];
}

- (void)requestNWWithProgress:(ZYNetWorkRequestProgressBlock)progress success:(ZYNetWorkRequestSuccessBlock)success failure:(ZYNetWorkRequestFailureBlock)failure completion:(ZYNetWorkRequestCompletionBlock)completion {
    
    _progressBlock = [progress copy];
    [self requestNWWithSuccess:success failure:failure completion:completion];
}

- (void)requestSuccess:(ZYAppNetWork *)request
{
    id data = nil;
    if ([request.responseData.successResponse isKindOfClass:NSDictionary.class]) {
        
        data = [self requestDataToModel:request.responseData.successResponse[@"data"]];
        
        /// 为H5接口地址获取时，单独处理
        if (request.requestType == ZYNetWorkRequestTypeH5) {
            NSString *key = [NSString stringWithFormat:@"%@",[(NSDictionary *)request.parameters objectForKey:@"param"]];
            NSMutableDictionary *dic = NSMutableDictionary.alloc.init;
            BOOL isOK = NO;
            if ([data isKindOfClass:NSArray.class]) {
                NSArray *array = data;
                for (NSDictionary *h5Dic in array) {
                    if ([key isEqualToString:[h5Dic objectForKey:@"key"]]) {
                        dic = [NSMutableDictionary.alloc initWithDictionary:h5Dic];
                        [dic setObject:(NSString *)[dic objectForKey:@"name"] forKey:@"url"];
                        isOK = YES;
                        break;
                    }
                }
            }
            
            if (!isOK) {
                [dic setValue:@"获取失败，未找到param信息" forKey:@"msg"];
            }
            data = dic;
            NSLog(@"请求成功！\n 请求接口：%@ \n 请求成功：%@",request.requestUrl,data);
            if ([request.responseData.successResponse isKindOfClass:NSDictionary.class]) {
                NSMutableDictionary *dic = [NSMutableDictionary.alloc initWithDictionary:request.responseData.successResponse];
                [dic setValue:data forKey:@"data"];
                [dic removeObjectForKey:ZYNWAes128Key];
                request.responseData.successResponse = dic;
                self.responseData.successResponse = request.responseData.successResponse;
            }
        }
    }
    self.data = data;
    
    [self requestSucceedFilter];
    
    if (_successBlock) { _successBlock(self, data); }
    if (_completionBlock) { _completionBlock(YES); }
    
    if (self.isDirectlyBackCahche && self.isCache) {
        if (self.isDirectlyBack) {
            [self clearBlock];
            self.isDirectlyBack = NO;
        } else {
            self.isDirectlyBack = YES;
        }
    } else{
        [self clearBlock];
    }
}

- (void)requestFaile:(ZYAppNetWork *)request
{
    id data = nil;
    if ([request.responseData.faileResponse isKindOfClass:NSDictionary.class]) {
        data = request.responseData.faileResponse[@"data"];
    }
    self.data = data;
    
    [self requestFailedFilter];
    
    if (_failureBlock) { _failureBlock(self, request.responseData.error, data); }
    if (_completionBlock) { _completionBlock(YES); }
    
    [self clearBlock];
}

- (void)requestNETFaile:(ZYAppNetWork *)request
{
    id data = nil;
    if ([request.responseData.faileNETResponse isKindOfClass:NSDictionary.class]) {
        data = request.responseData.faileNETResponse[@"data"];
    }
    self.data = data;
    
    [self requestFailedFilter];
    
    if (_failureBlock) {
        _failureBlock(self, request.responseData.error, data);
    }
    _completionBlock(YES);
    
    [self clearBlock];
}

- (void)requestProgress:(ZYAppNetWork *)request
{
    if (_progressBlock) {
        self.progressBlock(request.responseData.progress);
    }
}

- (Class)modelClass
{
    return nil;
}

- (id)requestDataToModel:(id)data
{
    if (data) {
        Class modelClass = [self modelClass];
        if (modelClass) {
            id responseJSONModel = nil;
            if ([data isKindOfClass:[NSDictionary class]]) {
                responseJSONModel = [modelClass mj_objectWithKeyValues:data];
                data = responseJSONModel;
            }else if ([data isKindOfClass:[NSArray class]]) {
                responseJSONModel = [modelClass mj_objectArrayWithKeyValuesArray:data];
                data = responseJSONModel;
            }
        }
    }
    return data;
}

- (void)clearBlock
{
    self.successBlock = nil;
    self.failureBlock = nil;
    self.progressBlock = nil;
    self.completionBlock = nil;
}

- (void)requestSucceedFilter
{
    
}

- (void)requestFailedFilter
{
    
}

- (void)dealloc
{
    [self clearBlock];
}

@end
