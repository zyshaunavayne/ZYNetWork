//
//  MMKVManager.m
//  ZYNetWork
//
//  Created by 张宇 on 2021/3/16.
//

#import "MMKVManager.h"

@implementation MMKVManager

+ (void)load
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *libraryPath = (NSString *) [paths firstObject];
    NSString *rootDir = [libraryPath stringByAppendingPathComponent:@"mmkvCaches"];
    [MMKV initializeMMKV:rootDir];
    
    MMKV *mKV = MMKVManager.getMMKV;
    NSString *version = [[[NSBundle mainBundle]infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *mmkvVersion = [mKV getStringForKey:@"CFBundleShortVersionString"];
    
    if (![version isEqual:mmkvVersion] || mmkvVersion.length == 0) {
        // 清空所有本地缓存
        [self clearMemoryCache];
        // 缓存版本号
        [mKV setString:version forKey:@"CFBundleShortVersionString"];
    }
}

+ (MMKV *)getMMKV
{
    return [MMKV defaultMMKV];
}

+ (void)clearMemoryCache
{
    [MMKVManager.getMMKV clearMemoryCache];
}

@end
