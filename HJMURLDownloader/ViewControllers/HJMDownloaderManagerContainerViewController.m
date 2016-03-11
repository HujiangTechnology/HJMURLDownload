//
//  HJMDownloaderManagerContainerViewController.m
//  HJMURLDownloader
//
//  Created by Yozone Wang on 15/1/19.
//
//

#import <HJMURLDownloader/HJMDownloaderManagerTableViewController.h>
#import "HJMDownloaderManagerContainerViewController.h"
#import "HJMSpaceInformationView.h"
#import "HJMURLDownloadManager.h"
#import "HJMCDDownloadItem.h"
#import "HJMSegmentedControl.h"

// FIXME: 用户的关联问题，现在有些混乱，绕得有点晕

@interface UIButton (HJMDownloaderExt)
+ (id)hjm_buttonWithBackgroundImageName:(NSString *)imageName;
+ (id)hjm_buttonWithImageName:(NSString *)imageName;
@end

@interface HJMDownloaderManagerContainerViewController () <UIScrollViewDelegate>

@property (strong, nonatomic) HJMSegmentedControl *segmentedControl;
@property (strong, nonatomic) UIScrollView *containerView;
@property (strong, nonatomic) HJMSpaceInformationView *spaceInformationView;
@property (strong, nonatomic) UIButton *selectAllButton;
@property (strong, nonatomic) UIButton *deleteSelectedButton;

@property (strong, nonatomic) HJMDownloaderManagerTableViewController *downloadingViewController;
@property (strong, nonatomic) HJMDownloaderManagerTableViewController *downloadedViewController;
@property (weak, nonatomic) HJMDownloaderManagerTableViewController *currentViewController;
@property (strong, nonatomic) HJMDownloadCoreDataManager *coreDataManager;
@property (strong, nonatomic) UIToolbar *operationToolbar;
@property (strong, nonatomic) UIView *separatorView;

@property(nonatomic, strong) NSArray *constraints;
@end

@implementation HJMDownloaderManagerContainerViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil
                         bundle:(NSBundle *)nibBundleOrNil {

    self = [super initWithNibName:nibNameOrNil
                           bundle:nibBundleOrNil];

    if (self) {

        [self commonInit];
    }
    return self;
}

- (void)awakeFromNib {

    [super awakeFromNib];
    [self commonInit];
}

- (void)commonInit {

    _downloadingViewController = [[HJMDownloaderManagerTableViewController alloc] initWithNibName:nil
                                                                                           bundle:nil];
    _downloadingViewController.showDownloadedOnly = NO;
    [self addChildViewController:_downloadingViewController];
    [_downloadingViewController didMoveToParentViewController:self];

    _downloadedViewController = [[HJMDownloaderManagerTableViewController alloc] initWithNibName:nil
                                                                                          bundle:nil];
    _downloadedViewController.showDownloadedOnly = YES;
    [self addChildViewController:_downloadedViewController];
    [_downloadedViewController didMoveToParentViewController:self];
}

- (void)dealloc {

    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];

    [defaultCenter removeObserver:self
                             name:UITableViewSelectionDidChangeNotification
                           object:_currentViewController.tableView];

    [defaultCenter removeObserver:self
                             name:HJMDownloaderDidDeleteDownloadItemNotification
                           object:nil];

    [defaultCenter removeObserver:self
                             name:HJMDownloaderDidInsertNewDownloadItemNotification
                           object:nil];

    [_downloadedViewController willMoveToParentViewController:nil];
    [_downloadedViewController removeFromParentViewController];

    [_downloadingViewController willMoveToParentViewController:nil];
    [_downloadingViewController removeFromParentViewController];

    _containerView.delegate = nil;
    _containerView = nil;
}

- (HJMDownloadCoreDataManager *)coreDataManager {

    if (!_coreDataManager) {
        _coreDataManager = [HJMDownloadCoreDataManager new];
        _coreDataManager.userID = self.userID;
    }
    return _coreDataManager;
}

