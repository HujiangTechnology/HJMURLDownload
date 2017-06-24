//
//  HJMFragmentsDownloadManager.m
//  Pods
//
//  Created by lchen on 21/06/2017.
//
//

#import "HJMFragmentCallBackModel.h"
#import "HJMFragmentConsumer.h"
#import "HJMFragmentDBManager.h"
#import "HJMFragmentProducer.h"
#import "HJMFragmentsDownloadManager.h"
#import "HJMURLDownload.h"
#import "M3U8SegmentInfoList.h"

@interface HJMFragmentsDownloadManager () <HJMFragmentProducerDelegate, HJMFragmentConsumerDelegate>

@property (nonatomic, strong) HJMFragmentProducer *producer;
@property (nonatomic, strong) HJMFragmentConsumer *consumer;

@property (nonatomic, strong) NSMutableArray <HJMFragmentCallBackModel *> *callbackModelArray;

/**
 下载队列标识，也用作数据库表名
 */
//@property (nonatomic, copy) NSString *tableName;

@end

@implementation HJMFragmentsDownloadManager

+ (instancetype)defaultManager {
    static HJMFragmentsDownloadManager *singletonInstance;
    if (!singletonInstance) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            singletonInstance = [[super allocWithZone:NULL] init];
        });
    }
    return singletonInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [self defaultManager];
}

- (instancetype)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(changeWiFiAccess:)
                                                     name:kHJMURLDownloaderOnlyWiFiAccessNotification
                                                   object:nil];
        self.producer = [[HJMFragmentProducer alloc] init];
        self.producer.delegate = self;
        self.consumer = [[HJMFragmentConsumer alloc] init];
        self.consumer.delegate = self;
        self.concurrentCount = 4;
        self.onlyWiFiAccess = NO;
        self.supportBackgroundDownload = YES;
    }
    return self;
}

- (BOOL)canResumeDownloadWithIdentifier:(NSString *)identifier {
    return [self.producer isTableExistInDatabaseWith:identifier];
}

- (void)downloadFragmentList:(M3U8SegmentInfoList *)fragments delegate:(id<HJMFragmentsDownloadManagerDelegate>)delegate {
    // 把delegate记录下来供以后调用
    HJMFragmentCallBackModel *model = [[HJMFragmentCallBackModel alloc] initWithIdentifier:fragments.identifier delegate:delegate];
    [self.callbackModelArray addObject:model];
    // 把所有的任务丢给producer
    [self.producer addFragmentsArray:fragments];
    
    // 看看consumer是不是空闲
    if (self.consumer.isBusy) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(downloadTaskAddedToQueueWithIdentifer:)]) {
            [self.delegate downloadTaskAddedToQueueWithIdentifer:fragments.identifier];
        }
    } else {
        // 从producer拿数据开始下载
        NSArray <M3U8SegmentInfo *> *fragmentsToDownload = [self.producer fragmentsWithIdentifier:fragments.identifier originalArray:fragments.segmentInfoList limitedCount:self.concurrentCount];
        [self.consumer startToDownloadFragmentArray:fragmentsToDownload arrayIdentifer:fragments.identifier];
        if (self.delegate && [self.delegate respondsToSelector:@selector(downloadTaskBeginWithIdentifier:)]) {
            [self.delegate downloadTaskBeginWithIdentifier:fragments.identifier];
        }
    }
}

- (id<HJMFragmentsDownloadManagerDelegate>)delegateForIdentifier:(NSString *)identifier {
    for (HJMFragmentCallBackModel *model in self.callbackModelArray) {
        if ([model.identifier isEqualToString:identifier]) {
            return model.delegate;
        }
    }
    return nil;
}

- (void)removeRecordFromCallbackArrayWithIdentifier:(NSString *)identifier {
    HJMFragmentCallBackModel *tempModel = nil;
    for (HJMFragmentCallBackModel *model in self.callbackModelArray) {
        if ([model.identifier isEqualToString:identifier]) {
            tempModel = model;
        }
    }
    if (tempModel) {
        [self.callbackModelArray removeObject:tempModel];
    }
}

- (void)handleEventsForBackgroundURLSession:(NSString *)aBackgroundURLSessionIdentifier completionHandler:(void (^)())aCompletionHandler {
    [self.consumer handleEventsForBackgroundURLSession:aBackgroundURLSessionIdentifier completionHandler:aCompletionHandler];
}

#pragma mark HJMFragmentProducerDelegate

- (void)fragmentListHasRunOutWithIdentifier:(NSString *)identifier {
    if ([self.delegate respondsToSelector:@selector(downloadTaskCompleteWithDirectoryPath:identifier:)]) {
        [self.delegate downloadTaskCompleteWithDirectoryPath:nil identifier:nil];
    }
    // 队列下载完成了，将记录的delegate移除
    [self removeRecordFromCallbackArrayWithIdentifier:identifier];
    
    // 一个队列的fragments已经下载完了，试着去下载下一个队列
    M3U8SegmentInfoList *fragmentsArray = [self.producer nextFragmentList];
    if (fragmentsArray.count) {
        // producer里面有下一个队列的记录，consumer直接去下载，producer会将这个下载记入数据库
        [self.consumer startToDownloadFragmentArray:[fragmentsArray.segmentInfoList subarrayWithRange:NSMakeRange(0, MIN(self.concurrentCount, fragmentsArray.count))] arrayIdentifer:fragmentsArray.identifier];
    }
}

#pragma mark - HJMFragmentConsumerDelegate

- (M3U8SegmentInfo *)oneMoreFragmentWithIdentifier:(NSString *)identifier {
    return [self.producer oneMoreFragmentWithIdentifier:identifier];
}

- (void)oneFragmentDownloadedWithIdentifier:(NSString *)identifier {
    NSInteger leftFragmentCount = [self.producer leftFragmentCountWithIdentifier:identifier];
    if ([self.delegate respondsToSelector:@selector(downloadTaskReachProgress:identifier:)]) {
        [self.delegate downloadTaskReachProgress:(CGFloat)leftFragmentCount / [self.producer totalCountForCurrentFragmentList] identifier:identifier];
    }
}

- (void)oneFragmentDownloadedWithFragmentIdentifier:(NSString *)fragmentIdentifier identifier:(NSString *)identifier {
    // remove the record at database
    [self.producer removeFragmentOutofDatabaseWithFragmentIdentifier:fragmentIdentifier identifier:identifier];
}

- (void)downloadTaskDidCompleteWithError:(NSError *)error identifier:(NSString *)identifier {

}

#pragma mark - NSNotification



@end
