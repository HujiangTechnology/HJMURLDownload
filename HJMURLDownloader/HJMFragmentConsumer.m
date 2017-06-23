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

/**
 重试次数，key为data task的url，value为已经重试的次数
 */
@property (nonatomic, strong) NSMutableDictionary *retryDictionary;

@end

@implementation HJMFragmentConsumer

- (NSMutableDictionary *)retryDictionary {
    if (!_retryDictionary) {
        _retryDictionary = [NSMutableDictionary dictionary];
    }
    return _retryDictionary;
}

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

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    NSNumber *retryTimes = self.retryDictionary[task.originalRequest.URL.absoluteString];
    // get the data task's original url
    if ([retryTimes intValue] < 3) {
        // 记录下来，重试
        [[self.session downloadTaskWithURL:task.originalRequest.URL] resume];
        NSString *urlString = task.originalRequest.URL.absoluteString;
        self.retryDictionary[urlString] = @([retryTimes intValue] +1);
    } else {
        [self.delegate downloadTaskDidCompleteWithError:error identifier:self.currentDownloadIdentifier];
        
    }
    
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