- (void)loadView {

    [super loadView];

    self.segmentedControl = ({
        HJMSegmentedControl *segmentedControl = [[HJMSegmentedControl alloc] initWithItems:[self segmentTitles]];
        segmentedControl.showsGhostIndicatorView = NO;
        segmentedControl.animatedSwitch = NO;
        segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
        segmentedControl.selectedSegmentIndex = 0;
        segmentedControl.separatorImage = [UIImage imageNamed:@"separator-line"];
        if (self.segmentedControlTintColor) {
            segmentedControl.tintColor = self.segmentedControlTintColor;
        }
        [self.view addSubview:segmentedControl];
        segmentedControl;
    });

    self.spaceInformationView = ({

        HJMSpaceInformationView *informationView = [[HJMSpaceInformationView alloc] initWithFrame:CGRectMake(0,
                CGRectGetHeight(self.view.frame) - 10.0f - self.bottomLayoutGuide.length,
                CGRectGetWidth(self.view.bounds),
                10.0f)];

        informationView.translatesAutoresizingMaskIntoConstraints = NO;
        informationView.tintColor = [UIColor colorWithRed:0.486
                                                    green:0.831
                                                     blue:0.439
                                                    alpha:1.000];

        informationView.backgroundColor = [UIColor colorWithWhite:0.847
                                                            alpha:1.000];

        informationView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                UIViewAutoresizingFlexibleTopMargin;

        [self.view addSubview:informationView];
        informationView;
    });

    self.containerView = ({

        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
        scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        scrollView.scrollEnabled = NO;
        scrollView.pagingEnabled = YES;
        scrollView.scrollsToTop = NO;
        scrollView.delegate = self;
        scrollView.showsHorizontalScrollIndicator = NO;
        scrollView.bounces = NO;
        [self.view addSubview:scrollView];
        scrollView;
    });

    self.separatorView = [UIView new];
    self.separatorView.backgroundColor = [UIColor colorWithWhite:0.84
                                                           alpha:1.0f];
    self.separatorView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.separatorView];

    [self.containerView addSubview:self.downloadedViewController.view];
    [self.containerView addSubview:self.downloadingViewController.view];
    _downloadingViewController.tableView.scrollsToTop = NO;

    self.operationToolbar = [UIToolbar new];
    self.operationToolbar.hidden = YES;
    self.operationToolbar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.operationToolbar];
}

