//
//  ZYAppNetWorkAgent.h
//  ZYNetWork
//
//  Created by Fan Li Lin on 2022/10/19.
//

#import <Foundation/Foundation.h>

@class ZYAppNetWork;

@interface ZYAppNetWorkAgent : NSObject

/// 网络任务管理器
+ (ZYAppNetWorkAgent *)sharedAgent;

/// 添加网络任务暂存
- (void)addRequest:(ZYAppNetWork *)request;

/// 取消网络任务并移除
- (void)removeRequest:(ZYAppNetWork *)request;

@end

