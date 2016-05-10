//
//  HJMURLDownloadManager.m
//  HJMURLDownloader
//
//  Created by Dong Han on 12/23/14.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import "HJMURLDownloadManager.h"
#import "HJMURLDownloadNotificationHandler.h"
#import "HJMDownloadCoreDataManager.h"
#import "HJMCDDownloadItem.h"
#import "HJMCDDownloadItem+HJMDownloadAdditions.h"

static NSString *const HJMURLDownloadErrorDomain = @"com.hjm.hjmurldownload";
static NSString *const HJMURLDownloadHTTPStatusKey = @"HJMURLDownloadHTTPStatusKey";

static NSString *const kURLDownloadDownloadObject = @"HJMURLDownloadObject";

static const NSTimeInterval kDefaultRequestTimeout = 30;

NSString *const kHJMURLDownloaderOnlyWiFiAccessNotification = @"kHJMURLDownloaderOnlyWifiAccessNotification";
NSString *const kHJMURLDownloaderDownloadTaskDidFinishDownloadingNotification = @"HJMURLDownloaderDownloadTaskDidFinishDownloadingNotification";

@interface HJMURLDownloadManager () <NSURLSessionDelegate,
NSURLSessionTaskDelegate,
NSURLSessionDataDelegate,
NSURLSessionDownloadDelegate>

@property (nonatomic, copy) NSDictionary *HTTPAdditionalHeaders;

@property(nonatomic, strong) NSURLSession *URLSession;
@property(nonatomic, strong) HJMURLDownloadNotificationHandler *URLDownloadHandler;
@property(nonatomic, strong) HJMURLDownloadBackgroundSessionCompletionHandlerBlock backgroundSessionCompletionHandlerBlock;
@property (nonatomic, readwrite, strong) HJMDownloadCoreDataManager *coreDataManager;

@property (nonatomic, strong) NSMutableDictionary *activeDownloadsDictionary;
@property (nonatomic, strong) NSDictionary *tmpActiveDownloadsDictionary;
@property (nonatomic, strong) NSMutableArray *waitingDownloadsArray;
@property (nonatomic) BOOL isShouldAutomaticlyStartNextWaitingDownloadItem;

@property (nonatomic, assign) NSInteger maxConcurrentFileDownloadsCount;
@property (nonatomic, assign) NSInteger currentFileDownloadsCount;
@property (nonatomic, copy) NSString *backgroundIdentifier;
@property (nonatomic) BOOL backgroundMode;
@property (nonatomic) BOOL isOnlyWiFiAccess;
@property (nonatomic, strong) NSDate *lastPacketTimestamp;
@property (nonatomic) float previousSpeed;

@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;

@property (nonatomic) dispatch_queue_t concurrentQueue;

#if TARGET_OS_IPHONE
@property (nonatomic, strong) NSMutableDictionary *completionHandlerDictionary;
#endif

@end

@implementation HJMURLDownloadManager

@synthesize currentFileDownloadsCount=_currentFileDownloadsCount;

- (void)dealloc {
    [self.URLSession finishTasksAndInvalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kHJMURLDownloaderOnlyWiFiAccessNotification
                                                  object:nil];
}

+ (instancetype)defaultManager {
    static dispatch_once_t onceToken;
    static id sharedManager = nil;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (instancetype)init {
    return [self initBackgroundDownloaderWithIdentifier:@"" maxConcurrentDownloads:1 OnlyWiFiAccess:YES];
}

- (instancetype)initWithMaxConcurrentDownloads:(NSInteger)aMaxConcurrentFileDownloadsCount isSupportBackgroundMode:(BOOL)isBackgroundMode backgroundIdentifier:(NSString *)identifier HTTPAdditionalHeaders:(NSDictionary *)headers OnlyWiFiAccess:(BOOL)isOnlyWiFiAccess {
    self = [super init];
    if (self) {
        if (aMaxConcurrentFileDownloadsCount > 0) {
            self.maxConcurrentFileDownloadsCount = aMaxConcurrentFileDownloadsCount;
        } else {
            self.maxConcurrentFileDownloadsCount = -1;
        }
        [self setupRecordData];
        [self setupNotification];
        _backgroundMode = isBackgroundMode;
        _isShouldAutomaticlyStartNextWaitingDownloadItem = YES;
        _recoverDownloadAfterReopenAppEnable= YES;
        _HTTPAdditionalHeaders = headers;
        _isOnlyWiFiAccess = isOnlyWiFiAccess;
        _backgroundIdentifier = identifier;
        if (_backgroundMode) {
            [self setupBackgroundURLSession:[self createABackgroundConfigObject]];
        } else {
            [self setupStandardURLSession];
        }
    }
    return self;
}

- (instancetype)initWithMaxConcurrentDownloads:(NSInteger)aMaxConcurrentFileDownloadsCount
                       isSupportBackgroundMode:(BOOL)isBackgroundMode
                                OnlyWiFiAccess:(BOOL)isOnlyWiFiAccess {
    return [self initWithMaxConcurrentDownloads:aMaxConcurrentFileDownloadsCount isSupportBackgroundMode:isBackgroundMode backgroundIdentifier:nil HTTPAdditionalHeaders:nil OnlyWiFiAccess:isOnlyWiFiAccess];
}

- (instancetype)initWithMaxConcurrentDownloads:(NSInteger)aMaxConcurrentFileDownloadsCount {
    return [self initWithMaxConcurrentDownloads:aMaxConcurrentFileDownloadsCount
                        isSupportBackgroundMode:NO];
}

- (instancetype)initWithMaxConcurrentDownloads:(NSInteger)aMaxConcurrentFileDownloadsCount
                       isSupportBackgroundMode:(BOOL)isBackgroundMode {
    
    return [self initWithMaxConcurrentDownloads:aMaxConcurrentFileDownloadsCount isSupportBackgroundMode:isBackgroundMode backgroundIdentifier:nil HTTPAdditionalHeaders:nil OnlyWiFiAccess:YES];
}


- (instancetype)initStandardDownloaderWithMaxConcurrentDownloads:(NSInteger)aMaxConcurrentFileDownloadsCount {
    return [self initWithMaxConcurrentDownloads:aMaxConcurrentFileDownloadsCount isSupportBackgroundMode:NO backgroundIdentifier:nil HTTPAdditionalHeaders:nil OnlyWiFiAccess:NO];
}

- (instancetype)initBackgroundDownloaderWithIdentifier:(NSString *)identifier maxConcurrentDownloads:(NSInteger)aMaxConcurrentFileDownloadsCount OnlyWiFiAccess:(BOOL)isOnlyWiFiAccess {
    return [self initWithMaxConcurrentDownloads:aMaxConcurrentFileDownloadsCount isSupportBackgroundMode:YES backgroundIdentifier:identifier HTTPAdditionalHeaders:nil OnlyWiFiAccess:isOnlyWiFiAccess];
}

- (HJMDownloadCoreDataManager *)coreDataManager {
    if (!self.backgroundMode) {
        return nil;
    }
    if (!_coreDataManager) {
        _coreDataManager = [[HJMDownloadCoreDataManager alloc] init];
        _coreDataManager.userID = self.userID;
    }
    return _coreDataManager;
}

- (void)setUserID:(NSInteger)userID {
    if (_userID != userID) {
        _userID = userID;
        self.coreDataManager.userID = userID;
    }
}

- (dispatch_queue_t)concurrentQueue {
    if (!_concurrentQueue) {
        _concurrentQueue = dispatch_queue_create([@"com.hujiang.hjmurldownload" UTF8String], DISPATCH_QUEUE_CONCURRENT);
    }
    return _concurrentQueue;
}

- (NSInteger)currentFileDownloadsCount {
    __block NSUInteger currentCount;
    dispatch_sync(self.concurrentQueue, ^{
        currentCount = _currentFileDownloadsCount;
    });
    return currentCount;
}

- (void)setCurrentFileDownloadsCount:(NSInteger)aCurrentFileDownloadsCount {
    dispatch_barrier_async(self.concurrentQueue, ^{
        _currentFileDownloadsCount = MIN(self.maxConcurrentFileDownloadsCount, MAX(aCurrentFileDownloadsCount, 0));
    });
}

- (void)setupNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(changeWiFiAccess:)
                                                 name:kHJMURLDownloaderOnlyWiFiAccessNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillTerminate:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
}

