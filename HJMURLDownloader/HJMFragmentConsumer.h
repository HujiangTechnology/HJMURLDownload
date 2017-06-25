//
//  HJMFragmentConsumer.h
//  Pods
//
//  Created by lchen on 21/06/2017.
//
//

#import <Foundation/Foundation.h>
#import "M3U8SegmentInfo.h"

typedef NS_ENUM(NSUInteger, HJMFragmentDownloadStatus) {
    HJMURLDownloadStatusNone,       // 数据库中没有记录，是一个新任务
    HJMURLDownloadStatusCanResume,  // 数据库中有记录，可以回复下载
    HJMURLDownloadStatusCompleted,  // 数据库中没有记录了，本地有文件夹，说明已经完成了
};

@protocol HJMFragmentConsumerDelegate <NSObject>

@required
- (M3U8SegmentInfo *)oneMoreFragmentWithIdentifier:(NSString *)identifier;

- (void)oneFragmentDownloadedWithFragmentIdentifier:(NSString *)fragmentIdentifier identifier:(NSString *)identifier;

- (void)downloadTaskDidCompleteWithError:(NSError *)error identifier:(NSString *)identifier;

- (void)didStoppedCurrentFragmentListDownloading;

- (NSString *)currentDownloadingIdentifier;

- (void)fragmentSaveToDiskFailed;

@end

@interface HJMFragmentConsumer : NSObject

@property (nonatomic, weak) id<HJMFragmentConsumerDelegate> delegate;

@property (nonatomic, assign, readonly) BOOL isBusy;

- (NSString *)directoryPathWithIdentifier:(NSString *)identifier;

- (void)stopCurrentDownloadingFragmentList;

- (BOOL)directoryExistsWithIdentifer:(NSString *)identifier;

- (instancetype)initWithLimitedConcurrentCount:(NSInteger)count isSupportBackground:(BOOL)isSupportBackground backgroundIdentifier:(NSString *)backgroundIdentifier;

- (void)handleEventsForBackgroundURLSession:(NSString *)aBackgroundURLSessionIdentifier completionHandler:(void (^)())aCompletionHandler;

- (void)startToDownloadFragmentArray:(NSArray <M3U8SegmentInfo *> *)fragmentArray arrayIdentifer:(NSString *)identifier;

@end
