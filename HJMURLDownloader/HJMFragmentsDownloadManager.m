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
//#import "HJMURLDownloadObject.h"

@implementation HJMFragmentsDownloadManager
static HJMFragmentsDownloadManager *manager;

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[HJMFragmentsDownloadManager alloc] init];
    });
    return manager;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [super allocWithZone:zone];
    });
    return manager;
}

- (void)addDownloadWithURL:(NSURL *)url progress:(HJMURLDownloadProgressBlock)progressBlock complete:(HJMURLDownloadCompletionBlock)completeBlock {
    // 查询数据库中有没有这个表
    // 有这个表的话，不需要请求具体信息，直接拿到core data里面的数据下载即可
    
    
    // 没有这个表，当作一个新的加到core data里面
    NSMutableArray <HJMURLDownloadObject *> *downloadObject = [NSMutableArray array];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"localM3u8" ofType:@"txt"];
    NSString *m3u8String = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    M3U8SegmentInfoList *m3u8InfoList = [M3U8Parser m3u8SegmentInfoListFromPlanString:m3u8String];
    for (M3U8SegmentInfo *segment in m3u8InfoList.segmentInfoList) {
        HJMURLDownloadObject *downloadObject = [[HJMURLDownloadObject alloc] init];
        downloadObject.remoteURL = segment.mediaURL;
//        downloadObject.progressBlock = progressBlock;
//        downloadObject.completionBlock = completeBlock;
        downloadObject.title = [url.absoluteString lastPathComponent];
        downloadObject.identifier = url.absoluteString;
    }
    
    
    
    
    NSArray<HJMURLDownloadObject *> *downloadObjects = [NSArray array];


}

@end