- (void)updateViewConstraints {
    [super updateViewConstraints];

    if (!self.constraints) {
        id topLayoutGuide = self.topLayoutGuide;
        NSDictionary *variableBindings;
        variableBindings = NSDictionaryOfVariableBindings(_segmentedControl,
                _containerView,
                _spaceInformationView,
                topLayoutGuide,
                _operationToolbar);

        NSArray *verticalConstraints;
        if (self.operationToolbar.isHidden) {
            verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topLayoutGuide][_segmentedControl(==40)][_containerView(>=0)][_spaceInformationView(==10)]|"
                                                                          options:kNilOptions
                                                                          metrics:nil
                                                                            views:variableBindings];
        } else {
            verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topLayoutGuide][_segmentedControl(==40)][_containerView(>=0)][_operationToolbar(==44)][_spaceInformationView(==10)]|"
                                                                          options:kNilOptions
                                                                          metrics:nil
                                                                            views:variableBindings];

            self.containerView.contentInset = UIEdgeInsetsMake(0,
                    0,
                    44,
                    0);
        }

        self.constraints = verticalConstraints;
        [self.view addConstraints:verticalConstraints];
        NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:_segmentedControl
                                                                      attribute:NSLayoutAttributeWidth
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.view
                                                                      attribute:NSLayoutAttributeWidth
                                                                     multiplier:1 constant:0];
        [self.view addConstraint:constraint];
        constraint = [NSLayoutConstraint constraintWithItem:_operationToolbar
                                                  attribute:NSLayoutAttributeWidth
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self.view
                                                  attribute:NSLayoutAttributeWidth
                                                 multiplier:1 constant:0];
        [self.view addConstraint:constraint];
        constraint = [NSLayoutConstraint constraintWithItem:_segmentedControl
                                                  attribute:NSLayoutAttributeLeft
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self.view
                                                  attribute:NSLayoutAttributeLeft
                                                 multiplier:1 constant:0];
        [self.view addConstraint:constraint];
        constraint = [NSLayoutConstraint constraintWithItem:_operationToolbar
                                                  attribute:NSLayoutAttributeLeft
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self.view
                                                  attribute:NSLayoutAttributeLeft
                                                 multiplier:1 constant:0];
        [self.view addConstraint:constraint];
        constraint = [NSLayoutConstraint constraintWithItem:_containerView
                                                  attribute:NSLayoutAttributeWidth
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self.view
                                                  attribute:NSLayoutAttributeWidth
                                                 multiplier:1 constant:0];
        [self.view addConstraint:constraint];
        constraint = [NSLayoutConstraint constraintWithItem:_separatorView
                                                  attribute:NSLayoutAttributeLeft
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self.view
                                                  attribute:NSLayoutAttributeLeft
                                                 multiplier:1 constant:0];
        [self.view addConstraint:constraint];
        constraint = [NSLayoutConstraint constraintWithItem:_separatorView
                                                  attribute:NSLayoutAttributeWidth
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self.view
                                                  attribute:NSLayoutAttributeWidth
                                                 multiplier:1 constant:0];
        [self.view addConstraint:constraint];
        constraint = [NSLayoutConstraint constraintWithItem:_separatorView
                                                  attribute:NSLayoutAttributeHeight
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:nil
                                                  attribute:NSLayoutAttributeNotAnAttribute
                                                 multiplier:1 constant:1.0f / [UIScreen mainScreen].scale];
        [self.view addConstraint:constraint];
        constraint = [NSLayoutConstraint constraintWithItem:_separatorView
                                                  attribute:NSLayoutAttributeTop
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self.segmentedControl
                                                  attribute:NSLayoutAttributeBottom
                                                 multiplier:1 constant:0];
        [self.view addConstraint:constraint];
        constraint = [NSLayoutConstraint constraintWithItem:_containerView
                                                  attribute:NSLayoutAttributeLeft
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self.view
                                                  attribute:NSLayoutAttributeLeft
                                                 multiplier:1 constant:0];
        [self.view addConstraint:constraint];
        constraint = [NSLayoutConstraint constraintWithItem:_spaceInformationView
                                                  attribute:NSLayoutAttributeWidth
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self.view
                                                  attribute:NSLayoutAttributeWidth
                                                 multiplier:1 constant:0];
        [self.view addConstraint:constraint];

        UIView *downloadedView = self.downloadedViewController.view;
        UIView *downloadingView = self.downloadingViewController.view;
        downloadedView.translatesAutoresizingMaskIntoConstraints = NO;
        downloadingView.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *containerVariableBindings = NSDictionaryOfVariableBindings(_containerView,
                downloadedView,
                downloadingView);

        NSArray *containerConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[downloadedView(==_containerView)]|"
                                                                                options:kNilOptions
                                                                                metrics:nil
                                                                                  views:containerVariableBindings];

        [self.containerView addConstraints:containerConstraints];
        containerConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[downloadingView(==_containerView)]|"
                                                                       options:kNilOptions
                                                                       metrics:nil
                                                                         views:containerVariableBindings];

        [self.containerView addConstraints:containerConstraints];
        containerConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[downloadedView(==_containerView)][downloadingView(==_containerView)]|"
                                                                       options:kNilOptions
                                                                       metrics:nil
                                                                         views:containerVariableBindings];

        [self.containerView addConstraints:containerConstraints];
    } else {

        [self.view removeConstraints:self.constraints];
        id topLayoutGuide = self.topLayoutGuide;
        NSDictionary *variableBindings;
        variableBindings = NSDictionaryOfVariableBindings(_segmentedControl,
                _containerView,
                _spaceInformationView,
                topLayoutGuide,
                _operationToolbar);
        NSArray *verticalConstraints;
        if (self.operationToolbar.isHidden) {
            verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topLayoutGuide][_segmentedControl(==40)][_containerView(>=0)][_spaceInformationView(==10)]|"
                                                                          options:kNilOptions
                                                                          metrics:nil
                                                                            views:variableBindings];

        } else {

            verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topLayoutGuide][_segmentedControl(==40)][_containerView(>=0)][_operationToolbar(==44)][_spaceInformationView(==10)]|"
                                                                          options:kNilOptions
                                                                          metrics:nil
                                                                            views:variableBindings];

        }
        self.constraints = verticalConstraints;
        [self.view addConstraints:verticalConstraints];
    }
}

