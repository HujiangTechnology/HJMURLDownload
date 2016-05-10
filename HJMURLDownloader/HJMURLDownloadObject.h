//
//  HJMURLDownloadObject.h
//  HJMURLDownloader
//
//  Created by Dong Han on 12/24/14.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJMURLDownloadExItem.h"


@class HJMCDDownloadItem;

@interface HJMURLDownloadObject : NSObject <HJMURLDownloadExItem>

@property (strong, nonatomic) NSURL *remoteURL;
@property (strong, nonatomic) NSData *resumeData;

@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *category;
@property (copy, nonatomic) NSString *categoryID;
@property (copy, nonatomic) NSDictionary *userInfo;
@property (strong, nonatomic) NSString *identifier;
@property (assign, nonatomic) NSSearchPathDirectory searchPathDirectory;
@property (strong, nonatomic) NSString *relativePath;
@property (strong, nonatomic) NSDate *startDate;
@property (nonatomic) BOOL isIgnoreResumeDataAfterCancel;

@property (assign, nonatomic) NSInteger userID;
@property (assign, nonatomic) NSInteger sortIndex;

@property (nonatomic, assign) float downloadProgress;
@property (nonatomic, assign) int64_t receivedFileSizeInBytes;
@property (nonatomic, assign) int64_t expectedFileSizeInBytes;
@property (nonatomic, assign) int64_t resumedFileSizeInBytes;
@property (nonatomic, assign) float averageSpeed;

@property (strong, nonatomic) NSManagedObjectID *downloadItemObjectID;

@property (nonatomic) BOOL isLastDownload;

@property (copy, nonatomic) HJMURLDownloadProgressBlock progressBlock;
@property (copy, nonatomic) HJMURLDownloadCompletionBlock completionBlock;

- (instancetype)initWithURLDownloadExItem:(id<HJMURLDownloadExItem>)downloadItem;
- (instancetype)initWithCDDownloadItem:(HJMCDDownloadItem *)downloadItem;

@end
