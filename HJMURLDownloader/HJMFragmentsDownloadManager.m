//
//  HJMFragmentsDownloadManager.m
//  Pods
//
//  Created by lchen on 21/06/2017.
//
//

#import "HJMFragmentCallBackModel.h"
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

- (HJMFragmentDownloadStatus)fragmentListDownloadStatusWithIdentifier:(NSString *)identifier {
    if ([self.producer isTableExistInDatabaseWithIdentifier:identifier]) {
        return HJMURLDownloadStatusCanResume;
    } else {
        if ([self.consumer directoryExistsWithIdentifer:identifier]) {
            return HJMURLDownloadStatusCompleted;
        } else {
            return HJMURLDownloadStatusNone;
        }
    }
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
        NSArray <M3U8SegmentInfo *> *fragmentsToDownload = [self.producer fragmentsWithOriginalArray:fragments limitedCount:self.concurrentCount];
        [self.consumer startToDownloadFragmentArray:fragmentsToDownload arrayIdentifer:fragments.identifier];
        if (self.delegate && [self.delegate respondsToSelector:@selector(downloadTaskBeginWithIdentifier:)]) {
            [self.delegate downloadTaskBeginWithIdentifier:fragments.identifier];
        }
    }
}

- (void)stopDownloadFragmentListWithIdentifier:(NSString *)identifier {
    if ([self.producer.currentDownloadingIdentifier isEqualToString:identifier]) {
        [self.consumer stopCurrentDownloadingFragmentList];
    } else {
        [self.producer removePendingFragmentArrayWithIdentifier:identifier];
        [self removeRecordFromCallbackArrayWithIdentifier:identifier];
        if (self.delegate && [self.delegate respondsToSelector:@selector(fragmentDidStoppedWithIdentifier:)]) {
            [self.delegate fragmentDidStoppedWithIdentifier:identifier];
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
    if (self.delegate && [self.delegate respondsToSelector:@selector(downloadTaskCompleteWithDirectoryPath:identifier:)]) {
        [self.delegate downloadTaskCompleteWithDirectoryPath:[self.consumer directoryPathWithIdentifier:identifier] identifier:identifier];
    }
    // 队列下载完成了，将记录的delegate移除
    [self removeRecordFromCallbackArrayWithIdentifier:identifier];
    
    // 一个队列的fragments已经下载完了，试着去下载下一个队列
    M3U8SegmentInfoList *fragmentsArray = [self.producer nextFragmentList];
    if (fragmentsArray.count) {
        // producer里面有下一个队列的记录，consumer直接去下载，producer会将这个下载记入数据库
        [self.consumer startToDownloadFragmentArray:[fragmentsArray.segmentInfoList subarrayWithRange:NSMakeRange(0, MIN(self.concurrentCount, fragmentsArray.count))] arrayIdentifer:fragmentsArray.identifier];
        if (self.delegate && [self.delegate respondsToSelector:@selector(downloadTaskBeginWithIdentifier:)]) {
            [self.delegate downloadTaskBeginWithIdentifier:identifier];
        }
    }
}

- (void)allFragmentListsHaveRunOut {
    NSLog(@"all fragment have run out");
}

#pragma mark - HJMFragmentConsumerDelegate

- (M3U8SegmentInfo *)oneMoreFragmentWithIdentifier:(NSString *)identifier {
    return [self.producer oneMoreFragmentWithIdentifier:identifier];
}

- (void)oneFragmentDownloadedWithFragmentIdentifier:(NSString *)fragmentIdentifier identifier:(NSString *)identifier {
    // remove the record at database
    [self.producer markFragmentAsDoneInDatabaseWithFragmentIdentifier:fragmentIdentifier identifier:identifier];
    if (self.delegate && [self.delegate respondsToSelector:@selector(downloadTaskReachProgress:identifier:)]) {
        NSInteger leftFragmentCount = [self.producer leftFragmentCountWithIdentifier:identifier];
        [self.delegate downloadTaskReachProgress: (1 - (CGFloat)leftFragmentCount / [self.producer totalCountForCurrentFragmentList]) identifier:identifier];
    }
}

- (void)downloadTaskDidCompleteWithError:(NSError *)error identifier:(NSString *)identifier {
    if (self.delegate && [self.delegate respondsToSelector:@selector(downloadTaskCompleteWithError:identifier:)]) {
        [self.delegate downloadTaskCompleteWithError:error identifier:identifier];
    }
}

- (void)didStoppedCurrentFragmentListDownloading {
    M3U8SegmentInfoList *fragmentsArray = [self.producer nextFragmentList];
    if (fragmentsArray.count) {
        // producer里面有下一个队列的记录，consumer直接去下载，producer会将这个下载记入数据库
        [self.consumer startToDownloadFragmentArray:[fragmentsArray.segmentInfoList subarrayWithRange:NSMakeRange(0, MIN(self.concurrentCount, fragmentsArray.count))] arrayIdentifer:fragmentsArray.identifier];
        if (self.delegate && [self.delegate respondsToSelector:@selector(downloadTaskBeginWithIdentifier:)]) {
            [self.delegate downloadTaskBeginWithIdentifier:fragmentsArray.identifier];
        }
    }
}

- (void)fragmentSaveToDiskFailed {
    if (self.delegate && [self.delegate respondsToSelector:@selector(fragmentSaveToDiskFailed)]) {
        [self.delegate fragmentSaveToDiskFailed];
    }
}

- (NSString *)currentDownloadingIdentifier {
    return self.producer.currentDownloadingIdentifier;
}



@end