- (void)setSegmentedControlTintColor:(UIColor *)segmentedControlTintColor {
    if (_segmentedControlTintColor != segmentedControlTintColor) {
        _segmentedControlTintColor = segmentedControlTintColor;
        self.segmentedControl.tintColor = segmentedControlTintColor;
    }
}

- (NSArray *)segmentTitles {
    NSUInteger downloadedCount = [self.coreDataManager countDownloadedItemsWithPredicate:nil];
    NSMutableAttributedString *downloadedAttributedString = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"已下载", @"")
                                                                                                   attributes:@{
                                                                                                           NSFontAttributeName : [UIFont systemFontOfSize:15.0f],
                                                                                                           NSForegroundColorAttributeName : [UIColor colorWithWhite:0.400
                                                                                                                                                              alpha:1.000]
                                                                                                   }];

    if (downloadedCount > 0) {
        [downloadedAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %ld", (long)downloadedCount] attributes:@{
                NSFontAttributeName : [UIFont systemFontOfSize:12.0f],
                NSForegroundColorAttributeName : [UIColor colorWithWhite:0.600
                                                                   alpha:1.000]
        }]];
    }

    NSUInteger downloadingCount = [self.coreDataManager countDownloadingItemsWithPredicate:nil];
    NSMutableAttributedString *downloadingAttributedString = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"下载中", @"") attributes:@{
            NSFontAttributeName : [UIFont systemFontOfSize:15.0f],
            NSForegroundColorAttributeName : [UIColor colorWithWhite:0.400
                                                               alpha:1.000]
    }];

    if (downloadingCount > 0) {
        [downloadingAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %ld", (long)downloadingCount] attributes:@{
                NSFontAttributeName : [UIFont systemFontOfSize:12.0f],
                NSForegroundColorAttributeName : [UIColor colorWithWhite:0.600
                                                                   alpha:1.000]
        }]];
    }

    return @[downloadedAttributedString, downloadingAttributedString];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.segmentedControl addTarget:self
                              action:@selector(segmentedControlValueChanged:)
                    forControlEvents:UIControlEventValueChanged];

    [self.segmentedControl associateWithScrollView:self.containerView];

    [self setCurrentViewControllerToIndex:self.segmentedControl.selectedSegmentIndex];

    UIBarButtonItem *editBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"编辑", @"")
                                                                          style:UIBarButtonItemStylePlain
                                                                         target:self
                                                                         action:@selector(toggleEditing:)];

    self.navigationItem.rightBarButtonItem = editBarButtonItem;

    [self makeupToolbar];

    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self
                      selector:@selector(updateDownloadInformation:)
                          name:HJMDownloaderDidDeleteDownloadItemNotification
                        object:nil];

    [defaultCenter addObserver:self
                      selector:@selector(updateDownloadInformation:)
                          name:HJMDownloaderDidInsertNewDownloadItemNotification
                        object:nil];
}

- (void)updateDownloadInformation:(NSNotification *)notification {
    [self.spaceInformationView reloadSpaceInformation];
    [self updateSegmentTitles];
    [self updateToolbarButtonStatus];
}

- (void)updateSegmentTitles {
    [[self segmentTitles] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.segmentedControl setAttributedTitle:obj
                                forSegmentAtIndex:idx];
    }];
}

- (void)tableViewSelectionDidChangeNotification:(NSNotification *)notification {
    [self updateToolbarButtonStatus];
}

- (void)toggleEditing:(UIBarButtonItem *)barButtonItem {
    [self setEditing:!self.isEditing animated:YES];
}

- (void)setEditing:(BOOL)editing
          animated:(BOOL)animated {

    if (editing) {
        if (self.currentViewController.isEditing) {

            [self.currentViewController setEditing:NO
                                          animated:YES];
        }
    }
    [super setEditing:editing animated:animated];

    [self.currentViewController setEditing:editing
                                  animated:YES];

    if (self.isEditing) {
        self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"取消", @"");
    } else {
        self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"编辑", @"");
    }

    self.segmentedControl.enabled = !editing;
    //    self.containerView.scrollEnabled = !editing;
    [self.operationToolbar setHidden:!editing];
    //    [self.navigationController setToolbarHidden:!editing animated:YES];
    [self updateViewConstraints];
    [self updateToolbarButtonStatus];
    if (!editing) {
        self.selectAllButton.selected = NO;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.spaceInformationView reloadSpaceInformation];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)setDownloadManager:(HJMURLDownloadManager *)downloadManager {

    if (_downloadManager != downloadManager) {

        _downloadManager = downloadManager;
        self.coreDataManager = downloadManager.coreDataManager;
        self.userID = downloadManager.userID;
        self.downloadedViewController.coreDataManager = self.coreDataManager;
        self.downloadedViewController.downloadManager = downloadManager;
        self.downloadingViewController.coreDataManager = self.coreDataManager;
        self.downloadingViewController.downloadManager = downloadManager;
    }
}