- (NSURLSessionConfiguration *)createABackgroundConfigObject {
    NSString *aBackgroundDownloadSessionIdentifier = self.backgroundIdentifier.length > 0 ? self.backgroundIdentifier : [NSString stringWithFormat:@"%@.HJMURLDownload", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"]];
    NSURLSessionConfiguration *aBackgroundConfigObject;
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
        aBackgroundConfigObject = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:aBackgroundDownloadSessionIdentifier];
    } else {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        aBackgroundConfigObject = [NSURLSessionConfiguration backgroundSessionConfiguration:aBackgroundDownloadSessionIdentifier];
#pragma GCC diagnostic pop
    }
    
    if (self.HTTPAdditionalHeaders.count > 0) {
        aBackgroundConfigObject.HTTPAdditionalHeaders = self.HTTPAdditionalHeaders;
    }
    // 默认配置
    aBackgroundConfigObject.allowsCellularAccess = !self.isOnlyWiFiAccess;
    return aBackgroundConfigObject;
}

- (NSURLSessionConfiguration *)createAStandardConfigObject {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.allowsCellularAccess = !self.isOnlyWiFiAccess;
    return configuration;
}

- (void)changeWiFiAccess:(NSNotification *)notif {
    BOOL isOnlyWiFiAccess = [[notif object] boolValue];
    if (self.isOnlyWiFiAccess != isOnlyWiFiAccess) {
        self.isOnlyWiFiAccess = isOnlyWiFiAccess;
        
        self.tmpActiveDownloadsDictionary = [self.activeDownloadsDictionary copy];
        self.isShouldAutomaticlyStartNextWaitingDownloadItem = NO;
        
        [[self.activeDownloadsDictionary allKeys] enumerateObjectsUsingBlock:^(NSNumber *indexNumber, NSUInteger idx, BOOL *stop) {
            HJMURLDownloadObject *downloadObject = self.activeDownloadsDictionary[indexNumber];
            [self cancelAURLDownloadItem:downloadObject];
        }];
        
        self.currentFileDownloadsCount = 0;
        
        [self.URLSession invalidateAndCancel];
    }
}

- (void)stopBackgroundTask {
    if (self.backgroundTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
        self.backgroundTask = UIBackgroundTaskInvalid;
    }
}

- (void)didEnterBackground:(NSNotification *)notif {
    if (self.maxConcurrentFileDownloadsCount > 0) {
        self.backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:NSStringFromClass([self class])
                                                                           expirationHandler:^{
                                                                               [self cancelAllDownloads];
                                                                               [self stopBackgroundTask];
                                                                           }];
    }
}

- (void)applicationWillTerminate:(NSNotification *)notif {
    if (self.maxConcurrentFileDownloadsCount > 0) {
        [self cancelAllDownloads];
    }
}

- (HJMURLDownloadNotificationHandler *)URLDownloadHandler {
    if (!_URLDownloadHandler) {
        _URLDownloadHandler = [[HJMURLDownloadNotificationHandler alloc] init];
    }
    return _URLDownloadHandler;
}

- (void)addNotificationHandler:(id<HJMURLDownloadHandlerDelegate>)delegate {
    [self.URLDownloadHandler addDownloaderDelegate:delegate];
}

- (void)removeNotificationHandler:(id<HJMURLDownloadHandlerDelegate>)delegate {
    [self.URLDownloadHandler removeDownloaderDelegate:delegate];
}

- (void)setupRecordData {
    self.currentFileDownloadsCount = 0;
    self.backgroundTask = UIBackgroundTaskInvalid;
}
- (NSMutableDictionary *)activeDownloadsDictionary {
    if (!_activeDownloadsDictionary) {
        _activeDownloadsDictionary = [NSMutableDictionary dictionary];
    }
    return _activeDownloadsDictionary;
}

- (NSMutableArray *)waitingDownloadsArray {
    if (!_waitingDownloadsArray) {
        _waitingDownloadsArray = [NSMutableArray array];
    }
    return _waitingDownloadsArray;
}

