//
//  ZYNetWorkResponseData.h
//  ZYNetWork
//
//  Created by 张宇 on 2021/3/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 访问结果状态
typedef NS_ENUM(NSUInteger, ZYNetWorkResponseStatus) {
    ZYNetWorkResponseRequesting = 0, //访问中
    ZYNetWorkResponseSuccess, //访问成功
    ZYNetWorkResponseFaileAndServer, //访问失败，服务器失败
    ZYNetWorkResponseFaileAndNET //访问失败，网络失败；无网、超时
};

@interface ZYNetWorkResponseData : NSObject

/// 请求进度
@property (nonatomic, strong, nullable)  NSProgress *progress;

/// 请求结果状态
@property (nonatomic, assign) ZYNetWorkResponseStatus responseStatus;

/// 请求成功结果
@property (nonatomic, strong, nullable) id successResponse;

/// 请求失败 服务器挂了
@property (nonatomic, strong, nullable) id faileResponse;

/// 请求失败 网络挂了
@property (nonatomic, strong, nullable) id faileNETResponse;

/// 失败error
@property (nonatomic, strong, nullable) NSError *error;

@end

NS_ASSUME_NONNULL_END


