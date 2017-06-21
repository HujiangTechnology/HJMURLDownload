//
//  HJMFragmentsDownloadManager.m
//  Pods
//
//  Created by lchen on 21/06/2017.
//
//

#import "HJMFragmentsDownloadManager.h"
#import "M3U8Parser.h"
#import "M3U8SegmentInfoList.h"
#import "HJMFragmentDBManager.h"
#import "HJMURLDownloadManager.h"
//#import "HJMURLDownloadObject.h"

@interface HJMFragmentsDownloadManager () <HJMURLDownloadManagerDelegate, HJMURLDownloadHandlerDelegate>

@property (nonatomic, copy) void(^progressBlock)(CGFloat progress);
@property (nonatomic, copy) void(^completionBlock)(NSString *directoryPath);
@property (nonatomic, copy) void(^errorBlock)(NSError *);
@property (nonatomic, strong) HJMURLDownloadManager *downloadManager;
@property (nonatomic, assign) NSInteger fragmentCount;

/**
 重试次数，key为object的identifer，value为已经重试的次数
 */
@property (nonatomic, strong) NSMutableDictionary *retryDictionary;
/**
 下载队列标识，也用作数据库表名
 */
@property (nonatomic, copy) NSString *tableName;

@end

@implementation HJMFragmentsDownloadManager
static HJMFragmentsDownloadManager *manager;

+ (instancetype)defaultManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[HJMFragmentsDownloadManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    return [self initStandardDownloaderWithMaxConcurrentDownloads:4];
}

- (instancetype)initStandardDownloaderWithMaxConcurrentDownloads:(NSInteger)aMaxConcurrentFileDownloadsCount {
    if (self = [super init]) {
        self.retryDictionary = [NSMutableDictionary dictionary];
        self.downloadManager = [[HJMURLDownloadManager alloc] initStandardDownloaderWithMaxConcurrentDownloads:aMaxConcurrentFileDownloadsCount];
        self.downloadManager.delegate = self;
        [self.downloadManager addNotificationHandler:self];
    }
    return self;
}

- (instancetype)initBackgroundDownloaderWithIdentifier:(NSString *)identifier maxConcurrentDownloads:(NSInteger)aMaxConcurrentFileDownloadsCount OnlyWiFiAccess:(BOOL)isOnlyWiFiAccess {
    if (self = [super init]) {
        self.retryDictionary = [NSMutableDictionary dictionary];
        self.downloadManager = [[HJMURLDownloadManager alloc] initBackgroundDownloaderWithIdentifier:identifier maxConcurrentDownloads:aMaxConcurrentFileDownloadsCount OnlyWiFiAccess:isOnlyWiFiAccess];
        self.downloadManager.delegate = self;
        [self.downloadManager addNotificationHandler:self];
    }
    return self;
}

- (void)dealloc {
    [self.downloadManager removeNotificationHandler:self];
}

- (void)downloadFragmentArray:(NSArray<M3U8SegmentInfo *> *)fragments originalUrl:(NSURL *)originalUrl progressBlock:(void (^)(CGFloat))progressBlock completionBlock:(void (^)(NSString *))completionBlock errorBlock:(void (^)(NSError *))errorBlock {
    // 查询数据库中有没有这个表
    // 有这个表的话，不需要请求具体信息，直接拿到db里面的数据下载即可
    // 没有这个表，当作一个新的加到db里面
    self.progressBlock = progressBlock;
    self.completionBlock = completionBlock;
    self.errorBlock = errorBlock;
    
    HJMFragmentDBManager *manager = [HJMFragmentDBManager sharedManager];
    self.tableName = originalUrl.lastPathComponent;
    if ([manager isTableExist:self.tableName] && [manager rowCountInTable:self.tableName]) {
        M3U8SegmentInfo *fragmentModel = [manager oneMoreFragmentModelInTable:self.tableName];
        [self.downloadManager addURLDownloadItem:nil];
        
    } else {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"localM3u8" ofType:@"txt"];
        NSString *m3u8String = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
        M3U8SegmentInfoList *m3u8InfoList = [M3U8Parser m3u8SegmentInfoListFromPlanString:m3u8String];
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
