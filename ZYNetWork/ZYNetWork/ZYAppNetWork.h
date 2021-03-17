//
//  ZYAppNetWork.h
//  ZYNetWork
//
//  Created by 张宇 on 2021/3/16.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AFNetworking/AFNetworking.h>
#import "ZYNetWorkResponseData.h"
#import "MMKVManager.h"
#import "ZYNetWorkSingleton.h"

#pragma mark -- ZYAppNetWork
/*
 如网络请求失败、查询数据不匹配、请检查配置是否正确
 */

@class ZYAppNetWork;
@protocol ZYAppNetWorkDelegate <NSObject>
@optional

/// 访问成功代理
/// @param request 回调request父类
- (void)requestSuccess:(ZYAppNetWork *_Nullable)request;

/// 访问失败
/// @param request 回调request父类
- (void)requestFaile:(ZYAppNetWork *_Nullable)request;

/// 访问进度
/// @param request 回调request父类
- (void)requestProgress:(ZYAppNetWork *_Nullable)request;

/// 网络连接失败
/// @param request 回调request父类
- (void)requestNETFaile:(ZYAppNetWork *_Nullable)request;

/// 在多接口访问时才会回调此代理，表示所有并发接口已完毕，此代理只会回调一次
/// @param moreRequest 多接口
- (void)moreRequestEnd:(NSArray <ZYAppNetWork *> *_Nullable)moreRequest;

@end

/// 访问方式
typedef NS_ENUM(NSUInteger, ZYNetWorkRequestType) {
    ZYNetWorkRequestTypePOST = 0, //post
    ZYNetWorkRequestTypeGET, //get
    ZYNetWorkRequestTypeDELETE, //delete
    ZYNetWorkRequestTypePUT, //put
    ZYNetWorkRequestTypeBODY // body
};

/// 请求头格式
typedef NS_ENUM(NSUInteger, ZYNetWorkRequestSerializerType) {
    ZYNetWorkRequestSerializerTypeAuto = 0, // 默认自动匹配，只需要设置ZYSgbNetWorkContentType
    ZYNetWorkRequestSerializerTypeJSON, //JSON请求头格式
    ZYNetWorkRequestSerializerTypeHTTP //HTTP请求头格式
};

/// 返回内容格式
typedef NS_ENUM(NSUInteger, ZYNetWorkResponseSerializerType) {
    ZYNetWorkResponseSerializerTypeAuto = 0, // 默认自动匹配，只需要设置 JSON Respone
    ZYNetWorkResponseSerializerTypeJSON, //JSON Response
    ZYNetWorkResponseSerializerTypeHTTP //HTTP Response
};

/// 请求内容格式
typedef NS_ENUM(NSUInteger, ZYNetWorkContentType) {
    ZYNetWorkContentTypeJSON = 0, //application/json,
    ZYNetWorkContentTypeFORM //application/x-www-form-urlencoded
};

/// Token类型
typedef NS_ENUM(NSUInteger, ZYNetWorkTokenType) {
    ZYNetWorkTokenDefault = 0, //默认token。token=未登录token或者用户登录后的通用token
    ZYNetWorkTokenOther, //其他token
};

@interface ZYAppNetWork : NSObject

/// 访问的唯一ID，用户区分request
@property (nonatomic, copy, readonly) NSString * _Nullable requestId;

/// 代理 请求进度、成功、失败 后回调
@property (nonatomic, weak) id <ZYAppNetWorkDelegate> _Nullable delegate;

/// 网络请求回调，在请求结束后才会有值。
@property (nonatomic, strong, nullable, readonly) ZYNetWorkResponseData * responseData;

/// 全url地址 字符串类型
@property (nonatomic, copy, nonnull) NSString * requestUrl;

/// 入参
@property (nonatomic, copy, nullable) id parameters;

/// 访问方式 默认 ZYNetWorkRequestTypePOST
@property (nonatomic, assign) ZYNetWorkRequestType requestType;

/// 请求头方式 默认 ZYNetWorkRequestSerializerTypeAuto，不用设置
@property (nonatomic, assign) ZYNetWorkRequestSerializerType requestSerializerType;

/// 请求返回内容格式 默认 ZYNetWorkResponseSerializerTypeAuto，不用设置
@property (nonatomic, assign) ZYNetWorkResponseSerializerType responseSerializerType;

/// 请求内容类型 默认  ZYNetWorkContentTypeJSON
@property (nonatomic, assign) ZYNetWorkContentType contentType;

/// 请求token类型 默认 ZYNetWorkTokenDefault
@property (nonatomic, assign) ZYNetWorkTokenType tokenType;

/// 临时需要配置的header类型，有默认配置的，可以不设置
@property (nonatomic, copy, nullable) NSDictionary * header;

/// 是否需要缓存 默认为NO
@property (nonatomic, assign) BOOL isCache;

/// 设置安全协议 默认为HTTPS访问时 NO
@property (nonatomic, assign) BOOL validatesDomainName;

/// 开始访问 需设置代理 否则没有回调
- (void)startRequest;

/// 开启多接口访问
/// @param moreRequest 多接口访问
+ (void)startMoreRequest:(NSArray <ZYAppNetWork *> *_Nullable)moreRequest;

/// 取消访问  eg：ZYMediaNetWork 中重写了此方法，便于直接取消图片/视频的上传
- (void)cancleRequest;

/// 取消所有网络请求访问
- (void)cancleAllRequest;

/// 取消APP内所有的网络请求访问
+ (void)cancleAppAllRequest;

@end


