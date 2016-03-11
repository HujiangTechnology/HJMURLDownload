//
//  HJMDownloaderManagerTableViewController.m
//  HJMURLDownloader
//
//  Created by Yozone Wang on 14/12/31.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import "HJMDownloaderManagerTableViewController.h"
#import "HJMCDDownloadItem.h"
#import "HJMURLDownloadManager.h"
#import "HJMCDDownloadItem+HJMDownloadAdditions.h"

NSString * const HJMDownloaderDidInsertNewDownloadItemNotification = @"com.hujiang.HJMDownloader.didInsertNewDownloadItemNotification";
NSString * const HJMDownloaderDidDeleteDownloadItemNotification = @"com.hujiang.HJMDownloader.didDeleteDownloadItemNotification";

static NSString * const kHJMDownloaderTableViewCellIdentifier = @"HJMDownloaderTableViewCellIdentifier";
static NSString * const kHJMDownloaderTableViewHeaderIdentifier = @"HJMDownloaderTableViewHeaderIdentifier";

@interface HJMDownloaderManagerTableViewController () <NSFetchedResultsControllerDelegate,
        HJMDownloaderTableViewCellDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) UIButton *selectAllButton;
@property (assign, nonatomic) BOOL didInsertNewDownloadItem;
@property (assign, nonatomic) BOOL didDeleteDownloadItem;
@property (assign, nonatomic) BOOL isFirstLoad;

@end

@implementation HJMDownloaderManagerTableViewController

- (void)dealloc {
    self.otherActionBlock = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITableViewSelectionDidChangeNotification
                                                  object:self.tableView];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.isFirstLoad = YES;

    self.navigationItem.rightBarButtonItem = self.editButtonItem;

    [self registerTableViewCellClass:[HJMDownloaderTableViewCell class]];
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.tableView.rowHeight = 80;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.isFirstLoad) {
        [self reloadDownloadData];
        self.isFirstLoad = NO;
    }
}

- (HJMDownloadCoreDataManager *)coreDataManager {
    if (!_coreDataManager) {
        _coreDataManager = [[HJMDownloadCoreDataManager alloc] init];
    }
    return _coreDataManager;
}

- (void)setNoContentView:(UIView *)noContentView {
    if (_noContentView != noContentView) {
        [_noContentView removeFromSuperview];
        _noContentView = noContentView;
        _noContentView.frame = self.view.bounds;
        _noContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                UIViewAutoresizingFlexibleHeight;

        [self.view addSubview:_noContentView];
    }
}

- (NSFetchedResultsController *)fetchedResultsController {
    if (!_fetchedResultsController) {
        NSManagedObjectContext *mainContext = [HJMDownloadCoreDataManager mainManagedObjectContext];
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"HJMCDDownloadItem"];
        if (!self.sortDescriptors) {
            request.sortDescriptors = @[
                    [NSSortDescriptor sortDescriptorWithKey:@"createdAt"
                                                  ascending:YES],
            ];
        } else {
            request.sortDescriptors = self.sortDescriptors;
        }
        NSPredicate *compoundPredicate;
        if (self.showDownloadedOnly) {
            compoundPredicate = [NSPredicate predicateWithFormat:@"state = %d", HJMURLDownloadStatusSucceeded];
        } else {
            compoundPredicate = [NSPredicate predicateWithFormat:@"state != %d", HJMURLDownloadStatusSucceeded];
        }
        compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[
                compoundPredicate,
                [NSPredicate predicateWithFormat:@"(userID = 0 AND (isMultipleExistedWithAnonymous = NO OR isMultipleExistedWithAnonymous = nil)) OR userID = %d", self.userID]
        ]];
        if (self.predicate) {
            compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[compoundPredicate, self.predicate]];
        }

        request.predicate = compoundPredicate;
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:mainContext
                                                                          sectionNameKeyPath:self.sectionName
                                                                                   cacheName:nil];

        _fetchedResultsController.delegate = self;
    }
    return _fetchedResultsController;
}

- (void)setUserID:(NSInteger)userID {
    if (_userID != userID) {
        _userID = userID;
        [self reloadDownloadData];
    }
}

- (void)setSectionName:(NSString *)sectionName {
    if (_sectionName != sectionName) {
        _sectionName = sectionName;
        [self reloadDownloadData];
    }
}

