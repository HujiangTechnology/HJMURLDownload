# 简介

- 基于 NSURLSession，支持多任务、后台下载、断点续传
- 采用 CoreData 存储下载数据，并提供了一套下载管理界面，显示下载中和已下载的任务
- 使用Protocol扩展下载信息，提供了 Delegate 和 Block 两种回调方式，便于替换到现有项目
- 处理了较多的异常情况，例如用户手动将后台 app 杀掉后第二次启动的逻辑

# 介绍文章

[iOS 通用下载管理器-HJMURLDownloader](http://mobilev5.github.io/2016/03/13/meeting-common-urldownloader/)

# 运行 Demo

$ cd HJMURLDownloaderExample  
$ pod install   
$ open HJMURLDownloaderExample.xcworkspace  

# 使用

建议使用 Cocoapods 集成到项目中

``` pod 'HJMURLDownloader' ```

## HJMURLDownloadManager

### 初始化和创建下载

````objc 
/**
 *  单例方法
 */
+ (instancetype)defaultManager;

/**
 *  创建普通下载器，不支持后台下载，默认不限制网络
 *
 *  @param aMaxConcurrentFileDownloadsCount 最大并发数
 */
- (instancetype)initStandardDownloaderWithMaxConcurrentDownloads:(NSInteger)aMaxConcurrentFileDownloadsCount;

/**
 *  创建后台下载器，
 *
 *  @param identifier                       唯一标识，建议identifier命名为 bundleid.XXXXBackgroundDownloader,
 *  @param aMaxConcurrentFileDownloadsCount 最大并发数
 *  @param OnlyWiFiAccess                   是否仅WiFi环境下载
 */
- (instancetype)initBackgroundDownloaderWithIdentifier:(NSString *)identifier maxConcurrentDownloads:(NSInteger)aMaxConcurrentFileDownloadsCount OnlyWiFiAccess:(BOOL)isOnlyWiFiAccess;
````

### AppDelegate相关配置

````objc 
- (void)application:(UIApplication *)anApplication handleEventsForBackgroundURLSession:(NSString *)aBackgroundURLSessionIdentifier completionHandler:(void (^)())aCompletionHandler
{
// 后台使用Background downloader 两种情况
// 1. 默认使用单例
    [[HJMURLDownloaderInstance sharedInstance] addCompletionHandler:aCompletionHandler forSession:aBackgroundURLSessionIdentifier];
// 2. 使用自己创建的downloader
    [[CCBookDownloader sharedDownloader] getDownloadManager] addCompletionHandler:aCompletionHandler forSession:aBackgroundURLSessionIdentifier];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    //保存本次下载状态
    [HJMDownloadCoreDataManager saveContext];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [HJMDownloadCoreDataManager saveContext];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [HJMDownloadCoreDataManager saveContext];
}
```

### delegate 方法

````objc 
/**
 *  是否有足够的磁盘空间
 *
 *  @param expectedData 需要的磁盘空间
 *
 *  @return 如果为YES 说明有足够的空间存储目标文件
 */
- (BOOL)downloadTaskShouldHaveEnoughFreeSpace:(long long)expectedData;

/**
 *  完成下载任务后的回调方法
 *
 *  @param item  下载任务模型对象
 *  @param block 完成后的回调Block
 */
 @optional
- (void)downloadTaskDidFinishWithDownloadItem:(id<HJMURLDownloadExItem>)item
                              completionBlock:(void (^)(void))block;
```

### 添加和取消下载操作

````objc 
/**
 *  基本添加和取消操作
 *
 *  @param url           下载文件的URL
 *  @param progressBlock 下载进度Block   Block内回传下载进度，文件总长度，剩余时间
 *  @param completeBlock 完成后回调Block Block内回传完成后的文件的沙盒路径，是否完成状态
 */
- (void)addDownloadWithURL:(NSURL *)url
                  progress:(HJMURLDownloadProgressBlock)progressBlock
                  complete:(HJMURLDownloadCompletionBlock)completeBlock;

/**
 *  增加下载任务
 *
 *  @param downloadItem 下载对象模型
 */
- (void)addURLDownloadItem:(id<HJMURLDownloadExItem>)downloadItem;

/**
 *  获取下载任务信息
 *
 *  @param identifier 下载对象的identifier
 */
- (id<HJMURLDownloadExItem>)getAURLDownloadWithIdentifier:(NSString *)identifier;

/**
 *  取消下载任务
 *
 *  @param downloadItem 下载对象模型
 */
- (void)cancelAURLDownloadItem:(id<HJMURLDownloadExItem>)downloadItem;

/**
 *  取消下载任务
 *
 *  @param identifier 下载对象的identifier
 */
- (void)cancelAURLDownloadWithIdentifier:(NSString *)identifier;

/**
 *  取消所有下载任务
 */
- (void)cancelALLDownloads;
```

### 单任务下载示例

##### 初始化操作

````objc 
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static id sharedManager = nil;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] initWithMaxConcurrentDownloads:1 isSupportBackgroundMode:YES];
    });
    return sharedManager;
}
```

##### 创建下载任务

````objc 
        [self.downloadManager addDownloadWithURL:[NSURL URLWithString:self.originURLString] progress:^(float progress, int64_t totalLength, NSInteger remainingTime) {
		//	获取progress totalLength remainingTime
		//	UI展示等操作
        } complete:^(BOOL completed, NSURL *didFinishDownloadingToURL) {
        //	完成时的操作，didFinishDownloadingToURL为下载的文件在本地的沙盒路径
        }];
