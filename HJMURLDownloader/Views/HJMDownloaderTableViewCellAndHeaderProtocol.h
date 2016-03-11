//
//  HJMDownloaderTableViewCellAndHeaderProtocol.h
//  HJMURLDownloader
//
//  Created by Yozone Wang on 15/1/27.
//
//

#import <Foundation/Foundation.h>

@class HJMCDDownloadItem;

@protocol HJMDownloaderHeaderViewProtocol <NSObject>

@property (strong, readonly, nonatomic) UILabel *titleLabel;

@end

typedef NS_ENUM(NSUInteger , HJMDownloadManagerCellAction) {
    HJMDownloadManagerCellActionNone,
    HJMDownloadManagerCellActionCancel,
    HJMDownloadManagerCellActionResume,
    HJMDownloadManagerCellActionOther
};

@protocol HJMDownloaderTableViewCellDelegate;

@protocol HJMDownloaderTableViewCellProtocol <NSObject>

@property (weak, nonatomic) id <HJMDownloaderTableViewCellDelegate> delegate;

- (void)updateCellWithDownloadItem:(HJMCDDownloadItem *)downloadItem;

@end

@protocol HJMDownloaderTableViewCellDelegate <NSObject>

- (void)performCancelActionForCell:(UITableViewCell <HJMDownloaderTableViewCellProtocol> *)cell;
- (void)performResumeActionForCell:(UITableViewCell <HJMDownloaderTableViewCellProtocol> *)cell;
- (void)performOtherActionForCell:(UITableViewCell <HJMDownloaderTableViewCellProtocol> *)cell;

@end