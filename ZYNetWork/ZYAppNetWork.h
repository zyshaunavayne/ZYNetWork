//
//  ZYAppNetWork.h
//  ZYNetWork
//
//  Created by 张宇 on 2023/2/9.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ZYNetWorkResponseData.h"
#import "ZYNetWorkSingleton.h"

#pragma mark -- ZYAppNetWork
/*
 如网络请求失败、查询数据不匹配、请检查配置是否正确
 */

#pragma mark -- 代理
@class ZYAppNetWork;
@protocol ZYAppNetWorkDelegate <NSObject>
@optional

/// 访问成功代理
/// @param request 回调request父类
- (void)requestSuccess:(ZYAppNetWork *)request;

/// 访问失败
/// @param request 回调request父类
- (void)requestFaile:(ZYAppNetWork *)request;

/// 访问进度
/// @param request 回调request父类
- (void)requestProgress:(ZYAppNetWork *)request;

/// 网络连接失败
/// @param request 回调request父类
- (void)requestNETFaile:(ZYAppNetWork *)request;

@end

#pragma mark -- 所需枚举
/// 访问方式
typedef NS_ENUM(NSUInteger, ZYNetWorkRequestType) {
    ZYNetWorkRequestTypePOST = 0, //post
    ZYNetWorkRequestTypeGET, //get
    ZYNetWorkRequestTypeDELETE, //delete
    ZYNetWorkRequestTypePUT, //put
    ZYNetWorkRequestTypeBODY, // body
    ZYNetWorkRequestTypePATCH, //patch
    ZYNetWorkRequestTypeFILES, // 图片、文件、附件。默认会开启缓存且会立即返回
    ZYNetWorkRequestTypeFORMDATA // formData表单上传。参考formdata模块
};

/// 请求头格式
typedef NS_ENUM(NSUInteger, ZYNetWorkRequestSerializerType) {
    ZYNetWorkRequestSerializerTypeHTTP = 0,//默认自动匹配 HTTP请求头格式
    ZYNetWorkRequestSerializerTypeJSON //JSON请求头格式
};

/// 返回内容格式
typedef NS_ENUM(NSUInteger, ZYNetWorkResponseSerializerType) {
    ZYNetWorkResponseSerializerTypeJSON = 0, //默认自动匹配 JSON Response
    ZYNetWorkResponseSerializerTypeHTTP //HTTP Response
};
 
/// formData表单类型
typedef NS_ENUM(NSUInteger, ZYNetWorkFormDataType) {
    ZYNetWorkFormDataTypePhoto = 0, // 图片
    ZYNetWorkFormDataTypeOther // 其他
};

@interface ZYAppNetWork : NSObject
#pragma mark -- 基础入参
/// 访问的唯一ID，用户区分request
@property (nonatomic, copy, readonly) NSString * requestId;

/// 代理 请求进度、成功、失败 后回调
@property (nonatomic, weak) id <ZYAppNetWorkDelegate> delegate;

/// 网络请求回调，在请求结束后才会有值。
@property (nonatomic, strong, readonly) ZYNetWorkResponseData * responseData;

/// 全url地址 字符串类型
@property (nonatomic, copy) NSString * requestUrl;

/// 入参
@property (nonatomic, copy) id parameters;

/// 访问方式 默认 ZYNetWorkRequestTypePOST
@property (nonatomic, assign) ZYNetWorkRequestType requestType;

/// 请求头方式 默认 ZYNetWorkRequestSerializerTypeHTTP，不用设置
@property (nonatomic, assign) ZYNetWorkRequestSerializerType requestSerializerType;

/// 请求返回内容格式 默认 ZYNetWorkResponseSerializerTypeJson，不用设置
@property (nonatomic, assign) ZYNetWorkResponseSerializerType responseSerializerType;

/// 临时需要配置的header类型，有默认配置的，可以不设置
@property (nonatomic, copy) NSDictionary * header;

/// 是否需要缓存 默认为NO
@property (nonatomic, assign) BOOL isCache;

/// 是否需要立即返回网络请求数据。 eg：仅开启缓存时候有效。
@property (nonatomic, assign) BOOL isDirectlyBackCahche;

/// 是否需要返回缓存。且默认不返回，也不缓存。
/// eg：当为YES时，isCache、isDirectlyBackCahche 请设置为NO。且会进行缓存操作，但不会返回缓存结果。
@property (nonatomic, assign) BOOL isNoBackToCache;

/// 设置安全协议 默认为HTTPS访问时 NO
@property (nonatomic, assign) BOOL validatesDomainName;

/// 请求非必须成功。注：只用于在多个请求时。默认 NO，意为该请求必须请求成功，否则无回调。多个请求时，可设置其中某个请求为YES，让其失败时不影响其他接口的成功回调。
@property (nonatomic, assign) BOOL noNecessarySuccess;

/// 是否开启打印；默认 = YES 开启
@property (nonatomic, assign) BOOL isDebugLog;

/// 当前运行的task
@property (nonatomic, strong, readonly) NSURLSessionDataTask *dataTask;
 
/// 是否移除null的值，默认NO
@property (nonatomic, assign) BOOL removesNullValues;

#pragma mark -- formData 配参。仅ZYNetWorkRequestType = FormData有效
/// 附件数组，多个上传。必填项
@property (nonatomic, strong) NSArray *formDataArray;

/// 数据类型 默认图片类型。
@property (nonatomic, assign) ZYNetWorkFormDataType formDataType;

/// 后台接收name。key。必填项
@property (nonatomic, strong) NSString *formDataName;

/// 文件名 默认为formDataFileName.png
@property (nonatomic, strong) NSString *formDataFileName;

#pragma mark -- method
/// 开始访问 需设置代理 否则没有回调
- (void)startRequest;

/// 取消访问  eg：ZYMediaNetWork 中重写了此方法，便于直接取消图片/视频的上传
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


