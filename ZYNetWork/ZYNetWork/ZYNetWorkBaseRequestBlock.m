//
//  ZYNetWorkBaseRequestBlock.m
//  ZYNetWork
//
//  Created by 张宇 on 2021/3/16.
//

#import "ZYNetWorkBaseRequestBlock.h"

@interface  ZYNetWorkBaseRequestBlock () <ZYAppNetWorkDelegate>
@end

@implementation ZYNetWorkBaseRequestBlock

- (id)requestDelegate
{
    return self;
}

- (void)requestSuccess:(ZYAppNetWork *)request
{
    if (self.successResponse) {
        self.successResponse(request);
    }
}

- (void)requestProgress:(ZYAppNetWork *)request
{
    if (self.progressResponse) {
        self.progressResponse(request);
    }
}

- (void)requestNETFaile:(ZYAppNetWork *)request
{
    if (self.faileNETResponse) {
        self.faileNETResponse(request);
    }
}

- (void)requestFaile:(ZYAppNetWork *)request
{
    if (self.faileResponse) {
        self.faileResponse(request);
    }
}

@end