- (HJMURLDownloadObject *)createAURLDownloadObjectWithDownloadTask:(NSURLSessionDownloadTask *)aDownloadTask {
    
    HJMCDDownloadItem *item = [HJMCDDownloadItem downloadItemForIdentifier:aDownloadTask.taskDescription
                                                                    userID:self.userID];
    
    HJMURLDownloadObject *downloadObject = [[HJMURLDownloadObject alloc] initWithCDDownloadItem:item];
    
    if (aDownloadTask) {
        downloadObject.task = aDownloadTask;
    }
    return downloadObject;
}

- (void)handleTasksWithCompletionHandler:(NSArray *)aDownloadTasksArray {
    if (aDownloadTasksArray.count > 0) {
        for (NSURLSessionDownloadTask *aDownloadTask in aDownloadTasksArray) {
            HJMURLDownloadObject *downloadObject = [self createAURLDownloadObjectWithDownloadTask:aDownloadTask];
            downloadObject.task = aDownloadTask;
            downloadObject.identifier = aDownloadTask.taskDescription;
            downloadObject.isLastDownload = YES;
            [self.URLDownloadHandler.delegates enumerateObjectsUsingBlock:^(id<HJMURLDownloadHandlerDelegate> delegate, BOOL *stop) {
                
                if ([delegate respondsToSelector:@selector(downloadURLDownloadItemWillRecover:)]) {
                    [delegate downloadURLDownloadItemWillRecover:downloadObject];
                }
            }];
           
            //注意 DownloadTast.state为Completed时有两种情况，1. 下载完成 2. 下载被取消，无法在这个回调里准确的判断当前下载状态
            if (aDownloadTask.state == NSURLSessionTaskStateCompleted || aDownloadTask.state == NSURLSessionTaskStateRunning) {
                self.activeDownloadsDictionary[@(aDownloadTask.taskIdentifier)] = downloadObject;
                self.currentFileDownloadsCount++;
            }
        }
    }
}

- (void)setupStandardURLSession {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    if (self.HTTPAdditionalHeaders.count > 0) {
        configuration.HTTPAdditionalHeaders = self.HTTPAdditionalHeaders;
    }
    self.URLSession = [NSURLSession sessionWithConfiguration:configuration
                                                    delegate:self
                                               delegateQueue:[NSOperationQueue mainQueue]];
   
    //TODO: 注意未测试，待测试
    [self.URLSession getTasksWithCompletionHandler:^(NSArray *aDataTasksArray, NSArray *anUploadTasksArray, NSArray *aDownloadTasksArray) {
        if (self.recoverDownloadAfterReopenAppEnable) {
            [self handleTasksWithCompletionHandler:aDownloadTasksArray];
        } else {
            for (NSURLSessionDownloadTask *aDownloadTask in aDownloadTasksArray) {
                [aDownloadTask suspend];
            }
        }
    }];
}

- (void)setupBackgroundURLSession:(NSURLSessionConfiguration *)aBackgroundConfigObject {
    
    self.URLSession = [NSURLSession sessionWithConfiguration:aBackgroundConfigObject
                                                    delegate:self
                                               delegateQueue:[NSOperationQueue mainQueue]];
     if (self.recoverDownloadAfterReopenAppEnable) {
        [self.URLSession getTasksWithCompletionHandler:^(NSArray *aDataTasksArray, NSArray *anUploadTasksArray, NSArray *aDownloadTasksArray) {
            if (self.recoverDownloadAfterReopenAppEnable) {
                [self handleTasksWithCompletionHandler:aDownloadTasksArray];
            } else {
                for (NSURLSessionDownloadTask *aDownloadTask in aDownloadTasksArray) {
                    [aDownloadTask suspend];
                }
            }
        }];
     } 
}

#pragma mark - NSURLSessionDataDelegate

