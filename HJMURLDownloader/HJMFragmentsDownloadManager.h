//
//  HJMFragmentsDownloadManager.h
//  Pods
//
//  Created by lchen on 21/06/2017.
//
//

#import <Foundation/Foundation.h>
#import "M3U8SegmentInfoList.h"
//#import "HJMURLDownloadManager.h"

@protocol HJMFragmentsDownloadManagerDelegate <NSObject>

@required
- (BOOL)downloadTaskShouldHaveEnoughFreeSpace:(long long)expectedData;

@optional
- (void)downloadTaskAddedToQueueWithIdentifer:(NSString *)identifier;

- (void)downloadTaskBeginWithIdentifier:(NSString *)identifier;

- (void)downloadTaskReachProgress:(CGFloat)progress identifier:(NSString *)identifier;

- (void)downloadTaskCompleteWithDirectoryPath:(NSString *)directoryPath identifier:(NSString *)identifier;

- (void)downloadTaskCompleteWithError:(NSError *)error identifier:(NSString *)identifier;

@end

@interface HJMFragmentsDownloadManager : NSObject

@property (nonatomic, weak, readonly) id<HJMFragmentsDownloadManagerDelegate> delegate;
@property (nonatomic, assign, getter = isOnlyWiFiAccess) BOOL onlyWiFiAccess;
@property (nonatomic, assign, getter = isSupportBackgroundDownload) BOOL supportBackgroundDownload;

/**
 并发下载数量，系统限制上限为4，默认为4
 */
@property (nonatomic, assign) NSInteger concurrentCount;

/**
 *  创建普通下载器，不支持后台下载，默认不限制网络
 */
+ (instancetype)defaultManager;

- (void)downloadFragmentList:(M3U8SegmentInfoList *)fragments baseUrl:(NSURL *)baseUrl delegate:(id<HJMFragmentsDownloadManagerDelegate>)delegate;

- (void)handleEventsForBackgroundURLSession:(NSString *)aBackgroundURLSessionIdentifier completionHandler:(void (^)())aCompletionHandler;

@end