```

##### 实现代理方法

````objc 
- (BOOL)downloadTaskShouldHaveEnoughFreeSpace:(long long)expectedData {
    return YES;
}

- (void)downloadTaskDidFinishWithDownloadItem:(id<HJMURLDownloadExItem>)downloadObject completionBlock:(void (^)(void))block {

    ..........................
    //文件处理
    ..........................

    //调用block，下载队列中的任务进行下一个
        block(); 
}


```

##### 取消下载

````objc 
	[self.downloadManager cancelAURLDownloadWithIdentifier:self.originURLString];


```

### 多任务下载示例

##### 初始化操作

````objc 
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static id sharedManager = nil;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] initWithMaxConcurrentDownloads:1
                                             isSupportBackgroundMode:YES];
    });
    return sharedManager;
}
```

##### 初始化遵循HJMURLDownloadExItem协议的实例，配置对应属性值

````objc
- (LessonItem *)createALessonItem {

    LessonItem *aLesson = [[LessonItem alloc] init];
    __weak __typeof(&*self)weakSelf= self;

    aLesson.progressBlock = ^(float progress, int64_t totalLength, NSInteger seconds) {
    ..........................

        //	获取progress totalLength remainingTime
		//	UI展示等操作 
    ..........................		
    };

    aLesson.completionBlock = ^(BOOL completed, NSURL *didFinishDownloadingToURL) {
    ..........................    
        //	完成时的操作，didFinishDownloadingToURL为下载的文件在本地的沙盒路径
    ..........................            
    };
    aLesson.remoteURL = [NSURL URLWithString:@"http://a.ali.dongting.com/fccaa2a98849bfbc/1427606533/mp3_128_300/24/75/24812476f5df9d9cdcbc90beddc05a75.mp3"];

    aLesson.relativePath = [[aLesson.remoteURL absoluteString] lastPathComponent];
	[self.lessonsArray addObject:aLesson];
	
    aLesson.identifier = aLesson.remoteURL;
    aLesson.title = [downloadfilename stringByDeletingPathExtension];
    aLesson.category = [NSString stringWithFormat:@"Category %d", arc4random() % 4];

    return aLesson;
}
```

##### 创建下载任务

````objc 
	[self.downloadManager addURLDownloadItem:[self createALessonItem]];
```

##### 实现代理方法

````objc 
- (BOOL)downloadTaskShouldHaveEnoughFreeSpace:(long long)expectedData {
    return YES;
}

- (void)downloadTaskDidFinishWithDownloadItem:(id<HJMURLDownloadExItem>)downloadObject completionBlock:(void (^)(void))block {

    ..........................
    //文件处理
    ..........................

    //调用block，下载队列中的任务进行下一个
        block();  
}


```

##### 取消下载

````objc 
	[self.downloadManager cancelAURLDownloadItem:[self.lessonsArray firstObject]];

```

---

## HJMDownloaderManagerContainerViewController

### 属性

````objc 
 /**
 *  获得下载管理器同步UI显示
 */
 @property (strong, nonatomic) HJMURLDownloadManager *downloadManager;   // 下载管理器
 @property (assign, nonatomic) NSInteger userID;                         // 用户标识
 @property (strong, nonatomic) UIColor *segmentedControlTintColor;       // segmentControl的颜色

```

### 设置下载完成后点击播放调用的方法

````objc 
/**
 *  点击下载完成的cell的progressButton触发的动作
 *
 *  @param otherActionBlock 回调Block
 */
- (void)setDownloadedOtherActionBlock:(void(^)(HJMDownloaderManagerTableViewController *downloaderManagerTableViewController, HJMCDDownloadItem *downloadItem))otherActionBlock;
```

### 使用示例

##### 初始化设置

````objc 
HJMDownloaderManagerContainerViewController *downloaderManagerContainerViewController = 
(HJMDownloaderManagerContainerViewController *)navigationController.topViewController;

    [downloaderManagerContainerViewController setSegmentedControlTintColor:[UIColor colorWithRed:0.141
                                                                                           green:0.553
                                                                                            blue:0.886
                                                                                           alpha:1.000]];

    downloaderManagerContainerViewController.downloadManager = viewController.downloadManager;
    ..................................
    部分用户自定义设置
    ..................................
```

##### 设置下载完成的 block

````objc 
    [downloaderManagerContainerViewController setDownloadedOtherActionBlock:
     ^(HJMDownloaderManagerTableViewController *downloaderManagerTableViewController, HJMCDDownloadItem *downloadItem) {


    }];
```

### 用户自定义设置

````objc 
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
 *  刷新页面（内部调用TableView的reloadData）
 */
- (void)reloadDownloadData;

```

# 作者
[hiessu](https://github.com/hiessu) & [azone](https://github.com/azone) 

# 待做
- [ ] KVO 检测 NSURLSessionDownloadTask 状态
- [ ] 支持 NSProgress
- [ ] 优化 CoreData 存储逻辑
- [ ] 处理其他错误状态

# 感谢

本项目参考并借鉴 [HWIFileDownload](https://github.com/Heikowi/HWIFileDownload) 和 [TCBlobDownload](https://github.com/thibaultCha/TCBlobDownload)，在此表示感谢   
