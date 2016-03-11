//
//  HJMURLDownloaderInstance.m
//  HJMURLDownloaderExample
//
//  Created by Dong Han on 1/6/15.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import "HJMURLDownloaderInstance.h"

@implementation HJMURLDownloaderInstance

static id sharedManager = nil;

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] initBackgroundDownloaderWithIdentifier:@"" maxConcurrentDownloads:1 OnlyWiFiAccess:NO];
    });
    return sharedManager;
}

- (HJMURLDownloadManager *)downloadManager {
    return sharedManager;
}

@end
