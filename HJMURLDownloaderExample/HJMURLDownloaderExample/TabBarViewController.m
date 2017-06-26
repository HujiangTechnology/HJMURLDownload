//
//  TabBarViewController.m
//  HJMURLDownloaderExample
//
//  Created by Yozone Wang on 15/1/12.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import "TabBarViewController.h"
#import "HJMDownloaderManagerContainerViewController.h"
#import "HJMDownloaderHeaderView.h"
#import "ViewController.h"
#import "HJMDownloaderManagerTableViewController.h"
#import <HJMURLDownloader/HJMCDDownloadItem+HJMDownloadAdditions.h>

@interface TabBarViewController ()

@end

@implementation TabBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    ViewController *viewController = [self.childViewControllers firstObject];
    
    UINavigationController *navigationController = [self.childViewControllers objectAtIndex:1];
    navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.141 green:0.553 blue:0.886 alpha:1.000];
    navigationController.navigationBar.tintColor = [UIColor whiteColor];
    navigationController.navigationBar.translucent = NO;
    NSMutableDictionary *attributes = [[navigationController.navigationBar titleTextAttributes] mutableCopy] ?: [NSMutableDictionary dictionaryWithCapacity:1];
    attributes[NSForegroundColorAttributeName] = [UIColor whiteColor];
    [navigationController.navigationBar setTitleTextAttributes:attributes];
    [navigationController.navigationBar setBarStyle:UIBarStyleBlack];

    HJMDownloaderManagerContainerViewController *downloaderManagerContainerViewController = (HJMDownloaderManagerContainerViewController *)navigationController.topViewController;
    [downloaderManagerContainerViewController setSegmentedControlTintColor:[UIColor colorWithRed:0.141
                                                                                           green:0.553
                                                                                            blue:0.886
                                                                                           alpha:1.000]];
    
    downloaderManagerContainerViewController.downloadManager = viewController.downloadManager;
    [downloaderManagerContainerViewController setDownloadedSortDescriptors:@[
            [NSSortDescriptor sortDescriptorWithKey:@"categoryCreatedAt" ascending:NO],
            [NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES],
            [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]
    ]];
    [downloaderManagerContainerViewController setDownloadedSectionName:@"sectionName"];
    [downloaderManagerContainerViewController setDownloadedTableViewHeaderHeight:35.0f];
    [downloaderManagerContainerViewController registerDownloadedHeaderViewClass:[HJMDownloaderHeaderView class]];
    [downloaderManagerContainerViewController makeupTableViewWithBlock:^(UITableView *tableView) {
        tableView.backgroundView = nil;
        tableView.backgroundColor = [UIColor colorWithRed:0.9294 green:0.9294 blue:0.9294 alpha:1.0];
        tableView.tableFooterView = [UIView new];
        tableView.tableFooterView.frame = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), 1.0f / [UIScreen mainScreen].scale);
        tableView.tableFooterView.backgroundColor = [UIColor colorWithRed:0.8078 green:0.8078 blue:0.8078 alpha:1.0];
    }];

    [downloaderManagerContainerViewController setDownloadedOtherActionBlock:
     ^(HJMDownloaderManagerTableViewController *downloaderManagerTableViewController, HJMCDDownloadItem *downloadItem) {
    }];
}

@end
