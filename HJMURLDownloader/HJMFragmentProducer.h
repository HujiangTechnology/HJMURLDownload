//
//  HJMFragmentProducer.h
//  Pods
//
//  Created by lchen on 21/06/2017.
//
//

#import <Foundation/Foundation.h>
#import "M3U8SegmentInfoList.h"

@protocol HJMFragmentProducerDelegate <NSObject>

@required
- (void)fragmentListHasRunOutWithIdentifier:(NSString *)identifier;

@optional
- (void)allFragmentListsHaveRunOut;

@end

@interface HJMFragmentProducer : NSObject

@property (nonatomic, weak) id<HJMFragmentProducerDelegate> delegate;
@property (nonatomic, copy, readonly) NSString *currentDownloadingIdentifier;

- (BOOL)isTableExistInDatabaseWithIdentifier:(NSString *)identifier;

/**
  下一个下载队列的标示
 */
- (M3U8SegmentInfoList *)nextFragmentList;

- (NSInteger)leftFragmentCountWithIdentifier:(NSString *)identifier;

- (NSInteger)totalCountForCurrentFragmentList;

- (void)addFragmentsArray:(M3U8SegmentInfoList *)fragmentArray;

- (NSArray <M3U8SegmentInfo *> *)fragmentsWithOriginalArray:(M3U8SegmentInfoList *)originalArray limitedCount:(NSInteger)limitedCount;

- (M3U8SegmentInfo *)oneMoreFragmentWithIdentifier:(NSString *)identifier;

- (void)removeFragmentOutofDatabaseWithFragmentIdentifier:(NSString *)fragmentIdentifer identifier:(NSString *)identifier;

@end
