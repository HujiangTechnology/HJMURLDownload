//
//  ProcessActionAfterDownloadProtocol.h
//  HJMURLDownloader
//
//  Created by Yozone Wang on 15/1/30.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HJMURLDownloadObject;

@protocol ProcessActionAfterDownloadProtocol <NSObject>

+ (instancetype)executeActionOnQueue:(NSOperationQueue *)queue
                  withDownloadObject:(HJMURLDownloadObject *)downloadObject;

@end
