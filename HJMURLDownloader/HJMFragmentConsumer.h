//
//  HJMFragmentConsumer.h
//  Pods
//
//  Created by lchen on 21/06/2017.
//
//

#import <Foundation/Foundation.h>
#import "M3U8SegmentInfo.h"

@protocol HJMFragmentConsumerDelegate <NSObject>

@required
- (M3U8SegmentInfo *)oneMoreFragmentWithIdentifier:(NSString *)identifier;

- (void)downloadTaskReachProgress:(CGFloat)progress identifier:(NSString *)identifier;

@end

@interface HJMFragmentConsumer : NSObject

@property (nonatomic, weak) id<HJMFragmentConsumerDelegate> delegate;

@property (nonatomic, assign, readonly) BOOL isBusy;

- (instancetype)initWithLimitedConcurrentCount:(NSInteger)count;

- (void)startToDownloadFragmentArray:(NSArray <M3U8SegmentInfo *> *)fragmentArray arrayIdentifer:(NSString *)identifier;
//
//+ (instancetype)fragmentConsumerWithFragmentArray:(NSArray *)fragmentArray;
//
//- (void)startToDownloadWithLimitedCounte:(NSInteger)limitedCount;

@end
