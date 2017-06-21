//
//  HJMFragmentProducer.h
//  Pods
//
//  Created by lchen on 21/06/2017.
//
//

#import <Foundation/Foundation.h>

@interface HJMFragmentProducer : NSObject

+ (instancetype)FragmentProducerWithFragmentArray:(NSArray *)fragmentArray;

- (NSArray *)moreFragmentsWithLimitedCount:(NSInteger)limitedCount;

- (id)oneMoreFragment;

@end
