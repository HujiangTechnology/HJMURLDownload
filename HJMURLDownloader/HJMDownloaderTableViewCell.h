//
//  HJMDownloaderTableViewCell.h
//  HJMURLDownloader
//
//  Created by Yozone Wang on 14/12/31.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HJMDownloaderTableViewCellAndHeaderProtocol.h"

extern NSString * const HJMLastPlayedTimeKey;

@class HJMCDDownloadItem;
@protocol HJMDownloaderTableViewCellDelegate;


@interface HJMDownloaderTableViewCell : UITableViewCell <HJMDownloaderTableViewCellProtocol>

@end
