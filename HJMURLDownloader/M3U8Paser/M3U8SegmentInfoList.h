//
//  M3U8SegmentInfoList.h
//  M3U8Kit
//
//  Created by Oneday on 13-1-11.
//  Copyright (c) 2013年 0day. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "M3U8SegmentInfo.h"

@interface M3U8SegmentInfoList : NSObject
<
NSCopying,
NSCoding
>

@property (nonatomic, assign ,readonly) NSUInteger count;
@property (nonatomic, strong) NSMutableArray <M3U8SegmentInfo *> *segmentInfoList;
@property (nonatomic, copy) NSString *originalUrl;
@property (nonatomic, copy) NSString *identifier;

- (void)addSegementInfo:(M3U8SegmentInfo *)segment;
- (M3U8SegmentInfo *)segmentInfoAtIndex:(NSUInteger)index;

- (NSString *)originalM3U8PlanStringValue;

@end
