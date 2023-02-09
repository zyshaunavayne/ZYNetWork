//
//  ZYNetWorkMoreRequest.h
//  ZYNetWork
//
//  Created by 张宇 on 2021/10/12.
//

#import <Foundation/Foundation.h>
#import "ZYNetWorkRequest.h"

/// 请求成功
typedef void(^ZYNetWorkMoreRequestSuccessBlock) (NSArray * _Nullable successArray);
/// 请求失败
typedef void(^ZYNetWorkMoreRequestFailureBlock) (NSArray * _Nullable failureArray, NSString * _Nullable msg);

NS_ASSUME_NONNULL_BEGIN

@interface ZYNetWorkMoreRequest : NSObject

/// 发起多个网络请求
/// @param requestArray 多网络请求
/// @param success 成功回调
/// @param failure 失败回调
- (void)startMoreRequest:(NSArray<ZYNetWorkRequest *> *)requestArray
                 success:(ZYNetWorkMoreRequestSuccessBlock)success
                 failure:(ZYNetWorkMoreRequestFailureBlock)failure;

/// 取消所有网络请求
- (void)cancleMoreRequest;

@end

NS_ASSUME_NONNULL_END