- (void)startAURLDownloadObject:(HJMURLDownloadObject *)downloadObject fromCoreData:(BOOL)isFromCoreData {
    //0. 处理下载对象已经在下载中的情况
    //0.1 如果isFromCoreData为Yes，表明为内部唤起下载
    //0.2 如何isFromCoreData为No, 表明为外部创建下载
    __block BOOL isADownloadAlreadyExists;
    [[self.activeDownloadsDictionary copy] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, HJMURLDownloadObject   * _Nonnull currentDownloadObject, BOOL * _Nonnull stop) {
        if ([currentDownloadObject.identifier isEqualToString:downloadObject.identifier]) {
            isADownloadAlreadyExists = YES;
            if (!isFromCoreData) {
                downloadObject.task = currentDownloadObject.task;
                self.activeDownloadsDictionary[key] = downloadObject;
            }
            *stop = YES;
        }
    }];
   
    //内部唤起的下载已经存在下载队伍中则直接返回
    if (isFromCoreData && isADownloadAlreadyExists) {
        return;
    }
    
    //1. 数据库操作，插入或者读取数据库
    if (downloadObject.task) {
        downloadObject.status = HJMURLDownloadStatusDownloading;
    } else {
        downloadObject.status = HJMURLDownloadStatusWaiting;
    }
    if ([self.coreDataManager downloadItemExistsForDownloadObject:downloadObject]) {
        HJMCDDownloadItem *item = [HJMCDDownloadItem downloadItemForIdentifier:downloadObject.identifier
                                                                        userID:self.userID];
        NSData *currentData = [self __isValidResumeData:item.resumeData];
        if (currentData) {
            downloadObject.resumeData = currentData;
        }
        [self.coreDataManager updateDownloadItemWithDownloadObject:downloadObject andResumeData:downloadObject.resumeData ?: nil];
    } else {
        //新增下载对象，插入后立即保存，处理程序在保存前意外退出未保存丢失数据的情况
        [self.coreDataManager insertNewDownloadItemWithDownloadObject:downloadObject];
        [HJMDownloadCoreDataManager saveContext];
        NSString *fullDirectory = [[downloadObject fullPath] stringByDeletingLastPathComponent];
        BOOL isDir = YES;
        NSFileManager *fm = [NSFileManager defaultManager];
        if (![fm fileExistsAtPath:fullDirectory isDirectory:&isDir] && isDir) {
            
            [fm createDirectoryAtPath:fullDirectory
          withIntermediateDirectories:YES
                           attributes:nil
                                error:nil];
        }
    }
    
    if (downloadObject.task) {
        return;
    }
    
    //2. 派发waitingToDownload消息
    [self.URLDownloadHandler.delegates enumerateObjectsUsingBlock:^(id<HJMURLDownloadHandlerDelegate> delegate, BOOL *stop) {
        if ([delegate respondsToSelector:@selector(downloadURLDownloadItemWaitingToDownload:)]) {
            [delegate downloadURLDownloadItemWaitingToDownload:downloadObject];
        }
    }];
    
    //3. 满足下载条件添加task或加入等待队列
    if ([self isShouldAddMoreDownloadItem]) {
        
        NSError *error;
        if ([self.delegate respondsToSelector:@selector(downloadTaskShouldHaveEnoughFreeSpace:)]) {
            // 如果下载没有足够的剩余空间, 则返回报错处理
            if (![self.delegate downloadTaskShouldHaveEnoughFreeSpace:-1]) {
                
                error = [NSError errorWithDomain:HJMURLDownloadErrorDomain
                                            code:HJMURLDownloadErrorNotEnoughFreeDiskSpace
                                        userInfo:@{ NSLocalizedDescriptionKey:@"Not enough free disk space" }];
            }
            if (error) {
                
                [self handleDownloadWithError:error
                            URLDownloadObject:downloadObject];
                return;
            }
        }
        
        NSURLSessionDownloadTask *aDownloadTask = nil;
        
        if (downloadObject.resumeData) {
            @try {
                aDownloadTask = [self.URLSession downloadTaskWithResumeData:downloadObject.resumeData];
            }
            @catch (NSException *exception) {
                if ([NSInvalidArgumentException isEqualToString:exception.name]) {
                    aDownloadTask = [self.URLSession downloadTaskWithURL:downloadObject.remoteURL];
                } else {
                    @throw exception; // only swallow NSInvalidArgumentException for resumeData
                }
            }
        } else {
            
            NSMutableURLRequest *downloadRequest = [NSMutableURLRequest requestWithURL:downloadObject.remoteURL
                                                                           cachePolicy:0 ? NSURLRequestUseProtocolCachePolicy : NSURLRequestReloadIgnoringLocalCacheData
                                                                       timeoutInterval:kDefaultRequestTimeout];
            if (![NSURLConnection canHandleRequest:downloadRequest]) {
                NSError *error = [NSError errorWithDomain:HJMURLDownloadErrorDomain
                                                     code:HJMURLDownloadErrorInvalidURL
                                                 userInfo:@{ NSLocalizedDescriptionKey:
                                                                 [NSString stringWithFormat:@"Invalid URL provided: %@", downloadRequest.URL]}];
                
                [self handleDownloadWithError:error
                            URLDownloadObject:downloadObject];
                return;
            }
            aDownloadTask = [self.URLSession downloadTaskWithRequest:downloadRequest];
        }
        aDownloadTask.taskDescription = downloadObject.identifier;
        downloadObject.task = aDownloadTask;
        downloadObject.startDate = [NSDate date];
        
        [self.coreDataManager updateDownloadItemWithDownloadObject:downloadObject andResumeData:nil];
        
        self.activeDownloadsDictionary[@(aDownloadTask.taskIdentifier)] = downloadObject;
        
        [aDownloadTask resume];
        self.currentFileDownloadsCount++;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.URLDownloadHandler.delegates enumerateObjectsUsingBlock:^(id<HJMURLDownloadHandlerDelegate> delegate, BOOL *stop) {
                if ([delegate respondsToSelector:@selector(downloadURLDownloadItemWillDownload:)]) {
                    [delegate downloadURLDownloadItemWillDownload:downloadObject];
                }
            }];
        });
    } else {
        [self.waitingDownloadsArray addObject:downloadObject];
    }
}


- (void)startAURLDownloadObject:(HJMURLDownloadObject *)downloadObject {
    [self startAURLDownloadObject:downloadObject fromCoreData:NO];
}

#pragma mark Public Method

// 基础操作
- (void)addDownloadWithURL:(NSURL *)url
                  progress:(HJMURLDownloadProgressBlock)progressBlock
                  complete:(HJMURLDownloadCompletionBlock)completeBlock {
    
    if (!url) {
        if (completeBlock) {
            completeBlock(NO, nil);
        }
        return;
    }
    
    HJMURLDownloadObject *downloadObject = [[HJMURLDownloadObject alloc] init];
    downloadObject.remoteURL = url;
    downloadObject.progressBlock = progressBlock;
    downloadObject.completionBlock = completeBlock;
    downloadObject.title = [url.absoluteString lastPathComponent];
    downloadObject.identifier = url.absoluteString;

    [self startAURLDownloadObject:downloadObject];
}

- (void)addURLDownloadItem:(id<HJMURLDownloadExItem>)downloadItem {
    HJMURLDownloadObject *downloadObject = [[HJMURLDownloadObject alloc] initWithURLDownloadExItem:downloadItem];
    [self startAURLDownloadObject:downloadObject];
}

- (id<HJMURLDownloadExItem>)getAURLDownloadWithIdentifier:(NSString *)identifier {
    HJMCDDownloadItem *hjmcdDownloadItem = [HJMCDDownloadItem downloadItemForIdentifier:identifier userID:self.userID];
    return [[HJMURLDownloadObject alloc] initWithCDDownloadItem:hjmcdDownloadItem];
}

- (void)cancelAllDownloads {
    [self.waitingDownloadsArray enumerateObjectsUsingBlock:^(HJMURLDownloadObject * _Nonnull downloadObject, NSUInteger idx, BOOL * _Nonnull stop) {
        downloadObject.status = HJMURLDownloadStatusPaused;
        [self.coreDataManager updateDownloadItemWithDownloadObject:downloadObject andResumeData:nil];
    }];
    [self.waitingDownloadsArray removeAllObjects];
    self.isShouldAutomaticlyStartNextWaitingDownloadItem = NO;
    [self.activeDownloadsDictionary enumerateKeysAndObjectsUsingBlock:^(id key, HJMURLDownloadObject *downloadObj, BOOL *stop) {
        [self cancelAURLDownloadItem:downloadObj];
    }];
    [self.activeDownloadsDictionary removeAllObjects];
    self.isShouldAutomaticlyStartNextWaitingDownloadItem = YES;
    [HJMDownloadCoreDataManager saveContext];
}

