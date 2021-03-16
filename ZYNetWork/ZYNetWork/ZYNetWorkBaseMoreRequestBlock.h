//
//  ZYNetWorkBaseMoreRequestBlock.h
//  ZYNetWork
//
//  Created by 张宇 on 2021/3/16.
//

#import <Foundation/Foundation.h>
#import "ZYAppNetWork.h"

NS_ASSUME_NONNULL_BEGIN

/// 多个网络请求请求回调 moreResponse 包含了单个接口回调（ZYSgbNetWork）
typedef void(^moreRequestSuccess) (NSArray <ZYAppNetWork *>* _Nonnull moreResponse);

@interface ZYNetWorkBaseMoreRequestBlock : NSObject

/// 设置代理class，默认将代理给父类
@property (nonatomic, weak) id requestDelegate;

/// 多个网络接口请求成功回调
@property (nonatomic, copy) moreRequestSuccess moreResponse;

@end

NS_ASSUME_NONNULL_END
