//
//  HJMFragmentsDownloadManager.h
//  Pods
//
//  Created by lchen on 21/06/2017.
//
//

#import <Foundation/Foundation.h>
#import "M3U8SegmentInfoList.h"
#import "HJMFragmentConsumer.h"

@protocol HJMFragmentsDownloadManagerDelegate <NSObject>

/**
 当前有任务正在下载，新添加的下载任务被加入到队列中，等待前面的任务完成再开始

 @param identifier 加入队列等待的任务的唯一标示，接入方应该能够通过这个标示找到对应的任务
 */
- (void)downloadTaskAddedToQueueWithIdentifer:(NSString *)identifier;

/**
 通知代理，任务已经开始下载了

 @param identifier 任务标示
 */
- (void)downloadTaskBeginWithIdentifier:(NSString *)identifier;

/**
 下载的任务完成进度，任务中的每一个fragment下载完成会回调一次该方法

 @param progress 完成进度 下载完成的fragment的个数／总个数
 @param identifier 任务标示
 */
- (void)downloadTaskReachProgress:(CGFloat)progress identifier:(NSString *)identifier;

/**
 任务下载完成，自动下载队列中的下一个任务

 @param directoryPath 任务中所有的fragments保存的文件夹
 @param identifier 任务标示
 */
- (void)downloadTaskCompleteWithDirectoryPath:(NSString *)directoryPath identifier:(NSString *)identifier;

/**
 任务经过重试(如有)，下载失败，自动下载队列中的下一个任务

 @param error 出错信息
 @param identifier 任务标示
 */
- (void)downloadTaskCompleteWithError:(NSError *)error identifier:(NSString *)identifier;

/**
 存储出错 有可能是空间不够引起的
 */
- (void)fragmentSaveToDiskFailedWithIdentifier:(NSString *)identifier;

- (void)fragmentDidStoppedWithIdentifier:(NSString *)identifier;

- (void)allFragmentListsHaveRunOut;

@end

@interface HJMFragmentsDownloadManager : NSObject

/**
 支持background下载，默认为NO
 */
@property (nonatomic, assign, getter = isSupportBackgroundDownload) BOOL supportBackgroundDownload;

/**
 并发下载数量，系统限制上限为4，默认为4
 */
@property (nonatomic, assign) NSInteger concurrentCount;

@property (nonatomic, copy) NSString *backgroundIdentifier;

/**
 *  创建普通下载器，不支持后台下载，默认不限制网络，
 *  不论通过这个方法实例化还是通过init实例化，返回的均是单例
 */
+ (instancetype)defaultManager;

/**
 fragmentList的下载状态

 @param identifier fragment list标示
 */
- (HJMFragmentDownloadStatus)fragmentListDownloadStatusWithIdentifier:(NSString *)identifier;

/**
 下载任务，调用方法时无需对队列中的fragments是否已经下载进行过滤

 @param fragments 待下载的任务
 */
- (void)downloadFragmentList:(M3U8SegmentInfoList *)fragments delegate:(id<HJMFragmentsDownloadManagerDelegate>)delegate;

/**
 停止下载对应的任务

 @param identifier 任务标示
 */
- (void)stopDownloadFragmentListWithIdentifier:(NSString *)identifier;

/**
 删除对应的文件

 @param identifier 任务标示
 */
- (void)deleteFragemntListWithIdentifier:(NSString *)identifier;

/**
 处理background download任务完成时，系统对程序的唤起 https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/URLLoadingSystem/Articles/UsingNSURLSession.html
 */
- (void)handleEventsForBackgroundURLSession:(NSString *)aBackgroundURLSessionIdentifier completionHandler:(void (^)())aCompletionHandler;

@end
