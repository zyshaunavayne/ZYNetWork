//
//  MMKVManager.h
//  ZYNetWork
//
//  Created by 张宇 on 2021/3/16.
//

#import <Foundation/Foundation.h>

// 网络数据本地缓存框架
#import <MMKV/MMKV.h>

NS_ASSUME_NONNULL_BEGIN

@interface MMKVManager : NSObject

/// 获取MMKV
+ (MMKV *)getMMKV;

/// 清理缓存
+ (void)clearMemoryCache;

@end

NS_ASSUME_NONNULL_END
