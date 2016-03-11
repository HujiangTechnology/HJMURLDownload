//
//  LessonItem.h
//  HJMURLDownloaderExample
//
//  Created by Dong Han on 12/30/14.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJMURLDownloadExItem.h"

@interface LessonItem : NSObject <HJMURLDownloadExItem>

@property (strong, nonatomic) NSString *identifier;
@property (strong, nonatomic) NSString *relativePath;

@property (strong, nonatomic) NSData *resumeData;
@property (strong, nonatomic) NSURL *remoteURL;

@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *category;
@property (copy, nonatomic) NSDictionary *userInfo;
@property (strong, nonatomic) NSDate *startDate;

@property (nonatomic, assign) float downloadProgress;
@property (nonatomic, assign) int64_t receivedFileSizeInBytes;
@property (nonatomic, assign) int64_t expectedFileSizeInBytes;
@property (nonatomic, assign) int64_t resumedFileSizeInBytes;
@property (nonatomic, assign) float averageSpeed;
@property (nonatomic, assign) NSInteger sortIndex;
@property (nonatomic, copy) NSString * categoryID;
@property (nonatomic, assign) NSInteger userID;


@property (strong, nonatomic) NSManagedObjectID *downloadItemObjectID;
@property (copy, nonatomic) HJMURLDownloadProgressBlock progressBlock;
@property (copy, nonatomic) HJMURLDownloadCompletionBlock completionBlock;
@end
