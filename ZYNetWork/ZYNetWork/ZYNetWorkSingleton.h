//
//  ZYNetWorkSingleton.h
//  ZYNetWork
//
//  Created by 张宇 on 2021/3/16.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZYNetWorkSingleton : NSObject

+ (instancetype)shareSingleton;

/// 网络情况
@property (nonatomic, strong) NSString *networkType;

/// 上一次网络状态
@property (nonatomic, strong) NSString *lastNetworkType;

/// 经营帮App服务器主地址
@property (nonatomic, strong) NSString *mainAddress;

/// 网络管理记录 任何VC消失都会重置当前的networkManager
@property (nonatomic, strong) AFHTTPSessionManager *networkManager;

@end

NS_ASSUME_NONNULL_END
