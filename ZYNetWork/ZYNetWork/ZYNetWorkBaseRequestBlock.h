//
//  ZYNetWorkBaseRequestBlock.h
//  ZYNetWork
//
//  Created by 张宇 on 2021/3/16.
//

#import <Foundation/Foundation.h>
#import "ZYAppNetWork.h"

NS_ASSUME_NONNULL_BEGIN

/// 请求成功回调
typedef void(^requestSuccess) (ZYAppNetWork * _Nullable success);

/// 请求进度回调
typedef void(^requestProgress) (ZYAppNetWork * _Nullable progress);

/// 请求失败回调
typedef void(^requestFaile) (ZYAppNetWork * _Nullable faile);

/// 网络异常失败回调
typedef void(^requestFaileNET) (ZYAppNetWork * _Nullable faileNET);

/// 请求数据结束后 回调基类  所有的网络请求需要继承此类
@interface ZYNetWorkBaseRequestBlock : NSObject

/// 设置代理class，默认将代理给父类
@property (nonatomic, weak) id requestDelegate;

/// 请求成功Block
@property (nonatomic, copy) requestSuccess successResponse;

/// 请求进度Block
@property (nonatomic, copy) requestProgress progressResponse;

/// 请求失败回调
@property (nonatomic, copy) requestFaile faileResponse;

/// 请求失败回调
@property (nonatomic, copy) requestFaileNET faileNETResponse;

@end

NS_ASSUME_NONNULL_END


