//
//  HJMURLDownloadNotificationHandler.h
//  HJMURLDownloader
//
//  Created by Dong Han on 12/23/14.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJMURLDownloadExItem.h"
#import <UIKit/UIKit.h>

@protocol HJMURLDownloadHandlerDelegate;

@interface HJMURLDownloadNotificationHandler : NSObject
@property (strong, nonatomic) NSMutableSet *delegates;

- (void)addDownloaderDelegate:(id <HJMURLDownloadHandlerDelegate>)delegate;
- (void)removeDownloaderDelegate:(id <HJMURLDownloadHandlerDelegate>)delegate;

@end

@protocol HJMURLDownloadHandlerDelegate <NSObject>
@optional
//下载
- (void)downloadURLDownloadItemWaitingToDownload:(id<HJMURLDownloadExItem>)item;
- (void)downloadURLDownloadItemWillDownload:(id<HJMURLDownloadExItem>)item;
- (void)downloadURLDownloadItem:(id<HJMURLDownloadExItem>)item
               downloadProgress:(CGFloat)progress
                      totalSize:(unsigned long long)fileSize;

- (void)downloadURLDownloadItem:(id<HJMURLDownloadExItem>)item
               didFailWithError:(NSError *)error;

- (void)downloadURLDownloadItemDidFinished:(id<HJMURLDownloadExItem>)item;
- (void)downloadURLDownloadItemWillRecover:(id<HJMURLDownloadExItem>)item;

/*暂停*/
- (void)downloadURLDownloadItemDidPaused:(id<HJMURLDownloadExItem>)item;

/*取消*/
- (void)URLDownloadItemDidCanceled:(id<HJMURLDownloadExItem>)item;

/*删除*/
- (void)URLDownloadItemDidDeleted:(id<HJMURLDownloadExItem>)item;

/*解压*/
- (void)unzippingURLDownloadItem:(id<HJMURLDownloadExItem>)item
               unzippingProgress:(CGFloat)progress;

- (void)unzippingURLDownloadItemDidFinish:(id<HJMURLDownloadExItem>)item;
- (void)unzippingURLDownloadItem:(id<HJMURLDownloadExItem>)item
                didFailWithError:(NSError *)error;

@end

