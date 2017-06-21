//
//  HJMFragmentComsumer.h
//  Pods
//
//  Created by lchen on 21/06/2017.
//
//

#import <Foundation/Foundation.h>

@protocol HJMFragmentComsumerDelegate <NSObject>

- (void)fragmentsArrayRunsOut;

@end

@interface HJMFragmentComsumer : NSObject

@property (nonatomic, weak) id<HJMFragmentComsumerDelegate> delegate;

+ (instancetype)fragmentConsumerWithFragmentArray:(NSArray *)fragmentArray;

- (void)startToDownloadWithLimitedCounte:(NSInteger)limitedCount;

@end
