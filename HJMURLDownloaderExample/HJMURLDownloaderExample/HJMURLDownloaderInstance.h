//
//  HJMURLDownloaderInstance.h
//  HJMURLDownloaderExample
//
//  Created by Dong Han on 1/6/15.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HJMURLDownload.h>

@interface HJMURLDownloaderInstance : HJMURLDownloadManager
+ (instancetype)sharedInstance;
- (HJMURLDownloadManager *)downloadManager;
@end
