//
//  ZYMMKVManager.h
//  ZYNetWork
//
//  Created by 张宇 on 2021/6/29.
//

#import <Foundation/Foundation.h>

// 网络数据本地缓存框架
#import <MMKV/MMKV.h>

@interface ZYMMKVManager : NSObject

/// 获取MMKV
+ (MMKV *)getMMKV;

/// 清理缓存
+ (void)clearMemoryCache;

@end