- (void)cancelAURLDownloadWithDownloadID:(NSUInteger)aDownloadID {
    HJMURLDownloadObject *aDownloadObject = self.activeDownloadsDictionary[@(aDownloadID)];
    aDownloadObject.status = HJMURLDownloadStatusPaused;
    
    NSURLSessionDownloadTask *aDownloadTask = aDownloadObject.task;
    if (aDownloadTask) {
        if (aDownloadObject.isIgnoreResumeDataAfterCancel) {
            [aDownloadTask cancel];
            
            [self.coreDataManager updateDownloadItemWithDownloadObject:aDownloadObject andResumeData:nil];
        } else {
            [aDownloadTask cancelByProducingResumeData:^(NSData *resumeData) {
                
                [self.coreDataManager updateDownloadItemWithDownloadObject:aDownloadObject andResumeData:resumeData];
            }];
        }
    } else {
        [self.coreDataManager updateDownloadItemWithDownloadObject:aDownloadObject andResumeData:nil];
    }
}

- (void)removeWaitingDownloadsArrayWithIdentifier:(NSString *)identifier {
    __block NSInteger aFoundIndex = -1;
    [self.waitingDownloadsArray enumerateObjectsUsingBlock:^(HJMURLDownloadObject *downloadObject, NSUInteger idx, BOOL *stop) {
        if ([downloadObject.identifier isEqualToString:identifier]) {
            aFoundIndex = idx;
            downloadObject.status = HJMURLDownloadStatusPaused;
            
            [self.coreDataManager updateDownloadItemWithDownloadObject:downloadObject andResumeData:nil];
            *stop = YES;
        }
    }];
    
    if (aFoundIndex > -1) {
        [self.waitingDownloadsArray removeObjectAtIndex:aFoundIndex];
    }
}

- (void)cancelAURLDownloadWithIdentifier:(NSString *)identifier {
//    if (![self hasActiveDownloads])
//        return;
    
    __block id<HJMURLDownloadExItem> downloadItem;
    [[self.activeDownloadsDictionary allKeys] enumerateObjectsUsingBlock:^(NSNumber *key, NSUInteger idx, BOOL *stop) {
        id<HJMURLDownloadExItem> tmpDownloadItem = self.activeDownloadsDictionary[key];
        if ([tmpDownloadItem.identifier isEqualToString:identifier]) {
            downloadItem = tmpDownloadItem;
            *stop = YES;
        }
    }];
    
    if (!downloadItem) {
        [self.waitingDownloadsArray enumerateObjectsUsingBlock:^(id<HJMURLDownloadExItem> tmpdownloadItem, NSUInteger idx, BOOL *stop) {
            if ([tmpdownloadItem.identifier isEqualToString:identifier]) {
                downloadItem = tmpdownloadItem;
                *stop = YES;
            }
        }];
    }
    
    if (downloadItem) {
        [self cancelAURLDownloadItem:downloadItem];
    } else {
        HJMCDDownloadItem *hjmcdDownloadItem = [HJMCDDownloadItem downloadItemForIdentifier:identifier userID:self.userID];
        [self.coreDataManager updateDownloadItem:hjmcdDownloadItem withBlock:^(HJMCDDownloadItem *aDownloadItem) {
            aDownloadItem.state = @(HJMURLDownloadStatusPaused);
        }];
    }
}

- (void)cancelAURLDownloadItem:(id<HJMURLDownloadExItem>)downloadItem {
    
    //1. 取消下载 && 2. 更新数据库
    NSInteger aDownloadID = [self downloadIDForDownloadToken:downloadItem.identifier];
    
    if (aDownloadID > -1) {
        [self cancelAURLDownloadWithDownloadID:aDownloadID];
    } else {
        [self removeWaitingDownloadsArrayWithIdentifier:downloadItem.identifier];
    }
    //3. 派发通知
    [self.URLDownloadHandler.delegates enumerateObjectsUsingBlock:^(id<HJMURLDownloadHandlerDelegate> delegate, BOOL *stop) {
        
        if ([delegate respondsToSelector:@selector(URLDownloadItemDidCanceled:)]) {
            [delegate URLDownloadItemDidCanceled:downloadItem];
        }
    }];
}

- (void)deleteAURLDownloadItemIdentifier:(NSString *)identifier {
    
    //1. 取消下载
    NSInteger aDownloadID = [self downloadIDForDownloadToken:identifier];
    __block id<HJMURLDownloadExItem> downloadItem;
    if (aDownloadID > -1) {
        HJMURLDownloadObject *aDownloadObject = self.activeDownloadsDictionary[@(aDownloadID)];
        downloadItem = aDownloadObject;
        [aDownloadObject.task cancel];
    } else {
        __block NSInteger aFoundIndex = -1;
        [self.waitingDownloadsArray enumerateObjectsUsingBlock:^(HJMURLDownloadObject *downloadObj, NSUInteger idx, BOOL *stop) {
            
            if ([downloadObj.identifier isEqualToString:identifier]) {
                aFoundIndex = idx;
                downloadItem = downloadObj;
                *stop = YES;
            }
        }];
        if (aFoundIndex > -1) {
            [self.waitingDownloadsArray removeObjectAtIndex:(NSUInteger)aFoundIndex];
        }
    }
    //2. 清除数据库记录
    [self.coreDataManager deleteDownloadItemWithIdentifier:identifier];
    
    //3. 派发通知
    [self.URLDownloadHandler.delegates enumerateObjectsUsingBlock:^(id<HJMURLDownloadHandlerDelegate> delegate, BOOL *stop) {
        if ([delegate respondsToSelector:@selector(URLDownloadItemDidDeleted:)]) {
            [delegate URLDownloadItemDidDeleted:downloadItem];
        }
    }];
}

