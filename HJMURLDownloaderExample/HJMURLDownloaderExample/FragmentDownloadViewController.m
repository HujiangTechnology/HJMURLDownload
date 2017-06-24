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

@end

@implementation FragmentDownloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.identifierArray = @[@"aaaaaaa", @"bbbbbb", @"ccccccc"];
    [self setupUI];
}

- (void)setupUI {
    NSArray *titleArray = @[@"下载任务一", @"下载任务二", @"下载任务三", @"停止下载", @"恢复下载"];
    for (int i = 0; i < titleArray.count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = i;
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        button.layer.borderWidth = 1.0f;
        button.layer.borderColor = [UIColor blackColor].CGColor;
        [button setTitle:titleArray[i] forState:UIControlStateNormal];
        CGRect rect = CGRectMake(20.0f, 80.0f + 50.0f * i, 150.0f, 30.0f);
        button.frame = rect;
        [button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
    }
}

- (void)buttonClicked:(UIButton *)button {
    switch (button.tag) {
        case 0:
        case 1:
        case 2:
            // 下载带有不同标示的任务
            [self downloadTaskWithIndex:button.tag];
            break;
        case 3:
            [self stopTask];
            break;
        case 4:
            // 恢复下载带有不同标示的任务
            [self resumeTaskWithIndex:button.tag];
            break;
        case 5:
            break;
        default:
            break;
    }
}

- (void)downloadTaskWithIndex:(NSInteger)index {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"localM3u8" ofType:@"txt"];
    NSString *m3u8String = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    M3U8SegmentInfoList *m3u8InfoList = [M3U8Parser m3u8SegmentInfoListFromPlanString:m3u8String];
    m3u8InfoList.identifier = self.identifierArray[index];
    [[HJMFragmentsDownloadManager defaultManager] downloadFragmentList:m3u8InfoList delegate:self];
}

- (void)stopTask {

}

- (void)resumeTaskWithIndex:(NSInteger)index {

}

#pragma mark - HJMFragmentsDownloadManagerDelegate

- (BOOL)downloadTaskShouldHaveEnoughFreeSpace:(long long)expectedData {
    return YES;
}

/**
 当前有任务正在下载，新添加的下载任务被加入到队列中，等待前面的任务完成再开始
 
 @param identifier 加入队列等待的任务的唯一标示，接入方应该能够通过这个标示找到对应的任务
 */
- (void)downloadTaskAddedToQueueWithIdentifer:(NSString *)identifier {
    NSLog(@"%s", __func__);
}

/**
 通知代理，任务已经开始下载了
 
 @param identifier 任务标示
 */
- (void)downloadTaskBeginWithIdentifier:(NSString *)identifier {
    NSLog(@"%s", __func__);
}

/**
 下载的任务完成进度，任务中的每一个fragment下载完成会回调一次该方法
 
 @param progress 完成进度 下载完成的fragment的个数／总个数
 @param identifier 任务标示
 */
- (void)downloadTaskReachProgress:(CGFloat)progress identifier:(NSString *)identifier {
    NSLog(@"%s", __func__);
}

/**
 任务下载完成，自动下载队列中的下一个任务
 
 @param directoryPath 任务中所有的fragments保存的文件夹
 @param identifier 任务标示
 */
- (void)downloadTaskCompleteWithDirectoryPath:(NSString *)directoryPath identifier:(NSString *)identifier {
    NSLog(@"%s", __func__);
}

/**
 任务经过重试(如有)，下载失败，自动下载队列中的下一个任务
 
 @param error 出错信息
 @param identifier 任务标示
 */
- (void)downloadTaskCompleteWithError:(NSError *)error identifier:(NSString *)identifier {
    NSLog(@"%s", __func__);
}


@end
