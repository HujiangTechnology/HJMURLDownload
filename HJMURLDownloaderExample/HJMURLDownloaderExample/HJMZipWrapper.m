//
//  HJMZipWrapper.m
//  HJMURLDownloaderExample
//
//  Created by HJ Mobile on 13-7-8.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import "HJMZipWrapper.h"
#import "SSZipArchive.h"

@interface HJMZipWrapper () <SSZipArchiveDelegate> {
    dispatch_queue_t _unzip_queue;
}

@property (copy, nonatomic) HJMUnzipProcessBlock processBlock;

@end

@implementation HJMZipWrapper

- (id)init{
    if(self = [super init]){
        self.progress = 0.0;
    }
    return self;
}



- (void)unzipFileWithProgress:(HJMUnzipProcessBlock)progressBlock complete:(HJMUnzipCompleteBlock)completeBlock failure:(HJMUnzipFailureBlock)failureBlock {
    self.processBlock = progressBlock;

    NSFileManager * fm = [NSFileManager defaultManager];
    BOOL isDir;
    if (![fm fileExistsAtPath:self.targetPath isDirectory:&isDir] && isDir) {
        [fm createDirectoryAtPath:self.targetPath withIntermediateDirectories:YES attributes:nil error:nil];
    }

    _unzip_queue = dispatch_queue_create("com.hujiang.unzip-queue", 0);
    dispatch_async(_unzip_queue, ^{
        NSError * unzipError;
        BOOL unzippedOk = [SSZipArchive unzipFileAtPath:self.archivePath toDestination:self.targetPath overwrite:YES password:self.password error:&unzipError delegate:self];
        if (unzippedOk && !unzipError) {
            if (completeBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completeBlock(self);
                });
            }
        }
        else {
            if (failureBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failureBlock(self, unzipError);
                });
            }
        }
    });
}

- (void)zipArchiveDidUnzipFileAtIndex:(NSInteger)fileIndex totalFiles:(NSInteger)totalFiles archivePath:(NSString *)archivePath fileInfo:(unz_file_info)fileInfo {
    if (self.processBlock) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.processBlock(self, (CGFloat) fileIndex / totalFiles);
        });
    }
}

- (void)dealloc {
#if !OS_OBJECT_USE_OBJC
    dispatch_release(_unzip_queue);
#endif
    _unzip_queue = NULL;
}

@end
