//
//  HJMFragmentConsumer.m
//  Pods
//
//  Created by lchen on 21/06/2017.
//
//

#import "HJMFragmentConsumer.h"
#import "HJMFragmentDBManager.h"
#import "HJMURLDownloadManager.h"
#import "M3U8Parser.h"
#import "M3U8SegmentInfoList.h"

@interface HJMFragmentConsumer ()<HJMURLDownloadManagerDelegate, HJMURLDownloadHandlerDelegate>

@property (nonatomic, assign) NSInteger limitedCount;
@property (nonatomic, strong) HJMURLDownloadManager *downloadManager;
@property (nonatomic, copy) NSString *currentDownloadIdentifier;

@end

@implementation HJMFragmentConsumer

- (instancetype)initWithLimitedConcurrentCount:(NSInteger)count {
    if (self = [super init]) {
        self.limitedCount = count;
    }
    return self;
}

- (instancetype)init {
    return [self initWithLimitedConcurrentCount:4];
//    self.downloadManager = [[HJMURLDownloadManager alloc] initBackgroundDownloaderWithIdentifier:identifier maxConcurrentDownloads:aMaxConcurrentFileDownloadsCount OnlyWiFiAccess:isOnlyWiFiAccess];
    self.downloadManager.delegate = self;
    [self.downloadManager addNotificationHandler:self];
}

- (void)dealloc {
    [self.downloadManager removeNotificationHandler:self];
}

- (void)startToDownloadFragmentArray:(NSArray <M3U8SegmentInfo *> *)fragmentArray arrayIdentifer:(NSString *)identifier {
    
    NSArray <M3U8SegmentInfo *> *fragmentsFromDatabase = [manager fragmentsModelWithCount:self.limitedCount tableName:identifier];
    
    if (fragmentsFromDatabase.count) {
        
    } else {
        // notify delegate the array has downloaded
        [self.delegate ]
    }
    
    // 有这个表的话，不需要请求具体信息，直接拿到db里面的数据下载即可
    // 没有这个表，当作一个新的加到db里面
    
    self.tableName = originalUrl.lastPathComponent;
    if ([manager isTableExist:self.tableName] && [manager rowCountInTable:self.tableName]) {
        M3U8SegmentInfo *fragmentModel = [manager oneMoreFragmentModelInTable:self.tableName];
        [self.downloadManager addURLDownloadItem:nil];
        
    } else {
        [manager createTableWithName:self.tableName];
        [manager insertFragmentModelArray:m3u8InfoList.segmentInfoList toTable:self.tableName];
        M3U8SegmentInfo *fragmentModel = [manager oneMoreFragmentModelInTable:self.tableName];
        [self.downloadManager addURLDownloadItem:nil];
    }
}

#pragma mark - HJMURLDownloadHandlerDelegate

- (void)downloadURLDownloadItem:(id<HJMURLDownloadExItem>)item didFailWithError:(NSError *)error {
    NSNumber *retryTimes = self.retryDictionary[item.identifier];
    if ([retryTimes intValue] < 3) {
        [self.downloadManager addURLDownloadItem:item];
        self.retryDictionary[item.identifier] = @([retryTimes intValue] + 1);
    } else {
        // 停止所有下载
        [self.downloadManager cancelAllDownloads];
        self.progressBlock = nil;
        self.completionBlock = nil;
        self.errorBlock = nil;
        self.retryDictionary = nil;
        // 错误抛出去
        if (self.errorBlock) {
            self.errorBlock(error);
        }
    }
}

#pragma mark HJMURLDownloadManagerDelegate

- (BOOL)downloadTaskShouldHaveEnoughFreeSpace:(long long)expectedData {
    if ([self.delegate respondsToSelector:@selector(downloadTaskShouldHaveEnoughFreeSpace:)]) {
        return [self.delegate downloadTaskShouldHaveEnoughFreeSpace:expectedData];
    } else {
        return YES;
    }
}

- (void)downloadTaskDidFinishWithDownloadItem:(id<HJMURLDownloadExItem>)downloadObject completionBlock:(void (^)(void))block {
    // 下载后文件位置在[downloadObject fullPath]中
    if ([[HJMFragmentDBManager sharedManager] rowCountInTable:self.tableName] == 0) {
        if (self.completionBlock) {
            self.completionBlock([downloadObject fullPath]);
        }
        [[HJMFragmentDBManager sharedManager] dropTable:self.tableName];
    } else {
        if (self.progressBlock) {
            NSInteger leftFragmentCount = [[HJMFragmentDBManager sharedManager] rowCountInTable:self.tableName];
            self.progressBlock(self.fragmentCount - leftFragmentCount / self.fragmentCount);
        }
        [[HJMFragmentDBManager sharedManager] removeFragmentModel:downloadObject inTable:self.tableName];
    }
}

@end
