//
//  HJMUserInfoTransformer.m
//  HJMURLDownloader
//
//  Created by Yozone Wang on 14/12/29.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import "HJMUserInfoTransformer.h"

@implementation HJMUserInfoTransformer

- (id)transformedValue:(id)value {
    return [NSKeyedArchiver archivedDataWithRootObject:value];
}

- (id)reverseTransformedValue:(id)value {
    return [NSKeyedUnarchiver unarchiveObjectWithData:value];
}

@end