- (void)segmentedControlValueChanged:(HJMSegmentedControl *)segmentedControl {

    [self setCurrentViewControllerToIndex:segmentedControl.selectedSegmentIndex];

    [self.containerView setContentOffset:CGPointMake(CGRectGetMinX(self.currentViewController.view.frame), 0)
                                animated:YES];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self setCurrentViewControllerToIndex:self.segmentedControl.selectedSegmentIndex];
}

- (void)setCurrentViewControllerToIndex:(NSInteger)selectedIndex {
    if (selectedIndex == 0) {
        self.currentViewController = self.downloadedViewController;
    } else {
        self.currentViewController = self.downloadingViewController;
    }
    [self setEditing:NO animated:NO];
}

- (void)setCurrentViewController:(HJMDownloaderManagerTableViewController *)currentViewController {

    if (_currentViewController != currentViewController) {
        _currentViewController.tableView.scrollsToTop = NO;
        [_currentViewController setEditing:NO animated:NO];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UITableViewSelectionDidChangeNotification
                                                      object:_currentViewController.tableView];

        _currentViewController = currentViewController;
        _currentViewController.tableView.scrollsToTop = YES;
        // 监听 UITableView 选择变化
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(tableViewSelectionDidChangeNotification:)
                                                     name:UITableViewSelectionDidChangeNotification
                                                   object:currentViewController.tableView];

    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    [self.containerView setContentOffset:CGPointMake(CGRectGetMinX(self.currentViewController.view.frame), 0)
                                animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - setup HJMDownloaderManagerTableViewController

- (void)setDownloadedPredicate:(NSPredicate *)downloadedPredicate {
    self.downloadedViewController.predicate = downloadedPredicate;
}

- (void)setDownloadingPredicate:(NSPredicate *)downloadingPredicate {
    self.downloadingViewController.predicate = downloadingPredicate;
}

- (void)setDownloadedSortDescriptors:(NSArray *)downloadedSortDescriptors {
    self.downloadedViewController.sortDescriptors = downloadedSortDescriptors;
}

- (void)setDownloadingSortDescriptors:(NSArray *)downloadingSortDescriptors {
    self.downloadedViewController.sortDescriptors = downloadingSortDescriptors;
}

- (void)setUserID:(NSInteger)userID {

    if (_userID != userID) {
        _userID = userID;
        self.coreDataManager.userID = userID;
        self.downloadedViewController.userID = userID;
        self.downloadingViewController.userID = userID;
    }
}

- (void)makeupTableViewWithBlock:(void (^)(UITableView *tableView))makeupBlock {

    makeupBlock(self.downloadedViewController.tableView);
    makeupBlock(self.downloadingViewController.tableView);
}

- (void)registerDownloadedCellClass:(Class)cellClass {
    [self.downloadedViewController registerTableViewCellClass:cellClass];
}

- (void)registerDownloadedHeaderViewClass:(Class)tableViewHeaderClass {
    [self.downloadedViewController registerTableViewHeaderClass:tableViewHeaderClass];
}

- (void)registerDownloadingCellClass:(Class)cellClass {
    [self.downloadingViewController registerTableViewCellClass:cellClass];
}

- (void)registerDownloadingHeaderViewClass:(Class)tableViewHeaderClass {
    [self.downloadingViewController registerTableViewHeaderClass:tableViewHeaderClass];
}

- (void)setDownloadedOtherActionBlock:(void (^)(HJMDownloaderManagerTableViewController *downloaderManagerTableViewController, HJMCDDownloadItem *downloadItem))otherActionBlock {
    self.downloadedViewController.otherActionBlock = otherActionBlock;
}

- (void)setDownloadedSectionName:(NSString *)sectionName {
    self.downloadedViewController.sectionName = sectionName;
}

- (void)setDownloadingSectionName:(NSString *)sectionName {
    self.downloadingViewController.sectionName = sectionName;
}

- (void)setDownloadedTableViewHeaderHeight:(CGFloat)height {
    self.downloadedViewController.tableViewHeaderHeight = ^CGFloat(NSInteger section) {
        return height;
    };
}

- (void)setDownloadingTableViewHeaderHeight:(CGFloat)height {
    self.downloadingViewController.tableViewHeaderHeight = ^CGFloat(NSInteger section) {
        return height;
    };
}

- (void)setNoContentViewForDownloadedViewController:(UIView *)noContentView {
    self.downloadedViewController.noContentView = noContentView;
}

- (void)setNoContentViewForDownloadingViewController:(UIView *)noContentView {
    self.downloadingViewController.noContentView = noContentView;
}


- (void)reloadDownloadData {
    [self.downloadedViewController reloadDownloadData];
    [self.downloadingViewController reloadDownloadData];
    [self updateSegmentTitles];
}

- (void)setShouldResumeDownloadBlock:(BOOL (^)(NSIndexPath *, HJMCDDownloadItem *))shouldResumeDownloadBlock {
    if (_shouldResumeDownloadBlock != shouldResumeDownloadBlock) {
        _shouldResumeDownloadBlock = shouldResumeDownloadBlock;
        self.downloadingViewController.shouldResumeDownloadBlock = shouldResumeDownloadBlock;
    }
}

#pragma mark - download item management

- (void)makeupToolbar {

    UIButton *selectAllButton = [UIButton hjm_buttonWithImageName:@"uncheck-icon"];

    [selectAllButton setImage:[UIImage imageNamed:@"check-icon"]
                     forState:UIControlStateSelected];

    [selectAllButton setTitle:@"全选"
                     forState:UIControlStateNormal];

    [selectAllButton setTitleColor:[UIColor colorWithRed:0.3255
                                                   green:0.3255
                                                    blue:0.3255
                                                   alpha:1.0]
                          forState:UIControlStateNormal];

    selectAllButton.titleLabel.font = [UIFont systemFontOfSize:14.0f];

    [selectAllButton addTarget:self
                        action:@selector(selectAllButtonPressed:)
              forControlEvents:UIControlEventTouchUpInside];

    selectAllButton.frame = CGRectMake(0,
            0,
            140,
            32);

    self.selectAllButton = selectAllButton;
    UIBarButtonItem *selectAllButtonItem = [[UIBarButtonItem alloc] initWithCustomView:selectAllButton];

    UIBarButtonItem *flexibleBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                           target:nil
                                                                                           action:nil];

    UIButton *deleteSelectedButton = [UIButton hjm_buttonWithBackgroundImageName:@"delete-btn"];
    [deleteSelectedButton setTitle:@"删除"
                          forState:UIControlStateNormal];

    [deleteSelectedButton setTitleColor:[UIColor whiteColor]
                               forState:UIControlStateNormal];

    deleteSelectedButton.titleLabel.font = [UIFont systemFontOfSize:14.0f];
    deleteSelectedButton.frame = CGRectMake(0,
            0,
            140,
            32);

    [deleteSelectedButton addTarget:self
                             action:@selector(deleteSelectedButtonPressed:)
                   forControlEvents:UIControlEventTouchUpInside];

    self.deleteSelectedButton = deleteSelectedButton;
    UIBarButtonItem *deleteSelectedButtonItem = [[UIBarButtonItem alloc] initWithCustomView:deleteSelectedButton];

    [self.operationToolbar setItems:@[flexibleBarButtonItem,
                    selectAllButtonItem,
                    flexibleBarButtonItem,
                    deleteSelectedButtonItem,
                    flexibleBarButtonItem]
                           animated:YES];


    [self updateToolbarButtonStatus];
}

