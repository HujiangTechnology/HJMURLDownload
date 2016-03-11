//
//  HJMDownloaderManagerTableViewController.h
//  HJMURLDownloader
//
//  Created by Yozone Wang on 14/12/31.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HJMDownloaderTableViewCell.h"
#import "HJMDownloadCoreDataManager.h"

extern NSString * const HJMDownloaderDidInsertNewDownloadItemNotification;
extern NSString * const HJMDownloaderDidDeleteDownloadItemNotification;

@class HJMURLDownloadManager;
@class HJMCDDownloadItem;

@interface HJMDownloaderManagerTableViewController : UITableViewController

@property (strong, nonatomic) HJMDownloadCoreDataManager *coreDataManager;
@property (strong, nonatomic) HJMURLDownloadManager *downloadManager;
@property (assign, nonatomic) BOOL showDownloadedOnly;
@property (copy, nonatomic) NSString *sectionName;
@property (strong, nonatomic) UIView *noContentView;

@property (copy, nonatomic) void(^otherActionBlock)(HJMDownloaderManagerTableViewController *viewController, HJMCDDownloadItem *downloadItem);
@property (copy, nonatomic) CGFloat(^tableViewHeaderHeight)(NSInteger section);

@property (nonatomic) NSInteger userID;

@property (nonatomic, strong) NSPredicate *predicate;

@property (nonatomic, copy) NSArray *sortDescriptors;

@property(nonatomic, copy) BOOL (^shouldResumeDownloadBlock)(NSIndexPath *, HJMCDDownloadItem *);

- (void)registerTableViewCellClass:(Class<HJMDownloaderTableViewCellProtocol>)cellClass;

- (void)deleteDownloadItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)registerTableViewHeaderClass:(Class)headerViewClass;

- (void)reloadDownloadData;

@end
