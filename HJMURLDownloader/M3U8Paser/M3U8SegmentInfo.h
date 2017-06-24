//
//  M3U8SegmentInfo.h
//  M3U8Kit
//
//  Created by Oneday on 13-1-11.
//  Copyright (c) 2013年 0day. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "HJMURLDownloadExItem.h"

extern NSString *keyM3U8SegmentDuration;
extern NSString *keyM3U8SegmentMediaURLString;

/*!
 @class M3U8SegmentInfo
 @abstract This is the class indicates #EXTINF:<duration>,<title> + media in m3u8 file
 */

@interface M3U8SegmentInfo : NSObject <NSCopying, NSCoding>

@property (nonatomic, assign) CGFloat duration;
@property (nonatomic, copy) NSString   *mediaURLString;
@property (nonatomic, assign) int index;
@property (nonatomic, copy) NSString *md5String;

- (id)initWithDictionary:(NSDictionary *)params;
//- (NSDictionary *)dictionaryValue;

@end
