//
//  ZYNetWorkSingleton.h
//  ZYNetWork
//
//  Created by 张宇 on 2021/6/29.
//

#import <Foundation/Foundation.h>

@class AFHTTPSessionManager;

@interface ZYNetWorkSingleton : NSObject

+ (instancetype)shareSingleton;

/// 网络情况
@property (nonatomic, copy) NSString *networkType;

/// 上一次网络状态
@property (nonatomic, copy) NSString *lastNetworkType;

/// 网络管理记录 任何VC消失都会重置当前的networkManager
@property (nonatomic, strong) AFHTTPSessionManager *networkManager;

@end

