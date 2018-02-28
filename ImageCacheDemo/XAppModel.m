//
//  XAppModel.m
//  ImageCacheDemo
//
//  Created by X on 2018/2/28.
//  Copyright © 2018年 X. All rights reserved.
//

#import "XAppModel.h"

@implementation XAppModel

+ (instancetype)appModelWithDic:(NSDictionary *)dic{
    XAppModel *app = [[XAppModel alloc] init];
    [app setValuesForKeysWithDictionary:dic];
    return app;
}

@end
