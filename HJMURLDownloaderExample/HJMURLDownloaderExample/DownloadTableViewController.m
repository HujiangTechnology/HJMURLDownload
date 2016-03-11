//
//  DownloadTableViewController.m
//  HJMURLDownloaderExample
//
//  Created by Dong Han on 12/24/14.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import "DownloadTableViewController.h"

@interface DownloadTableViewController()
@property (strong, nonatomic) NSArray *downloadsArray;
@end

@implementation DownloadTableViewController

- (void)viewDidLoad {
    self.downloadsArray = @[@1, @2, @3, @4, @5];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.downloadsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    return cell;
}




@end
