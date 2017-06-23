//
//  HJMFragmentConsumer.m
//  Pods
//
//  Created by lchen on 21/06/2017.
//
//

#import "HJMFragmentConsumer.h"
#import "HJMFragmentDBManager.h"
#import "M3U8Parser.h"
#import "M3U8SegmentInfoList.h"

@interface HJMFragmentConsumer () <NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, assign) NSInteger limitedCount;
@property (nonatomic, copy) NSString *currentDownloadIdentifier;
@property (nonatomic, strong) NSMutableDictionary *completionHandlerDictionary;

@end

@implementation HJMFragmentConsumer

- (NSMutableDictionary *)completionHandlerDictionary {
    if (!_completionHandlerDictionary) {
        _completionHandlerDictionary = [NSMutableDictionary dictionary];
    }
    return _completionHandlerDictionary;
}

- (instancetype)initWithLimitedConcurrentCount:(NSInteger)count isSupportBackground:(BOOL)isSupportBackground backgroundIdentifier:(NSString *)backgroundIdentifier {
    if (self = [super init]) {
        self.limitedCount = count;
        NSURLSessionConfiguration *configuration;
        if (isSupportBackground) {
            configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:backgroundIdentifier];
        } else {
            configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        }
        self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return self;
}

- (instancetype)init {
    return [self initWithLimitedConcurrentCount:4 isSupportBackground:NO backgroundIdentifier:nil];
}

- (void)startToDownloadFragmentArray:(NSArray <M3U8SegmentInfo *> *)fragmentArray arrayIdentifer:(NSString *)identifier {
    for (M3U8SegmentInfo *fragment in fragmentArray) {
        [[self.session downloadTaskWithURL:nil] resume];
    }
}

- (void)handleEventsForBackgroundURLSession:(NSString *)aBackgroundURLSessionIdentifier completionHandler:(void (^)())aCompletionHandler {
    // 重新创建一个url session，用来后台中剩余的请求
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:aBackgroundURLSessionIdentifier];
    self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    [self.completionHandlerDictionary setObject:aCompletionHandler forKey:aBackgroundURLSessionIdentifier];
}

#pragma mark - HJMURLDownloadHandlerDelegate

- (void)downloadURLDownloadItem:(id<HJMURLDownloadExItem>)item didFailWithError:(NSError *)error {
//    NSNumber *retryTimes = self.retryDictionary[item.identifier];
//    if ([retryTimes intValue] < 3) {
//        [self.downloadManager addURLDownloadItem:item];
//        self.retryDictionary[item.identifier] = @([retryTimes intValue] + 1);
//    } else {
//        // 停止所有下载
//        [self.downloadManager cancelAllDownloads];
//        // 错误抛出去
//        
//    }
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    // 执行存储的block，告诉系统现在可以杀死app了。
    void (^backgroundBlock)() = self.completionHandlerDictionary[session.configuration.identifier];
    if (backgroundBlock) {
        [self.completionHandlerDictionary removeObjectForKey:session.configuration.identifier];
        backgroundBlock();
    }
}


@end