- (void)updateToolbarButtonStatus {

    UITableView *tableView = self.currentViewController.tableView;
    NSUInteger selectedCount = [[tableView indexPathsForSelectedRows] count];
    NSUInteger totalCounts = 0;
    for (int i = 0; i < [self.currentViewController numberOfSectionsInTableView:tableView]; ++i) {

        totalCounts += [self.currentViewController tableView:tableView
                                       numberOfRowsInSection:i];

    }

    self.selectAllButton.selected = (totalCounts > 0 && totalCounts == selectedCount);
    self.deleteSelectedButton.enabled = [[self.currentViewController.tableView indexPathsForSelectedRows] count] > 0;
}

- (void)deleteSelectedButtonPressed:(UIButton *)button {
    NSArray *selectedIndexPaths = [[self.currentViewController.tableView indexPathsForSelectedRows] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj2 compare:obj1];
    }];

    for (NSIndexPath *indexPath in selectedIndexPaths) {
        [self.currentViewController deleteDownloadItemAtIndexPath:indexPath];
    }
    [self setEditing:NO animated:YES];
}

- (void)selectAllButtonPressed:(UIButton *)button {
    button.selected = !button.isSelected;
    if (button.isSelected) {
        NSInteger sections = [self.currentViewController numberOfSectionsInTableView:self.currentViewController.tableView];
        for (NSInteger i = 0; i < sections; ++i) {

            NSInteger rows = [self.currentViewController tableView:self.currentViewController.tableView
                                             numberOfRowsInSection:i];

            for (NSInteger j = 0; j < rows; ++j) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:j
                                                            inSection:i];

                if ([self.currentViewController tableView:self.currentViewController.tableView
                                    canEditRowAtIndexPath:indexPath]) {

                    [self.currentViewController.tableView selectRowAtIndexPath:indexPath
                                                                      animated:YES
                                                                scrollPosition:UITableViewScrollPositionNone];

                }
            }
        }
    } else {

        NSInteger sections = [self.currentViewController numberOfSectionsInTableView:self.currentViewController.tableView];
        for (NSInteger i = 0; i < sections; ++i) {

            NSInteger rows = [self.currentViewController tableView:self.currentViewController.tableView
                                             numberOfRowsInSection:i];

            for (NSInteger j = 0; j < rows; ++j) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:j inSection:i];
                [self.currentViewController.tableView deselectRowAtIndexPath:indexPath
                                                                    animated:YES];
            }
        }
    }
    [self updateToolbarButtonStatus];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end


