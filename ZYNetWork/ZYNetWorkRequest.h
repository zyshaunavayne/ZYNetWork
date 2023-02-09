//
//  ZYNetWorkRequest.h
//  ZYNetWork
//
//  Created by 张宇 on 2023/2/9.
//

#import "ZYAppNetWork.h"

/// 请求成功
typedef void(^ZYNetWorkRequestSuccessBlock) (__kindof ZYAppNetWork *request, id data);
/// 请求失败
typedef void(^ZYNetWorkRequestFailureBlock) (__kindof ZYAppNetWork *request, NSError *error, id data);
/// 接口完成
typedef void(^ZYNetWorkRequestCompletionBlock) (BOOL completion);
/// 请求进度
typedef void(^ZYNetWorkRequestProgressBlock) (NSProgress *progress);

@interface ZYNetWorkRequest : ZYAppNetWork

/// 请求成功后的 data
@property (nonatomic, strong, readonly) id data;

/// data层转model，有需要的可以使用。
- (Class)modelClass;

/// 开始网络请求
/// @param success 成功
/// @param failure 失败
/// @param completion 完成
- (void)requestNWWithSuccess:(ZYNetWorkRequestSuccessBlock)success
                     failure:(ZYNetWorkRequestFailureBlock)failure
                  completion:(ZYNetWorkRequestCompletionBlock)completion;


/// 请求成功处理（在successBlock之前会调用）
- (void)requestSucceedFilter;

/// 请求失败处理（在failureBlock之前会调用）
- (void)requestFailedFilter;

/// 开始带进度的网络请求
/// @param progress 进度
/// @param success 成功
/// @param failure 失败
/// @param completion 完成
- (void)requestNWWithProgress:(ZYNetWorkRequestProgressBlock)progress success:(ZYNetWorkRequestSuccessBlock)success
                     failure:(ZYNetWorkRequestFailureBlock)failure
                  completion:(ZYNetWorkRequestCompletionBlock)completion;



@end

