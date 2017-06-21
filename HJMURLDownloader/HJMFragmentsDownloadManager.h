//
//  HJMFragmentsDownloadManager.h
//  Pods
//
//  Created by lchen on 21/06/2017.
//
//

#import <Foundation/Foundation.h>
#import "HJMURLDownloadManager.h"

@interface HJMFragmentsDownloadManager : NSObject

+ (instancetype)sharedManager;

- (void)addDownloadWithURL:(NSURL *)url
                  progress:(HJMURLDownloadProgressBlock)progressBlock
                  complete:(HJMURLDownloadCompletionBlock)completeBlock;


@end
