//
//  ZYAppNetWorkAgent.m
//  ZYNetWork
//
//  Created by Fan Li Lin on 2022/10/19.
//

#import "ZYAppNetWorkAgent.h"
#import "ZYAppNetWork.h"
#import <pthread/pthread.h>

#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)

@implementation ZYAppNetWorkAgent {
    NSMutableArray<ZYAppNetWork *> *_requestsRecord;
    pthread_mutex_t _lock;
}

+ (ZYAppNetWorkAgent *)sharedAgent
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _requestsRecord = [NSMutableArray array];
        pthread_mutex_init(&_lock, NULL);
    }
    return self;
}

- (void)addRequest:(ZYAppNetWork *)request
{
    Lock();
    [_requestsRecord addObject:request];
    Unlock();
}

- (void)removeRequest:(ZYAppNetWork *)request
{
    Lock();
    [_requestsRecord removeObject:request];
    NSLog(@"ZYNetWork Request queue size = %zd", [_requestsRecord count]);
    Unlock();
}

@end
