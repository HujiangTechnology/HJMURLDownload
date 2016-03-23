
//  HJMURLDownloadManager.h
//  HJMURLDownloader
//
//  Created by Dong Han on 12/23/14.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJMURLDownloadObject.h"
#import "HJMURLDownloadExItem.h"
#import "HJMURLDownloadNotificationHandler.h"

@class HJMDownloadCoreDataManager;

typedef void(^HJMURLDownloadBackgroundSessionCompletionHandlerBlock)();

extern NSString *const kHJMURLDownloaderOnlyWiFiAccessNotification;
extern NSString *const kHJMURLDownloaderDownloadTaskDidFinishDownloadingNotification;

@protocol HJMURLDownloadManagerDelegate <NSObject>
/**
 *  是否有足够的磁盘空间
 *
 *  @param expectedData 需要的磁盘空间
 *
 *  @return 如果为YES 说明有足够的空间存储目标文件
 */
- (BOOL)downloadTaskShouldHaveEnoughFreeSpace:(long long)expectedData;

/**
 *  完成下载任务后的回调方法
 *
 *  @param item  下载任务模型对象
 *  @param block 完成后的回调Block
 */
@optional
- (void)downloadTaskDidFinishWithDownloadItem:(id<HJMURLDownloadExItem>)item completionBlock:(void (^)(void))block;
@end

@interface HJMURLDownloadManager : NSObject

@property(nonatomic, readonly) HJMURLDownloadNotificationHandler *URLDownloadHandler;

@property (nonatomic) id<HJMURLDownloadManagerDelegate> delegate;

@property (nonatomic) NSInteger userID;

@property (strong, readonly, nonatomic) HJMDownloadCoreDataManager *coreDataManager;

@property (readonly, nonatomic) BOOL isOnlyWiFiAccess;

@property (readonly, copy, nonatomic) NSString *backgroundIdentifier;

@property (nonatomic, getter=isRecoverDownloadAfterReopenApp) BOOL recoverDownloadAfterReopenAppEnable;

/**
 *  单例方法
 */
+ (instancetype)defaultManager;

/**
 *  创建普通下载器，不支持后台下载，默认不限制网络
 *
 *  @param aMaxConcurrentFileDownloadsCount 最大并发数
 */
- (instancetype)initStandardDownloaderWithMaxConcurrentDownloads:(NSInteger)aMaxConcurrentFileDownloadsCount;

/**
 *  创建后台下载器，
 *
 *  @param identifier                       唯一标识，建议identifier命名为 bundleid.XXXXBackgroundDownloader,
 *  @param aMaxConcurrentFileDownloadsCount 最大并发数
 *  @param OnlyWiFiAccess                   是否仅WiFi环境下载
 */
- (instancetype)initBackgroundDownloaderWithIdentifier:(NSString *)identifier maxConcurrentDownloads:(NSInteger)aMaxConcurrentFileDownloadsCount OnlyWiFiAccess:(BOOL)isOnlyWiFiAccess;


/* -----后台下载模式BackgroundMode只能创建一个且和defaultManager冲突，下列初始化方法废弃 */

/**
 *  初始化最大并发数不支持后台下载
 *
 *  @param aMaxConcurrentFileDownloadsCount 最大并发数
 */
- (instancetype)initWithMaxConcurrentDownloads:(NSInteger)aMaxConcurrentFileDownloadsCount __attribute__ ((deprecated));

/**
 *  初始化最大并发数
 *
 *  @param aMaxConcurrentFileDownloadsCount 最大并发数
 *  @param isBackgroundMode                 是否支持后台下载
 */
- (instancetype)initWithMaxConcurrentDownloads:(NSInteger)aMaxConcurrentFileDownloadsCount isSupportBackgroundMode:(BOOL)isBackgroundMode __attribute__ ((deprecated));

