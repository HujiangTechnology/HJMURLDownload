//
//  HJMURLDownloadNotificationHandler.m
//  HJMURLDownloader
//
//  Created by Dong Han on 12/23/14.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import "HJMURLDownloadNotificationHandler.h"

@implementation HJMURLDownloadNotificationHandler

- (id)init{
    if(self = [super init]){
        self.delegates = [NSMutableSet set];
    }
    return self;
}

- (void)addDownloaderDelegate:(id <HJMURLDownloadHandlerDelegate>)delegate{
    @synchronized(self.delegates){
        [self.delegates addObject:delegate];
    }
}

- (void)removeDownloaderDelegate:(id <HJMURLDownloadHandlerDelegate>)delegate{
    @synchronized(self.delegates){
        [self.delegates removeObject:delegate];
    }
}

@end
