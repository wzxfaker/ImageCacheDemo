//
//  XAppModel.h
//  ImageCacheDemo
//
//  Created by X on 2018/2/28.
//  Copyright © 2018年 X. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XAppModel : NSObject
/**app名字*/
@property (nonatomic,copy) NSString *name;
@property (nonatomic,copy) NSString *icon;
@property (nonatomic,copy) NSString *download;

+ (instancetype)appModelWithDic:(NSDictionary *)dic;

@end
