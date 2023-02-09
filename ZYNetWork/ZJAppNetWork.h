//
//  ZJAppNetWork.h
//  ZJNetWork
//
//  Created by 张宇 on 2021/6/29.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ZJNetWorkResponseData.h"
#import "ZJNetWorkSingleton.h"

#pragma mark -- ZJAppNetWork
/*
 如网络请求失败、查询数据不匹配、请检查配置是否正确
 */

@class ZJAppNetWork;
@protocol ZJAppNetWorkDelegate <NSObject>
@optional

/// 访问成功代理
/// @param request 回调request父类
- (void)requestSuccess:(ZJAppNetWork *)request;

/// 访问失败
/// @param request 回调request父类
- (void)requestFaile:(ZJAppNetWork *)request;

/// 访问进度
/// @param request 回调request父类
- (void)requestProgress:(ZJAppNetWork *)request;

/// 网络连接失败
/// @param request 回调request父类
- (void)requestNETFaile:(ZJAppNetWork *)request;

@end

/// 访问方式
typedef NS_ENUM(NSUInteger, ZJNetWorkRequestType) {
    ZJNetWorkRequestTypePOST = 0, //post
    ZJNetWorkRequestTypeGET, //get
    ZJNetWorkRequestTypeDELETE, //delete
    ZJNetWorkRequestTypePUT, //put
    ZJNetWorkRequestTypeBODY, // body
    ZJNetWorkRequestTypePATCH, //patch
    ZJNetWorkRequestTypeH5 //获取H5地址专用，并非新的访问方式（临时占用）
};

/// 请求头格式
typedef NS_ENUM(NSUInteger, ZJNetWorkRequestSerializerType) {
    ZJNetWorkRequestSerializerTypeJSON = 0, //默认自动匹配 JSON请求头格式
    ZJNetWorkRequestSerializerTypeHTTP //HTTP请求头格式
};

/// 返回内容格式
typedef NS_ENUM(NSUInteger, ZJNetWorkResponseSerializerType) {
    ZJNetWorkResponseSerializerTypeJSON = 0, //默认自动匹配 JSON Response
    ZJNetWorkResponseSerializerTypeHTTP //HTTP Response
};
 
@interface ZJAppNetWork : NSObject

/// 访问的唯一ID，用户区分request
@property (nonatomic, copy, readonly) NSString * requestId;

/// 代理 请求进度、成功、失败 后回调
@property (nonatomic, weak) id <ZJAppNetWorkDelegate> delegate;

/// 网络请求回调，在请求结束后才会有值。
@property (nonatomic, strong, readonly) ZJNetWorkResponseData * responseData;

/// 全url地址 字符串类型
@property (nonatomic, copy) NSString * requestUrl;

/// 入参
@property (nonatomic, copy) id parameters;

/// 访问方式 默认 ZJNetWorkRequestTypePOST
@property (nonatomic, assign) ZJNetWorkRequestType requestType;

/// 请求头方式 默认 ZJNetWorkResponseSerializerTypeJSON，不用设置
@property (nonatomic, assign) ZJNetWorkRequestSerializerType requestSerializerType;

/// 请求返回内容格式 默认 ZJNetWorkResponseSerializerTypeJson，不用设置
@property (nonatomic, assign) ZJNetWorkResponseSerializerType responseSerializerType;

/// 临时需要配置的header类型，有默认配置的，可以不设置
@property (nonatomic, copy) NSDictionary * header;

/// 是否需要缓存 默认为NO
@property (nonatomic, assign) BOOL isCache;

/// 是否需要立即返回网络请求数据。 eg：仅开启缓存时候有效。
@property (nonatomic, assign) BOOL isDirectlyBackCahche;

/// 设置安全协议 默认为HTTPS访问时 NO
@property (nonatomic, assign) BOOL validatesDomainName;

/// 请求非必须成功。注：只用于在多个请求时。默认 NO，意为该请求必须请求成功，否则无回调。多个请求时，可设置其中某个请求为YES，让其失败时不影响其他接口的成功回调。
@property (nonatomic, assign) BOOL noNecessarySuccess;

/// 是否开启打印；默认 = YES 开启
@property (nonatomic, assign) BOOL isDebugLog;

/// 当前运行的task
@property (nonatomic, strong, readonly) NSURLSessionDataTask *dataTask;
 
/// 开始访问 需设置代理 否则没有回调
- (void)startRequest;

/// 取消访问  eg：ZJMediaNetWork 中重写了此方法，便于直接取消图片/视频的上传
- (void)cancleRequest;

/// 取消所有网络请求访问
- (void)cancleAllRequest;

/// 取消APP内所有的网络请求访问
+ (void)cancleAppAllRequest;

/// 检测数据访问成功后对应的数据状态
- (BOOL)checkReuqestResultCorrect:(NSDictionary *)dic;

/// 处理Code业务逻辑 参照后端对应的errCode码进行配置
- (void)handleCodeConfig:(NSInteger)code;

@end