- (void)setSortDescriptors:(NSArray *)sortDescriptors {
    if (_sortDescriptors != sortDescriptors) {
        _sortDescriptors = sortDescriptors;
        [self reloadDownloadData];
    }
}

- (void)reloadDownloadData {
    if (self.fetchedResultsController) {
        self.fetchedResultsController.delegate = nil;
        self.fetchedResultsController = nil;
        [self.fetchedResultsController performFetch:nil];
        [self.tableView reloadData];
        self.noContentView.hidden = [self.fetchedResultsController.fetchedObjects count] > 0;
    }
}

- (void)setPredicate:(NSPredicate *)predicate {
    if (_predicate != predicate) {
        _predicate = predicate;
        [self reloadDownloadData];
    }
}

- (void)registerTableViewCellClass:(Class<HJMDownloaderTableViewCellProtocol>)cellClass {
    [self.tableView registerClass:cellClass
           forCellReuseIdentifier:kHJMDownloaderTableViewCellIdentifier];

}

- (void)registerTableViewHeaderClass:(Class)headerViewClass {
    [self.tableView registerClass:headerViewClass
            forHeaderFooterViewReuseIdentifier:kHJMDownloaderTableViewHeaderIdentifier];

}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSUInteger numberOfSections = [self.fetchedResultsController.sections count];
    tableView.tableFooterView.hidden = [self.fetchedResultsController.fetchedObjects count] == 0;
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {

    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    return sectionInfo.numberOfObjects;
}

- (CGFloat)tableView:(UITableView *)tableView
        heightForHeaderInSection:(NSInteger)section {

    if (!self.sectionName) {
        return 0.0f;
    }
    if (self.tableViewHeaderHeight) {
        return self.tableViewHeaderHeight(section);
    }
    return 0;
}


- (UIView *)tableView:(UITableView *)tableView
        viewForHeaderInSection:(NSInteger)section {

    UITableViewHeaderFooterView <HJMDownloaderHeaderViewProtocol> *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kHJMDownloaderTableViewHeaderIdentifier];
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    headerView.titleLabel.text = sectionInfo.name;
    return headerView;
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell <HJMDownloaderTableViewCellProtocol> *cell = [tableView dequeueReusableCellWithIdentifier:kHJMDownloaderTableViewCellIdentifier forIndexPath:indexPath];
    HJMCDDownloadItem *downloadItem = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.delegate = self;
    [cell updateCellWithDownloadItem:downloadItem];

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView
        canEditRowAtIndexPath:(NSIndexPath *)indexPath {

    HJMCDDownloadItem *downloadItem = [self.fetchedResultsController objectAtIndexPath:indexPath];
    HJMURLDownloadStatus status = (HJMURLDownloadStatus)[downloadItem.state integerValue];
    return status != HJMURLDownloadStatusProcessing;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {

    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView
        commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
        forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self deleteDownloadItemAtIndexPath:indexPath];
    }
}

- (void)deleteDownloadItemAtIndexPath:(NSIndexPath *)indexPath {

    HJMCDDownloadItem *downloadItem = [self.fetchedResultsController objectAtIndexPath:indexPath];
    HJMURLDownloadStatus status = (HJMURLDownloadStatus)[downloadItem.state integerValue];
    if (status == HJMURLDownloadStatusSucceeded) {
        NSString *downloadTargetPath = [downloadItem fullPath];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[NSFileManager defaultManager] removeItemAtPath:downloadTargetPath
                                                       error:nil];

        });
    } else {
        [self.downloadManager deleteAURLDownloadItemIdentifier:downloadItem.identifier];
    }
    [self.coreDataManager deleteDownloadItem:downloadItem];
}

