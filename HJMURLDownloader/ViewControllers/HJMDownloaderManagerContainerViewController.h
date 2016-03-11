//
//  HJMDownloaderManagerContainerViewController.h
//  HJMURLDownloader
//
//  Created by Yozone Wang on 15/1/19.
//
//

// TODO: 将 Protocol 和 Delegate 放在一个文件中

#import <UIKit/UIKit.h>

@class HJMURLDownloadManager;
@class HJMDownloaderManagerTableViewController;
@class HJMCDDownloadItem;

@interface HJMDownloaderManagerContainerViewController : UIViewController

/**
*  获得下载管理器同步UI显示
*/
@property (strong, nonatomic) HJMURLDownloadManager *downloadManager;   // 下载管理器
@property (assign, nonatomic) NSInteger userID;                         // 用户标识
@property (strong, nonatomic) UIColor *segmentedControlTintColor;       // segmentControl的颜色
@property (copy, nonatomic) BOOL(^shouldResumeDownloadBlock)(NSIndexPath *indexPath, HJMCDDownloadItem *downloadItem);

/**
*  设置segmentControl的标题
*/
- (void)updateSegmentTitles;

/**
*  设置已经下载项的区头的名字
*
*  @param sectionName 名字
*/
- (void)setDownloadedSectionName:(NSString *)sectionName;

/**
*  设置正在下载项的区头的名字
*
*  @param sectionName 名字
*/
- (void)setDownloadingSectionName:(NSString *)sectionName;

/**
*  设置已经下载页面的tableHeaderView的高度
*
*  @param height tableHeaderView的高度
*/
- (void)setDownloadedTableViewHeaderHeight:(CGFloat)height;

/**
*  设置正在下载页面的tableHeaderView的高度
*
*  @param height tableHeaderView的高度
*/
- (void)setDownloadingTableViewHeaderHeight:(CGFloat)height;

/**
*  设置已经下载页面CoreData检索的谓词
*
*  @param downloadedPredicate 谓词
*/
- (void)setDownloadedPredicate:(NSPredicate *)downloadedPredicate;

/**
*  设置正在下载页面CoreData检索的谓词
*
*  @param downloadingPredicate 谓词
*/
- (void)setDownloadingPredicate:(NSPredicate *)downloadingPredicate;

/**
*  设置已经下载页面排序描述
*
*  @param downloadedSortDescriptors 排序描述
*/
- (void)setDownloadedSortDescriptors:(NSArray *)downloadedSortDescriptors;

/**
*  设置正在下载页面排序描述
*
*  @param downloadingSortDescriptors 排序描述
*/
- (void)setDownloadingSortDescriptors:(NSArray *)downloadingSortDescriptors;

/**
*  设置已经下载页面和正在下载页面tableView样式
*
*  @param makeupBlock 设置样式Block
*/
- (void)makeupTableViewWithBlock:(void(^)(UITableView *tableView))makeupBlock;

/**
*  注册已经下载页面的cell 的类型
*
*  @param cellClass 重用cell的类型
*/
- (void)registerDownloadedCellClass:(Class)cellClass;

/**
*  注册已经下载页面的tableHeaderView的类型
*
*  @param tableViewHeaderClass tableHeaderView的类型
*/
- (void)registerDownloadedHeaderViewClass:(Class)tableViewHeaderClass;

/**
*  注册正在下载页面的cell 的类型
*
*  @param cellClass 重用cell的类型
*/
- (void)registerDownloadingCellClass:(Class)cellClass;

/**
*  注册正在下载页面的tableHeaderView的类型
*
*  @param tableViewHeaderClass tableHeaderView的类型
*/
- (void)registerDownloadingHeaderViewClass:(Class)tableViewHeaderClass;

/**
*  设置已经下载页面无内容页
*
*  @param noContentView 无内容页
*/
- (void)setNoContentViewForDownloadedViewController:(UIView *)noContentView;

/**
*  设置正在下载页面无内容页
*
*  @param noContentView 无内容页
*/
- (void)setNoContentViewForDownloadingViewController:(UIView *)noContentView;

/**
*  点击下载完成的cell的progressButton触发的动作
*
*  @param otherActionBlock 回调Block
*/
- (void)setDownloadedOtherActionBlock:(void(^)(HJMDownloaderManagerTableViewController *downloaderManagerTableViewController, HJMCDDownloadItem *downloadItem))otherActionBlock;

/**
*  刷新页面（内部调用TableView的reloadData）
*/
- (void)reloadDownloadData;

@end
