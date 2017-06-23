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
@property (nonatomic, assign) BOOL isSupportBackgroundDownload;

/**
 *  创建普通下载器，不支持后台下载，默认不限制网络
 */
+ (instancetype)defaultManager;

/**
 *  创建普通下载器，不支持后台下载
 *
 *  @param aMaxConcurrentFileDownloadsCount 最大并发数(系统限制最大并发为4)
 */
- (instancetype)initStandardDownloaderWithMaxConcurrentDownloads:(NSInteger)aMaxConcurrentFileDownloadsCount;

/**
 *  创建后台下载器，
 *
 *  @param identifier                       唯一标识，建议identifier命名为 bundleid.XXXXBackgroundDownloader,
 *  @param aMaxConcurrentFileDownloadsCount 最大并发数(系统限制最大并发为4)
 *  @param isOnlyWiFiAccess                   是否仅WiFi环境下载
 */
- (instancetype)initBackgroundDownloaderWithIdentifier:(NSString *)identifier maxConcurrentDownloads:(NSInteger)aMaxConcurrentFileDownloadsCount OnlyWiFiAccess:(BOOL)isOnlyWiFiAccess;

- (void)downloadFragmentList:(M3U8SegmentInfoList *)fragments baseUrl:(NSURL *)baseUrl delegate:(id<HJMFragmentsDownloadManagerDelegate>)delegate;

- (void)handleEventsForBackgroundURLSession:(NSString *)aBackgroundURLSessionIdentifier completionHandler:(void (^)())aCompletionHandler;

@end