- (void)deleteAllDownloads {
    [self.waitingDownloadsArray enumerateObjectsUsingBlock:^(HJMURLDownloadObject *downloadObj, NSUInteger idx, BOOL *stop) {
        [self deleteAURLDownloadItemIdentifier:downloadObj.identifier];
    }];
    [self.waitingDownloadsArray removeAllObjects];
    [self.activeDownloadsDictionary enumerateKeysAndObjectsUsingBlock:^(id key, HJMURLDownloadObject *downloadObj, BOOL *stop) {
        
        [self deleteAURLDownloadItemIdentifier:downloadObj.identifier];
    }];
    [self.activeDownloadsDictionary removeAllObjects];
}

#pragma mark - NSURLSession
#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)aLocation {
    
    [self callCompletionHandlerForSession:session.configuration.identifier];
   
    //hack: 解决第二次启动后恢复上次下载任务，但实际上次下载任务未成功但未报Error的问题
    HJMURLDownloadObject *downloadObject = self.activeDownloadsDictionary[@(downloadTask.taskIdentifier)];
    if (![[NSFileManager defaultManager] fileExistsAtPath:aLocation.path] && downloadObject.isLastDownload) {
        return;
    }
    
    NSError *error;
    void(^NotificationBlock)(void) = ^(void) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.URLDownloadHandler.delegates enumerateObjectsUsingBlock:^(id<HJMURLDownloadHandlerDelegate> delegate, BOOL *stop) {
                if ([delegate respondsToSelector:@selector(downloadURLDownloadItemDidFinished:)]) {
                    [delegate downloadURLDownloadItemDidFinished:downloadObject];
                }
            }];
            [[NSNotificationCenter defaultCenter] postNotificationName:kHJMURLDownloaderDownloadTaskDidFinishDownloadingNotification
                                                                object:downloadTask];
        });
    };
    
    NSURL *targetURL;
    if (downloadObject.relativePath.length > 0) {
        if (downloadObject.searchPathDirectory != kNilOptions) {
            targetURL = [NSURL fileURLWithPath:[[NSSearchPathForDirectoriesInDomains(downloadObject.searchPathDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:downloadObject.relativePath]];
        } else {
            targetURL = [NSURL fileURLWithPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:downloadObject.relativePath]];
        }
        [[NSFileManager defaultManager] removeItemAtURL:targetURL error:nil] ;
    } else {
        //Notice: 保存路径有两种情况
        //1.当downloadObject.identifier存在且为下载地址时，取lastPathComponent
        //2.单个下载时采用URLSession创建的临时文件名保存在Cache路径下(理论上应该不存在此情况)
        if (downloadObject.identifier.length > 0 && [downloadObject.identifier hasPrefix:@"http"]) {
            targetURL = [NSURL fileURLWithPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:downloadObject.identifier.lastPathComponent]];
        } else {
            targetURL = [NSURL fileURLWithPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:aLocation.lastPathComponent]];
        }
        
    }
    
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *locationString = aLocation.path;
    //硬编码处理URL变化的问题
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"/*.+Library/Caches" options:NSRegularExpressionCaseInsensitive error:&error];
    if (!error) {
        locationString = [regex stringByReplacingMatchesInString:locationString options:0 range:NSMakeRange(0, [locationString length]) withTemplate:cachePath];
        if (locationString.length > 0) {
            aLocation = [NSURL fileURLWithPath:locationString];
        }
    }
    BOOL isFileReady = NO;
    if (targetURL) {
        [[NSFileManager defaultManager] removeItemAtURL:targetURL error:nil] ;
        isFileReady = [[NSFileManager defaultManager] moveItemAtURL:aLocation
                                                              toURL:targetURL
                                                              error:&error];
    }
    if (error || !isFileReady) {
        downloadObject.status = HJMURLDownloadStatusDownloadFailed;
        [[NSFileManager defaultManager] removeItemAtURL:aLocation error:nil] ;
    } else {
        downloadObject.status = HJMURLDownloadStatusSucceeded;
    }
    
    void (^DownloadTaskCompleteBlock)(void) = ^(void) {
        void(^AfterFinishingDownloadBlock)(void) = ^(void) {
            [self startNextWaitingDownload];
        };
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (downloadObject.completionBlock) {
                downloadObject.completionBlock(isFileReady, targetURL);
                AfterFinishingDownloadBlock();
            } else {
                if ([self.delegate respondsToSelector:@selector(downloadTaskDidFinishWithDownloadItem:completionBlock:)]) {
                    
                    [self.delegate downloadTaskDidFinishWithDownloadItem:downloadObject
                                                         completionBlock:AfterFinishingDownloadBlock];
                }
            }
        });
    };
    
    [self.coreDataManager updateDownloadItemWithDownloadObject:downloadObject andResumeData:nil];
    [HJMDownloadCoreDataManager saveContext];
    
    [self.activeDownloadsDictionary removeObjectForKey:@(downloadTask.taskIdentifier)];
    if (self.currentFileDownloadsCount > 0) {
        self.currentFileDownloadsCount--;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        DownloadTaskCompleteBlock();
        NotificationBlock();
    });
}

- (void)URLSession:(NSURLSession *)aSession
      downloadTask:(NSURLSessionDownloadTask *)aDownloadTask
      didWriteData:(int64_t)aBytesWrittenCount
 totalBytesWritten:(int64_t)aTotalBytesWrittenCount
