//
//  ZYNetWorkMoreRequest.m
//  ZYNetWork
//
//  Created by 张宇 on 2021/10/12.
//

#import "ZYNetWorkMoreRequest.h"

@interface ZYNetWorkMoreRequest ()<ZYAppNetWorkDelegate>

@property (nonatomic, strong) ZYNetWorkMoreRequestSuccessBlock successBlock;
@property (nonatomic, strong) ZYNetWorkMoreRequestFailureBlock failureBlock;

@property (nonatomic, strong) NSMutableArray <ZYNetWorkRequest *> *requestArray;
@property (nonatomic, assign) NSInteger finishedCount;

@end

@implementation ZYNetWorkMoreRequest

- (void)startMoreRequest:(NSArray<ZYNetWorkRequest *> *)requestArray success:(ZYNetWorkMoreRequestSuccessBlock)success failure:(ZYNetWorkMoreRequestFailureBlock)failure
{
    self.successBlock = success;
    self.failureBlock = failure;
    
    self.requestArray = [NSMutableArray.alloc initWithArray:requestArray];
    self.finishedCount =  0;
    
    [self start];
}

- (void)start
{
    for (ZYNetWorkRequest *singleRequest in self.requestArray) {
        [singleRequest requestNWWithSuccess:^(__kindof ZYAppNetWork *request, id data) {
            [self singleRequestSuccess:request];
        } failure:^(__kindof ZYAppNetWork *request, NSError *error, id data) {
            [self singleRequestFaile:request];
        } completion:nil];
    }
}

#pragma mark -- 单个网络请求回调处理
- (void)singleRequestSuccess:(ZYAppNetWork *)request
{
    self.finishedCount ++;
    
    if (self.finishedCount == self.requestArray.count) {
        if (self.successBlock) {
            self.successBlock(self.requestArray);
        }
        
        [self clearCompletionBlock];
    }
}

- (void)singleRequestFaile:(ZYAppNetWork *)request
{
    if (request.noNecessarySuccess) {
        self.finishedCount ++;
    } else {
        if (self.failureBlock) {
            self.failureBlock(self.requestArray, [self handldFailureMsg:request.responseData.faileResponse]);
        }
        
        [self clearCompletionBlock];
    }
}

#pragma mark - 处理失败消息提示
- (NSString *)handldFailureMsg:(id)responseObject
{
    if ([responseObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)responseObject;
        if([[dict allKeys] containsObject:@"msg"]){
            return dict[@"msg"] ? dict[@"msg"] : @"";
        }
        if([[dict allKeys] containsObject:@"message"]){
            return dict[@"message"] ? dict[@"message"] : @"";
        }
    }
    return @"";
}

#pragma mark -- 清理处理
- (void)clearCompletionBlock
{
    self.successBlock = nil;
    self.failureBlock = nil;
}
    
- (void)cancleMoreRequest
{
    for (ZYAppNetWork *request in self.requestArray) {
        [request cancleRequest];
    }
    
    [self clearCompletionBlock];
}

- (void)dealloc
{
    NSLog(@"多网络请求被释放了");
    [self cancleMoreRequest];
}

@end
