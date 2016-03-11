//
//  HJMURLDownloadObject.m
//  HJMURLDownloader
//
//  Created by Dong Han on 12/24/14.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import "HJMURLDownloadObject.h"
#import "HJMCDDownloadItem.h"

@implementation HJMURLDownloadObject

@synthesize status=_status, task=_task;
 
- (instancetype)initWithURLDownloadExItem:(id<HJMURLDownloadExItem>)downloadItem {
    if (self = [super init]) {
        _identifier = downloadItem.identifier;
        _resumeData = downloadItem.resumeData;
        _isIgnoreResumeDataAfterCancel = downloadItem.isIgnoreResumeDataAfterCancel;
        _progressBlock = downloadItem.progressBlock;
        _completionBlock = downloadItem.completionBlock;
        if ([downloadItem respondsToSelector:@selector(searchPathDirectory)]) {
            _searchPathDirectory = downloadItem.searchPathDirectory;
        } else {
            _searchPathDirectory = (NSSearchPathDirectory) kNilOptions;
        }
        _relativePath = downloadItem.relativePath;
        _remoteURL = downloadItem.remoteURL;
        _title = downloadItem.title;
        _downloadProgress = downloadItem.downloadProgress;
        _sortIndex = downloadItem.sortIndex;
        _categoryID = downloadItem.categoryID;
        _userID = downloadItem.userID;
        _userInfo = downloadItem.userInfo;

        _averageSpeed = downloadItem.averageSpeed;
        _category = downloadItem.category;
        _status = downloadItem.status;
        _receivedFileSizeInBytes = downloadItem.receivedFileSizeInBytes;
        _expectedFileSizeInBytes = downloadItem.expectedFileSizeInBytes;
        _resumedFileSizeInBytes = downloadItem.resumedFileSizeInBytes;
    }
    return self;
}

- (instancetype)initWithCDDownloadItem:(HJMCDDownloadItem *)downloadItem {
    if (self = [super init]) {
        _identifier = downloadItem.identifier;
        _category = downloadItem.category;
        _remoteURL = [NSURL URLWithString:downloadItem.downloadURLString];
        _title = downloadItem.name;
        _downloadProgress = [downloadItem.progress floatValue];
        _relativePath = downloadItem.targetPath;
        _searchPathDirectory = (NSSearchPathDirectory)[downloadItem.searchPathDirectory unsignedIntegerValue];
        _sortIndex = [downloadItem.sortIndex integerValue];
        _categoryID = downloadItem.categoryID;
        _userID = [downloadItem.userID integerValue];
        _userInfo = downloadItem.userInfo;
    }
    return self;
}



- (NSString *)fullPath {
    NSSearchPathDirectory searchPathDirectory = self.searchPathDirectory;
    if (searchPathDirectory == kNilOptions) {
        return self.relativePath;
    }
    NSString *mainPath = [NSSearchPathForDirectoriesInDomains(searchPathDirectory, NSUserDomainMask, YES) lastObject];
    return [mainPath stringByAppendingPathComponent:self.relativePath];
}

@end
