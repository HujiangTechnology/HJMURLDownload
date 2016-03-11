//
//  HJMURLDownloadExItem.h
//  HJMURLDownloader
//
//  Created by Dong Han on 12/23/14.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

typedef NS_ENUM(NSInteger, HJMURLDownloadStatus) {
    HJMURLDownloadStatusWaiting = 0,
    HJMURLDownloadStatusDownloading,
    HJMURLDownloadStatusPaused,
    HJMURLDownloadStatusSucceeded,
    HJMURLDownloadStatusProcessing,
    HJMURLDownloadStatusDownloadFailed,
};

typedef NS_ENUM(NSInteger, HJMURLDownloadError) {
    HJMURLDownloadErrorInvalidURL = 0,
    HJMURLDownloadErrorHTTPError,
    HJMURLDownloadErrorNotEnoughFreeDiskSpace
};

typedef void(^HJMURLDownloadProgressBlock)(float progress, int64_t totalLength, NSInteger remainingTime, float averageSpeed);
typedef void(^HJMURLDownloadCompletionBlock)(BOOL completed, NSURL *didFinishDownloadingToURL);

@protocol HJMURLDownloadExItem <NSObject>

@property (strong, nonatomic) NSURL *remoteURL;
@property (strong, nonatomic) NSString *identifier;
@property (strong, nonatomic) NSString *relativePath;
@property (nonatomic) BOOL isIgnoreResumeDataAfterCancel;

@optional
@property(nonatomic, assign) NSSearchPathDirectory searchPathDirectory;
@property (strong, nonatomic) NSURLSessionDownloadTask *task;
@property (assign, nonatomic) HJMURLDownloadStatus status;

@property (strong, nonatomic) NSData *resumeData;

@property (assign, nonatomic) NSInteger sortIndex;
@property (assign, nonatomic) NSInteger userID;
@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *category;
@property (copy, nonatomic) NSString *categoryID;
@property (copy, nonatomic) NSDictionary *userInfo;
@property (strong, nonatomic) NSDate *startDate;

@property (nonatomic, assign) float downloadProgress;
@property (nonatomic, assign) int64_t receivedFileSizeInBytes;
@property (nonatomic, assign) int64_t expectedFileSizeInBytes;
@property (nonatomic, assign) int64_t resumedFileSizeInBytes;
@property (nonatomic, assign) float averageSpeed;

@property (strong, nonatomic) NSManagedObjectID *downloadItemObjectID;
@property (copy, nonatomic) HJMURLDownloadProgressBlock progressBlock;
@property (copy, nonatomic) HJMURLDownloadCompletionBlock completionBlock;

- (NSString *)fullPath;

@end