totalBytesExpectedToWrite:(int64_t)aTotalBytesExpectedToWriteCount {
    
    HJMURLDownloadObject *downloadObject = self.activeDownloadsDictionary[@(aDownloadTask.taskIdentifier)];
    
    CGFloat progress = (CGFloat)aTotalBytesWrittenCount / (CGFloat)aTotalBytesExpectedToWriteCount;
    downloadObject.downloadProgress = progress;
    downloadObject.status = HJMURLDownloadStatusDownloading;
    downloadObject.receivedFileSizeInBytes = aTotalBytesWrittenCount;
    downloadObject.expectedFileSizeInBytes = aTotalBytesExpectedToWriteCount;
    
    [self.coreDataManager updateDownloadItemWithDownloadObject:downloadObject andResumeData:nil];
    
    CGFloat remainingTime = [self remainingTimeForDownload:downloadObject
                                          bytesTransferred:aTotalBytesWrittenCount
                                 totalBytesExpectedToWrite:aTotalBytesExpectedToWriteCount];
  
    float downloadSpeed = 0;
    NSDate *now = [NSDate date];
    if (self.lastPacketTimestamp)
    {
        NSTimeInterval downloadDurationForPacket = [now timeIntervalSinceDate:self.lastPacketTimestamp];
        float instantSpeed = aBytesWrittenCount / downloadDurationForPacket;
        downloadSpeed = (self.previousSpeed * 0.9) + 0.1 * instantSpeed;
    }
    self.lastPacketTimestamp = now;
    self.previousSpeed = downloadSpeed;
    downloadObject.averageSpeed = downloadSpeed;
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        if (downloadObject.progressBlock) {
            downloadObject.progressBlock(progress, aTotalBytesExpectedToWriteCount, remainingTime, downloadSpeed);
        }
        [self.URLDownloadHandler.delegates enumerateObjectsUsingBlock:^(id<HJMURLDownloadHandlerDelegate> delegate, BOOL *stop) {
            if ([delegate respondsToSelector:@selector(downloadURLDownloadItem:downloadProgress:totalSize:)]) {
                
                [delegate downloadURLDownloadItem:downloadObject
                                 downloadProgress:progress
                                        totalSize:aTotalBytesExpectedToWriteCount];
            }
        }];
        
    });
}

- (void)URLSession:(NSURLSession *)aSession
      downloadTask:(NSURLSessionDownloadTask *)aDownloadTask
 didResumeAtOffset:(int64_t)aFileOffset
expectedTotalBytes:(int64_t)aTotalBytesExpectedCount {
    
    HJMURLDownloadObject *downloadObject = self.activeDownloadsDictionary[@(aDownloadTask.taskIdentifier)];
    if (downloadObject) {
        downloadObject.resumedFileSizeInBytes = aFileOffset;
    }
}

#pragma mark Download Status

- (BOOL)isDownloadingIdentifier:(NSString *)aDownloadIdentifier {
    __block BOOL isDownloading = NO;
    NSInteger aDownloadID = [self downloadIDForDownloadToken:aDownloadIdentifier];
    if (aDownloadID > -1) {
        NSArray *aDownloadIDsArray = [self.activeDownloadsDictionary allKeys];
        if ([aDownloadIDsArray containsObject:@(aDownloadID)]) {
            isDownloading = YES;
        }
    }
    
    if (!isDownloading) {
        [self.waitingDownloadsArray enumerateObjectsUsingBlock:^(HJMURLDownloadObject *downloadObject, NSUInteger idx, BOOL *stop) {
            if ([downloadObject.identifier isEqualToString:aDownloadIdentifier]) {
                isDownloading = YES;
                *stop = YES;
            }
        }];
    }
    return isDownloading;
}

- (BOOL)hasActiveDownloads {
    BOOL aHasActiveDownloadsFlag = NO;
    if ((self.activeDownloadsDictionary.count > 0) || (self.waitingDownloadsArray.count > 0)) {
        aHasActiveDownloadsFlag = YES;
    }
    return aHasActiveDownloadsFlag;
}

- (void)startNextWaitingDownload {
    if (self.isShouldAutomaticlyStartNextWaitingDownloadItem && [self isShouldAddMoreDownloadItem]) {
        if (self.waitingDownloadsArray.count > 0) {
            HJMURLDownloadObject *downloadObject = [self.waitingDownloadsArray firstObject];
            if (downloadObject) {
                [self.waitingDownloadsArray removeObjectAtIndex:0];
                [self startAURLDownloadObject:downloadObject];
            } else if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
                [self stopBackgroundTask];
            }
        }
    }
}

#pragma mark helper

// http://stackoverflow.com/questions/21895853/how-can-i-check-that-an-nsdata-blob-is-valid-as-resumedata-for-an-nsurlsessiondo
- (NSData *)__isValidResumeData:(NSData *)data{
    if (!data || [data length] < 1)
        return nil;
    
    NSError *error;
    NSDictionary *resumeDictionary = [NSPropertyListSerialization propertyListWithData:data
                                                                               options:NSPropertyListImmutable
                                                                                format:NULL
                                                                                 error:&error];
    
    if (!resumeDictionary || error)
        return nil;
    
    NSString *tmpName;
    
    // iOS 8及以下版本，取出tmp绝对路径，检查tmp文件是否存在，并修改tmp绝对路径，重新赋值
    // iOS 9及以上版本，取出tmp文件名，检查tmp文件是否存在
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_8_4) {
        NSString *localFilePath = resumeDictionary[@"NSURLSessionResumeInfoLocalPath"];
        tmpName = [localFilePath lastPathComponent];
    } else {
        tmpName = resumeDictionary[@"NSURLSessionResumeInfoTempFileName"];
    }
    
    if (tmpName.length == 0) {
        return nil;
    }
    
    NSString *currentLocalFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:tmpName];
    BOOL isFileExists =  [[NSFileManager defaultManager] fileExistsAtPath:currentLocalFilePath];
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_8_4) {
        if (isFileExists) {
            NSMutableDictionary *tmpResumMutableDictionary = [NSMutableDictionary dictionaryWithDictionary:resumeDictionary];
            tmpResumMutableDictionary[@"NSURLSessionResumeInfoLocalPath"] = currentLocalFilePath;
            
            NSData *currentData = [NSPropertyListSerialization dataWithPropertyList:tmpResumMutableDictionary
                                                                             format:NSPropertyListBinaryFormat_v1_0
                                                                            options:NSPropertyListImmutable
                                                                              error:&error];
            return currentData;
        }
    }
    
    return isFileExists ? data : nil;
}

- (BOOL)isShouldAddMoreDownloadItem {
    return (self.maxConcurrentFileDownloadsCount == -1) || ((NSInteger)self.currentFileDownloadsCount < self.maxConcurrentFileDownloadsCount);
}

- (void)updateDownloadItemStatus:(HJMURLDownloadStatus)status
                    withDataTask:(NSURLSessionDataTask *)dataTask {
    
    HJMURLDownloadObject *downloadObject = self.activeDownloadsDictionary[@(dataTask.taskIdentifier)];
    downloadObject.status = HJMURLDownloadStatusDownloading;
    
    [self.coreDataManager updateDownloadItemWithDownloadObject:downloadObject andResumeData:nil];
}