@implementation UIButton (HJMDownloaderExt)

+ (id)hjm_buttonWithBackgroundImageName:(NSString *)imageName {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.exclusiveTouch = YES;
    UIImage *image = [UIImage imageNamed:imageName];
    UIImage *highlightImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@_pressed", imageName]];
    UIImage *selectedImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@_select", imageName]];
    // make resizable image
    CGFloat resizableMargin = 0;
    if ((NSInteger)image.size.width % 2 == 0) {
        resizableMargin = floorf(image.size.width / 2) - 1;
    }
    else {
        resizableMargin = floorf(image.size.width / 2);
    }
    image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(0, resizableMargin, 0, resizableMargin)];
    highlightImage = [highlightImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, resizableMargin, 0, resizableMargin)];
    selectedImage = [selectedImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, resizableMargin, 0, resizableMargin)];

    [button setBackgroundImage:image forState:UIControlStateNormal];
    [button setBackgroundImage:highlightImage forState:UIControlStateHighlighted];
    [button setBackgroundImage:selectedImage forState:UIControlStateSelected];
    button.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    return button;
}

+ (id)hjm_buttonWithImageName:(NSString *)imageName {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.exclusiveTouch = YES;
    UIImage *image = [UIImage imageNamed:imageName];
    UIImage *highlightImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@_pressed", imageName]];
    UIImage *selectedImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@_select", imageName]];
    // make resizable image
    CGFloat resizableMargin = 0;
    if ((NSInteger)image.size.width % 2 == 0) {
        resizableMargin = floorf(image.size.width / 2) - 1;
    }
    else {
        resizableMargin = floorf(image.size.width / 2);
    }
    image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(0, resizableMargin, 0, resizableMargin)];
    highlightImage = [highlightImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, resizableMargin, 0, resizableMargin)];
    selectedImage = [selectedImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, resizableMargin, 0, resizableMargin)];

    [button setImage:image forState:UIControlStateNormal];
    [button setImage:highlightImage forState:UIControlStateHighlighted];
    [button setImage:selectedImage forState:UIControlStateSelected];
    button.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    return button;
}

@end
