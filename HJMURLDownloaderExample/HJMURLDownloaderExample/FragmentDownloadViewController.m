//
//  FragmentDownloadViewController.m
//  HJMURLDownloaderExample
//
//  Created by lchen on 24/06/2017.
//  Copyright © 2017 HJ. All rights reserved.
//

#import "FragmentDownloadViewController.h"
#import <HJMURLDownloader/HJMFragmentsDownloadManager.h>
#import <HJMURLDownloader/M3U8Parser.h>

@interface FragmentDownloadViewController () <HJMFragmentsDownloadManagerDelegate>

@property (nonatomic, strong) NSArray *identifierArray;
@property (nonatomic, strong) NSMutableArray *labelArray;
@property (nonatomic, strong) NSMutableArray *buttonArray;

@end

@implementation FragmentDownloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.identifierArray = @[@"aaaaaaa", @"bbbbbb", @"ccccccc"];
    self.labelArray = [NSMutableArray array];
    self.buttonArray = [NSMutableArray array];
    [self setupUI];
}

- (void)setupUI {
    NSArray *titleArray = @[@"开始下载", @"开始下载", @"开始下载", @"删除文件一", @"删除文件二", @"删除文件三"];
    for (int i = 0; i < titleArray.count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.tag = i;
//        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        button.layer.borderWidth = 1.0f;
        button.layer.borderColor = [UIColor blackColor].CGColor;
        [button setTitle:titleArray[i] forState:UIControlStateNormal];
        CGRect rect = CGRectMake(20.0f, 80.0f + 50.0f * i, 100.0f, 30.0f);
        button.frame = rect;
        [button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
        
        UILabel *label = [[UILabel alloc] init];
        label.frame = CGRectMake(170.0f, 80.0f + 50.0f * i, 250.0f, 30.0f);
        label.tag = i;
        [self.view addSubview:label];
        [self.labelArray addObject:label];
        [self.buttonArray addObject:button];
    }
}

- (UILabel *)labelWithIdentifier:(NSString *)identifier {
    NSInteger index = [self.identifierArray indexOfObject:identifier];
    for (int i = 0; i < self.labelArray.count; i++) {
        if (index == i) {
            return [self.labelArray objectAtIndex:i];
        }
    }
    return nil;
}

- (UIButton *)buttonWithIdentifier:(NSString *)identifier {
    NSInteger index = [self.identifierArray indexOfObject:identifier];
    for (int i = 0; i < self.labelArray.count; i++) {
        if (index == i) {
            return [self.labelArray objectAtIndex:i];
        }
    }
    return nil;
}

- (void)buttonClicked:(UIButton *)button {
    switch (button.tag) {
        case 0:
        case 1:
        case 2:
            // 下载带有不同标示的任务
            if ([button.titleLabel.text isEqualToString:@"停止下载"]) {
                [self stopTaskWithIndex:button.tag];
            } else {
                [self downloadTaskWithIndex:button.tag];
            }
            break;
        case 3:
        case 4:
        case 5:
            // 删除
            [self deleteFragemntListWithIndex:button.tag];
            break;
        default:
            break;
    }
}

- (void)downloadTaskWithIndex:(NSInteger)index {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"localM3u8" ofType:@"txt"];
    NSString *m3u8String = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    M3U8SegmentInfoList *m3u8InfoList = [M3U8Parser m3u8SegmentInfoListFromPlanString:m3u8String];
    m3u8InfoList.segmentInfoList = [NSMutableArray arrayWithArray:[m3u8InfoList.segmentInfoList subarrayWithRange:NSMakeRange(0, 10)]];
    m3u8InfoList.identifier = self.identifierArray[index];
    [[HJMFragmentsDownloadManager defaultManager] downloadFragmentList:m3u8InfoList delegate:self];
    [[self.buttonArray objectAtIndex:index] setTitle:@"停止下载" forState:UIControlStateNormal];
}

- (void)stopTaskWithIndex:(NSInteger)index {
    NSString *identifier = self.identifierArray[index];
    [[HJMFragmentsDownloadManager defaultManager] stopDownloadFragmentListWithIdentifier:identifier];
    [[self.buttonArray objectAtIndex:index] setTitle:@"开始下载" forState:UIControlStateNormal];
}

- (void)deleteFragemntListWithIndex:(NSInteger)index {
    NSString *identifier = self.identifierArray[index % 3];
    [[HJMFragmentsDownloadManager defaultManager] deleteFragemntListWithIdentifier:identifier];
}

#pragma mark - HJMFragmentsDownloadManagerDelegate

- (void)downloadTaskAddedToQueueWithIdentifer:(NSString *)identifier {
    NSLog(@"add to queue");
    [self labelWithIdentifier:identifier].text = @"add to queue";
}

- (void)downloadTaskBeginWithIdentifier:(NSString *)identifier {
    NSLog(@"task begin: identifier :%@", identifier);
    [self labelWithIdentifier:identifier].text = [NSString stringWithFormat:@"task begin: identifier :%@", identifier];
}

- (void)downloadTaskReachProgress:(CGFloat)progress identifier:(NSString *)identifier {
    NSLog(@"download progress : %f  identifier :%@", progress, identifier);
    [self labelWithIdentifier:identifier].text = [NSString stringWithFormat:@"download progress : %f  identifier :%@", progress, identifier];
}

- (void)downloadTaskCompleteWithDirectoryPath:(NSString *)directoryPath identifier:(NSString *)identifier {
    NSLog(@"download success with path : %@", directoryPath);
    [self labelWithIdentifier:identifier].text = [NSString stringWithFormat:@"download success with path : %@", directoryPath];
}

- (void)downloadTaskCompleteWithError:(NSError *)error identifier:(NSString *)identifier {
    NSLog(@"download failed with error : %@", error);
    [self labelWithIdentifier:identifier].text = [NSString stringWithFormat:@"download failed with error : %@", error];
}

- (void)fragmentSaveToDiskFailedWithIdentifier:(NSString *)identifier {
    NSLog(@"save failed");
    [self labelWithIdentifier:identifier].text = [NSString stringWithFormat:@"save failed"];
}

- (void)allFragmentListsHaveRunOut {

}

@end
