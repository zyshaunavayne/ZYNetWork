//
//  ZYNetWorkSingleton.m
//  ZYNetWork
//
//  Created by 张宇 on 2023/2/9.
//

#import "ZYNetWorkSingleton.h"
#import <AFNetworking/AFHTTPSessionManager.h>

@implementation ZYNetWorkSingleton

static ZYNetWorkSingleton *instance = nil;

+ (instancetype)shareSingleton {
    return [[self alloc] init];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    if (instance == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            instance = [super allocWithZone:zone];
        });
    }
    return instance;
}

- (instancetype)init {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [super init];
        [self checkNetwork];
    });
    return instance;
}

- (void)checkNetwork
{
    self.lastNetworkType = @"2";
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[AFNetworkReachabilityManager sharedManager ] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case -1:
                self.networkType = @"0";
                self.lastNetworkType = @"0";
                break;
            case 0:
                self.networkType = @"-1";
                self.lastNetworkType = @"-1";
                break;
            case 1:
                self.networkType = @"1";
                if (![self.lastNetworkType isEqualToString:@"1"]) {
                    if ([self.lastNetworkType isEqualToString:@"0"] || [self.lastNetworkType isEqualToString:@"-1"]) {

                    }
                    self.lastNetworkType = @"1";
                }
                break;
            case 2:
                self.networkType = @"2";
                self.lastNetworkType = @"2";
                break;
            default:
                break;
        }
        if(status == AFNetworkReachabilityStatusReachableViaWWAN || status == AFNetworkReachabilityStatusReachableViaWiFi)
        {
            NSLog(@"有网");
        }else{
            self.networkType = @"-1";
            self.lastNetworkType = @"-1";
            return ;
        }
    }];
}

@end



