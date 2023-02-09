//
//  ZYNetWorkResponseData.h
//  ZYNetWork
//
//  Created by 张宇 on 2023/2/9.
//

#import <Foundation/Foundation.h>

/// 访问结果状态
typedef NS_ENUM(NSInteger, ZYNetWorkResponseStatus) {
    ZYNetWorkResponseRequesting = 0, //访问中
    ZYNetWorkResponseSuccess, //访问成功
    ZYNetWorkResponseFaileAndServer, //访问失败，服务器失败
    ZYNetWorkResponseFaileAndNET //访问失败，网络失败；无网、超时
};

/// 返回数据来源
typedef NS_ENUM(NSInteger, ZYNetWorkResponseDataType) {
    ZYNetWorkResponseDataTypeNetWork = 0, //网络
    ZYNetWorkResponseDataTypeCache, //本地缓存
};


@interface ZYNetWorkResponseData : NSObject

/// 请求进度
@property (nonatomic, strong)  NSProgress *progress;

/// 请求结果状态
@property (nonatomic, assign) ZYNetWorkResponseStatus responseStatus;

/// 请求成功结果
@property (nonatomic, strong) id successResponse;

/// 请求失败 服务器挂了
@property (nonatomic, strong) id faileResponse;

/// 请求失败 网络挂了
@property (nonatomic, strong) id faileNETResponse;

/// 失败error
@property (nonatomic, strong) NSError *error;

/// 返回内容 是否需要解密 默认NO
@property (nonatomic, assign) BOOL isEncryption;

/// 判断当前返回数据来源
@property (nonatomic, assign) ZYNetWorkResponseDataType responseDataType;

@end