- (NSString *)tableView:(UITableView *)tableView
        titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {

    HJMCDDownloadItem *downloadItem = [self.fetchedResultsController objectAtIndexPath:indexPath];
    HJMURLDownloadStatus status = (HJMURLDownloadStatus)[downloadItem.state integerValue];
    if (status != HJMURLDownloadStatusSucceeded) {
        return NSLocalizedString(@"取消", @"");
    }
    return NSLocalizedString(@"删除", @"");
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)tableView:(UITableView *)tableView
        didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    if (!tableView.isEditing) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        HJMCDDownloadItem *downloadItem = [self.fetchedResultsController objectAtIndexPath:indexPath];
        HJMURLDownloadStatus status = (HJMURLDownloadStatus)[downloadItem.state integerValue];
        if (status == HJMURLDownloadStatusSucceeded) {
            [self performOtherActionForCell:(UITableViewCell <HJMDownloaderTableViewCellProtocol> *)[tableView cellForRowAtIndexPath:indexPath]];
        }
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {

    switch (type) {
        case NSFetchedResultsChangeInsert: {
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];

            self.didInsertNewDownloadItem = YES;
            break;
        }
        case NSFetchedResultsChangeDelete: {
            [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];

            self.didDeleteDownloadItem = YES;
            break;
        }
        case NSFetchedResultsChangeMove: {
            [self.tableView moveRowAtIndexPath:indexPath
                                   toIndexPath:newIndexPath];

            break;
        }
        case NSFetchedResultsChangeUpdate: {
            UITableViewCell <HJMDownloaderTableViewCellProtocol> *cell = (UITableViewCell <HJMDownloaderTableViewCellProtocol> *)[self.tableView cellForRowAtIndexPath:indexPath];

            [cell updateCellWithDownloadItem:anObject];
            break;
        }
    }
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type {

    switch (type) {
        case NSFetchedResultsChangeDelete: {
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationAutomatic];

            break;
        }
        case NSFetchedResultsChangeInsert: {
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationAutomatic];

            break;
        }
        default:
            break;
    }
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
    self.noContentView.hidden = [self.fetchedResultsController.fetchedObjects count] > 0;
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    if (self.didInsertNewDownloadItem) {
        self.didInsertNewDownloadItem = NO;
        [notificationCenter postNotificationName:HJMDownloaderDidInsertNewDownloadItemNotification
                                          object:nil];

    }
    if (self.didDeleteDownloadItem) {
        self.didDeleteDownloadItem = NO;
        [notificationCenter postNotificationName:HJMDownloaderDidDeleteDownloadItemNotification
                                          object:nil];

    }
}

#pragma mark - HJMDownloaderTableViewCellDelegate

- (void)performCancelActionForCell:(UITableViewCell <HJMDownloaderTableViewCellProtocol> *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (indexPath) {

        HJMCDDownloadItem *downloadItem = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [self.downloadManager cancelAURLDownloadWithIdentifier:downloadItem.identifier];
    }
}

- (void)performResumeActionForCell:(UITableViewCell <HJMDownloaderTableViewCellProtocol> *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (indexPath) {
        HJMCDDownloadItem *downloadItem = [self.fetchedResultsController objectAtIndexPath:indexPath];
        if (self.shouldResumeDownloadBlock && !self.shouldResumeDownloadBlock(indexPath, downloadItem)) {
            return;
        }
        HJMURLDownloadObject *downloadObject = [[HJMURLDownloadObject alloc] init];
        downloadObject.identifier = downloadItem.identifier;
        downloadObject.title = downloadItem.name;
        downloadObject.remoteURL = [NSURL URLWithString:downloadItem.downloadURLString];
        downloadObject.downloadItemObjectID = downloadItem.objectID;
        downloadObject.category = downloadItem.category;
        downloadObject.categoryID = downloadItem.categoryID;
        downloadObject.averageSpeed = [downloadItem.averageSpeed floatValue];
        downloadObject.searchPathDirectory = (NSSearchPathDirectory)[downloadItem.searchPathDirectory unsignedIntegerValue];
        downloadObject.relativePath = downloadItem.targetPath;
        downloadObject.resumeData = downloadItem.resumeData;
        downloadObject.downloadProgress = [downloadItem.progress floatValue];
        [self.downloadManager addURLDownloadItem:downloadObject];
    }
}

- (void)performOtherActionForCell:(UITableViewCell <HJMDownloaderTableViewCellProtocol> *)cell {
    if (self.otherActionBlock) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        if (indexPath) {
            HJMCDDownloadItem *downloadItem = [self.fetchedResultsController objectAtIndexPath:indexPath];
            self.otherActionBlock(self, downloadItem);
        }
    }
}

@end