- (NSInteger)downloadIDForDownloadToken:(NSString *)identifier {
    __block NSInteger aFoundDownloadID = -1;
    [self.activeDownloadsDictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *aDownloadNumber, HJMURLDownloadObject *aDownloadObject, BOOL *stop) {
        if ([aDownloadObject.identifier isEqualToString:identifier]) {
            aFoundDownloadID = [aDownloadNumber unsignedIntegerValue];
            *stop = YES;
        }
    }];
    return aFoundDownloadID;
}

- (CGFloat)remainingTimeForDownload:(HJMURLDownloadObject *)download
                   bytesTransferred:(int64_t)bytesTransferred
          totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:download.startDate];
    CGFloat speed = (CGFloat)bytesTransferred / (CGFloat)timeInterval;
    CGFloat remainingBytes = totalBytesExpectedToWrite - bytesTransferred;
    CGFloat remainingTime = remainingBytes / speed;
    return remainingTime;
}

#pragma mark - NSURLSessionTaskDelegate

- (void)handleDownloadWithError:(NSError *)anError
              URLDownloadObject:(HJMURLDownloadObject *)downloadObject {
    
    BOOL success = YES;
    if (anError) {
        if ([anError.domain isEqualToString:NSURLErrorDomain] && (anError.code == NSURLErrorCancelled)) {
            downloadObject.status = HJMURLDownloadStatusPaused;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.URLDownloadHandler.delegates enumerateObjectsUsingBlock:^(id<HJMURLDownloadHandlerDelegate> delegate, BOOL *stop) {
                    if ([delegate respondsToSelector:@selector(downloadURLDownloadItemDidPaused:)]) {
                        [delegate downloadURLDownloadItemDidPaused:downloadObject];
                    }
                }];
            });
        } else {
            success = NO;
            downloadObject.status = HJMURLDownloadStatusDownloadFailed;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.URLDownloadHandler.delegates enumerateObjectsUsingBlock:^(id<HJMURLDownloadHandlerDelegate> delegate, BOOL *stop) {
                    if ([delegate respondsToSelector:@selector(downloadURLDownloadItem:didFailWithError:)]) {
                        
                        [delegate downloadURLDownloadItem:downloadObject
                                         didFailWithError:anError];
                    }
                }];
            });
        }
    } else {
        downloadObject.status = HJMURLDownloadStatusProcessing;
    }
    NSData *aSessionDownloadTaskResumeData = anError.userInfo[NSURLSessionDownloadTaskResumeData];
    [self.coreDataManager updateDownloadItemWithDownloadObject:downloadObject andResumeData:downloadObject.isIgnoreResumeDataAfterCancel ? nil : aSessionDownloadTaskResumeData];
    
    [self.activeDownloadsDictionary removeObjectForKey:@(downloadObject.task.taskIdentifier)];
}

- (void)URLSession:(NSURLSession *)aSession
              task:(NSURLSessionTask *)aTask
didCompleteWithError:(NSError *)anError {
    
    if (anError) {
        [self handleDownloadWithError:anError
                    URLDownloadObject:self.activeDownloadsDictionary[@(aTask.taskIdentifier)]];
        self.currentFileDownloadsCount--;
       
        //判断App在后台时是否为用户主动退出
        //如果是主动退出，则不做任何操作
        //否则自动开始下一个任务
        if ([anError.userInfo objectForKey:@"NSURLErrorBackgroundTaskCancelledReasonKey"] &&
            ([[anError.userInfo objectForKey:@"NSURLErrorBackgroundTaskCancelledReasonKey"] integerValue] == NSURLErrorCancelledReasonUserForceQuitApplication)) {
        } else {
            [self startNextWaitingDownload];
        }
    }
}

#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session
didBecomeInvalidWithError:(NSError *)error {
    
    [self setupBackgroundURLSession:[self createABackgroundConfigObject]];
    
    NSArray *aDownloadIdentifiersArray = [self.tmpActiveDownloadsDictionary allKeys];
    NSSortDescriptor *aDownloadIdentifiersSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:nil
                                                                                         ascending:YES
                                                                                        comparator:^(id obj1, id obj2)
                                                                                        {
                                                                                            return [obj1 compare:obj2];
                                                                                        }];
    aDownloadIdentifiersArray = [aDownloadIdentifiersArray sortedArrayUsingDescriptors:@[aDownloadIdentifiersSortDescriptor]];
    
    [aDownloadIdentifiersArray enumerateObjectsUsingBlock:^(NSNumber *indexNumber, NSUInteger idx, BOOL *stop) {
        HJMURLDownloadObject *downloadObject = self.tmpActiveDownloadsDictionary[indexNumber];
        [self startAURLDownloadObject:downloadObject];
    }];
    
    self.isShouldAutomaticlyStartNextWaitingDownloadItem = YES;
    
    [self startNextWaitingDownload];
}

#pragma mark - CompletionHandler

#if TARGET_OS_IPHONE

- (NSMutableDictionary *)completionHandlerDictionary {
    if (!_completionHandlerDictionary) {
        _completionHandlerDictionary = [NSMutableDictionary dictionary];
    }
    return _completionHandlerDictionary;
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    if (session.configuration.identifier)
        [self callCompletionHandlerForSession:session.configuration.identifier];
}

- (void)addCompletionHandler:(HJMURLDownloadBackgroundSessionCompletionHandlerBlock)handler
                  forSession:(NSString *)identifier {
    
    if ([self.completionHandlerDictionary objectForKey: identifier]) {
        NSLog(@"Error: Got multiple handlers for a single session identifier.  This should not happen.\n");
    }
    
    [self.completionHandlerDictionary setObject:handler
                                         forKey:identifier];
}

- (void)callCompletionHandlerForSession:(NSString *)identifier {
    HJMURLDownloadBackgroundSessionCompletionHandlerBlock handler = [self.completionHandlerDictionary objectForKey:identifier];
    
    if (handler) {
        [self.completionHandlerDictionary removeObjectForKey:identifier];
        dispatch_async(dispatch_get_main_queue(), ^{
            handler();
        });
    }
}
#endif

@end
