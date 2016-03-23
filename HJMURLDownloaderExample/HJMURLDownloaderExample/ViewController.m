//
//  ViewController.m
//  HJMURLDownloaderExample
//
//  Created by Dong Han on 12/23/14.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import "ViewController.h"
#import "HJMURLDownloaderInstance.h"
#import "LessonItem.h"
#import "HJMZipWrapper.h"

@interface ViewController () <HJMURLDownloadManagerDelegate, HJMURLDownloadHandlerDelegate>
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *percentageLabel;
@property (weak, nonatomic) IBOutlet UILabel *remaningTimeLabel;
@property (strong, nonatomic) IBOutlet UISwitch *wifiSwitch;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (assign, nonatomic) NSInteger index;

@property (strong, nonatomic) NSString *lessonPath;
@property (strong, nonatomic) LessonItem *aLesson;
@property (strong, nonatomic) NSMutableArray *lessonsArray;

@property (nonatomic) BOOL isSimpleTask;
@property (strong, nonatomic) NSString *originURLString;

@end

@implementation ViewController

#pragma mark 

- (void)downloadURLDownloadItemWillRecover:(id<HJMURLDownloadExItem>)item {
}

- (IBAction)changeSwitch:(id)sender {
    UISwitch *networkSwitch = sender;
    [[NSNotificationCenter defaultCenter] postNotificationName:kHJMURLDownloaderOnlyWiFiAccessNotification object:@(networkSwitch.on)];
}

- (NSArray *)lessonsArray {
    if (!_lessonsArray) {
        _lessonsArray = [NSMutableArray array];
    }
    return _lessonsArray;
}

#pragma mark HJMURLDownloadManagerDelegate

- (BOOL)downloadTaskShouldHaveEnoughFreeSpace:(long long)expectedData {
    return YES;
}

- (void)downloadTaskDidFinishWithDownloadItem:(id<HJMURLDownloadExItem>)downloadObject completionBlock:(void (^)(void))block {
    HJMZipWrapper *zipWrapper = [[HJMZipWrapper alloc] init];
    zipWrapper.archivePath = [downloadObject fullPath];
    zipWrapper.targetPath = [[zipWrapper.archivePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"lesson"];

    [zipWrapper unzipFileWithProgress:^(HJMZipWrapper *unzipWrapper, CGFloat progress) {

    } complete:^(HJMZipWrapper *unzipWrapper) {
        BOOL isDir;
        NSFileManager *fm = [NSFileManager defaultManager];
        if (![fm fileExistsAtPath:zipWrapper.targetPath isDirectory:&isDir] && isDir) {
            [fm createDirectoryAtPath:zipWrapper.targetPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        // 删除已下载文件
        [[NSFileManager defaultManager] removeItemAtPath:unzipWrapper.archivePath error:nil];

        // 跳过iCloud备份

        //
        block();

    } failure:^(HJMZipWrapper *unzipWrapper, NSError *error) {
        // 删除已下载文件
        [[NSFileManager defaultManager] removeItemAtPath:unzipWrapper.archivePath error:nil];

        block();
    }];
}

- (HJMURLDownloadManager *)downloadManager {
    if (!_downloadManager) {
        _downloadManager = [HJMURLDownloaderInstance sharedInstance].downloadManager;
        _downloadManager.delegate = self;
    }

    return _downloadManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    self.isSimpleTask = NO;
    self.originURLString = @"http://mov.bn.netease.com/mobilev/open/nos/mp4/2015/03/02/SAIOUJR73_sd.mp4";

    self.index = 1;

    [self.downloadManager addNotificationHandler:self];
    self.downloadManager.delegate = self;
    
    self.wifiSwitch.on = self.downloadManager.isOnlyWiFiAccess;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self recoverUI];
}

- (void)recoverUI {
    id<HJMURLDownloadExItem> item = [self.downloadManager getAURLDownloadWithIdentifier:self.originURLString];
    if (item) {
        self.progressView.progress = item.downloadProgress;
        self.percentageLabel.text = [NSString stringWithFormat:@"%.f%%", item.downloadProgress * 100];
    }
}

- (void)resetUI {
    self.progressView.progress = 0.0;
    self.remaningTimeLabel.text = @"当前速度:";
    self.percentageLabel.text = @"0%";
}

- (LessonItem *)createALessonItem {
    LessonItem *aLesson = [[LessonItem alloc] init];
    __weak __typeof(&*self)weakSelf = self;
    aLesson.progressBlock = ^(float progress, int64_t totalLength, NSInteger seconds, float speed) {
        weakSelf.progressView.progress = progress;
        weakSelf.percentageLabel.text = [NSString stringWithFormat:@"%.f%%", progress * 100];
        weakSelf.remaningTimeLabel.text = [NSString stringWithFormat:@"当前速度: %.fkb/s", speed / 1024];
    };

    aLesson.remoteURL = [NSURL URLWithString:self.originURLString];

    [self.lessonsArray addObject:aLesson];

    NSString *downloadfilename = [NSString stringWithFormat:@"lesson%@.zip", @(self.index++)];
    aLesson.relativePath = downloadfilename;

    //TODO: RecoverUI more clear
    aLesson.identifier = self.originURLString;
    //[NSString stringWithFormat:@"1232333334111112333%@", @(self.index)];
    aLesson.title = [downloadfilename stringByDeletingPathExtension];
    aLesson.category = [NSString stringWithFormat:@"Category %d", arc4random() % 4];

    return aLesson;
}

- (IBAction)pressDownloadButton:(id)sender {
    if (self.isSimpleTask) {
        __weak __typeof(&*self)weakSelf = self;
        [self.downloadManager addDownloadWithURL:[NSURL URLWithString:self.originURLString] progress:^(float progress, int64_t totalLength, NSInteger remainingTime, float speed) {
            weakSelf.progressView.progress = progress;
            weakSelf.percentageLabel.text = [NSString stringWithFormat:@"%.f%%", progress * 100];
            weakSelf.remaningTimeLabel.text = [NSString stringWithFormat:@"当前速度: %.fkb/s", speed / 1024];
        } complete:^(BOOL completed, NSURL *didFinishDownloadingToURL) {
            NSLog(@"Download done");
        }];
    } else {
        [self.downloadManager addURLDownloadItem:[self createALessonItem]];
    }
}

- (IBAction)pressCancelButton:(id)sender {
    if (self.isSimpleTask) {
        [self.downloadManager cancelAURLDownloadWithIdentifier:self.originURLString];
    } else {
        [self.downloadManager cancelAURLDownloadItem:[self.lessonsArray firstObject]];
    }
    self.index--;
}

- (IBAction)pressDeleteButton:(id)sender {
    [self.downloadManager deleteAllDownloads];
    [self resetUI];
}

- (IBAction)pressCrashButton:(id)sender {
    NSArray *anArray = [NSArray array];
    id test = [anArray objectAtIndex:123456789];
}

@end
