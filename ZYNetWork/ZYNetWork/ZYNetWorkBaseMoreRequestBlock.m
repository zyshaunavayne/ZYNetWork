//
//  ZYNetWorkBaseMoreRequestBlock.m
//  ZYNetWork
//
//  Created by 张宇 on 2021/3/16.
//

#import "ZYNetWorkBaseMoreRequestBlock.h"

@interface  ZYNetWorkBaseMoreRequestBlock () <ZYAppNetWorkDelegate>
@end

@implementation ZYNetWorkBaseMoreRequestBlock

- (id)requestDelegate
{
    return self;
}

- (void)moreRequestEnd:(NSArray<ZYAppNetWork *> *)moreRequest
{
    if (self.moreResponse) {
        self.moreResponse(moreRequest);
    }
}

@end