/**
 *  初始化最大并发数
 *
 *  @param aMaxConcurrentFileDownloadsCount 最大并发数
 *  @param isBackgroundMode                 是否支持后台下载
 *  @param OnlyWiFiAccess                   是否仅WiFi环境下载
 */
- (instancetype)initWithMaxConcurrentDownloads:(NSInteger)aMaxConcurrentFileDownloadsCount isSupportBackgroundMode:(BOOL)isBackgroundMode OnlyWiFiAccess:(BOOL)isOnlyWiFiAccess __attribute__ ((deprecated));

/**
 *  基本添加和取消操作
 *
 *  @param url           下载文件的URL
 *  @param progressBlock 下载进度Block   Block内回传下载进度，文件总长度，剩余时间
 *  @param completeBlock 完成后回调Block Block内回传完成后的文件的沙盒路径，是否完成状态
 * 注意: 如果App在本次运行时意外crash或者后台被系统回收，则下次启动时为避免重复下载，请先检查 NSCachesDirectory/url.lastPathComponent 是否存在已下载好的包，若不存在，则重新调用下载方法，正常情况会找回上次下载继续进行。
 */

- (void)addDownloadWithURL:(NSURL *)url
                  progress:(HJMURLDownloadProgressBlock)progressBlock
                  complete:(HJMURLDownloadCompletionBlock)completeBlock;
/**
 *  增加下载任务
 *
 *  @param downloadItem 下载对象模型
 */
- (void)addURLDownloadItem:(id<HJMURLDownloadExItem>)downloadItem;

/**
 *  获取下载任务信息
 *
 *  @param identifier 下载对象的identifier
 */
- (id<HJMURLDownloadExItem>)getAURLDownloadWithIdentifier:(NSString *)identifier;

/**
 *  取消下载任务
 *
 *  @param downloadItem 下载对象模型
 */
- (void)cancelAURLDownloadItem:(id<HJMURLDownloadExItem>)downloadItem;

/**
 *  取消下载任务
 *
 *  @param identifier 下载对象的identifier
 */
- (void)cancelAURLDownloadWithIdentifier:(NSString *)identifier;

/**
 *  取消所有下载任务
 */
- (void)cancelAllDownloads;

/**
 *  删除下载任务
 *
 *  @param identifier 下载任务的标识  只删除下载任务，不更新数据库中的数据
 */
- (void)deleteAURLDownloadItemIdentifier:(NSString *)identifier;

/**
 *  删除所有下载任务  更新数据库中的数据
 */
- (void)deleteAllDownloads;

/**
 *  判断当前的identifier是否在下载或者等待队列中
 *
 *  @param aDownloadIdentifier 下载任务的标识
 *
 *  @return 如果符合标识的下载任务正在下载，返回YES
 */
- (BOOL)isDownloadingIdentifier:(NSString *)aDownloadIdentifier;

/**
 *  判断是否还有下载任务
 *
 *  @return 如果正在下载的任务数量大于0 或者等待下载的任务数大于0 返回YES
 */
- (BOOL)hasActiveDownloads;

/**
 *  为session.configuration.identifier标识为identifier的对象添加完成后回调的Block
 *
 *  @param handler    完成后回调的Block
 *  @param identifier 标识
 */
- (void)addCompletionHandler:(HJMURLDownloadBackgroundSessionCompletionHandlerBlock)handler forSession: (NSString *)identifier;

/**
 *  调用session.configuration.identifier标识为identifier的下载任务完成后回调Block
 *
 *  @param identifier 标识
 */
- (void)callCompletionHandlerForSession:(NSString *)identifier;

/**
 *  添加响应代理
 *
 *  @param delegate 下载中操作的响应代理
 */
- (void)addNotificationHandler:(id<HJMURLDownloadHandlerDelegate>)delegate;

/**
 *  移除响应代理
 *
 *  @param delegate 下载中操作的响应代理
 */
- (void)removeNotificationHandler:(id<HJMURLDownloadHandlerDelegate>)delegate;
@end
