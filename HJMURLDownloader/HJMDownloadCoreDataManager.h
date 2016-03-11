//
//  HJMDownloadCoreDataManager.h
//  HJMURLDownloader
//
//  Created by Yozone Wang on 14/12/24.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "HJMURLDownloadExItem.h"

@class HJMURLDownloadObject;
@class HJMCDDownloadItem;

DISPATCH_EXPORT dispatch_queue_t hjm_coredata_queue();
extern NSString * const HJMCDDownloadItemDidInsertedNotification;
extern NSString * const HJMCDDownloadItemDidIsNewDownloadPropertyUpdatedNotification;
extern NSString * const HJMCDDownloadItemDidDeletedNotification;

@interface HJMDownloadCoreDataManager : NSObject

@property (assign, nonatomic) NSInteger userID;

+ (void)saveContext;

/**
*  主的 NSManagedObjectContext，由于操作比较简单所以只暴露一个主的 NSManagedObjectContext，用于查询和检测 HJMCDDownloadItem 的变化
*  如果需要对 HJMCDDownloadItem 进行操作请用 - (void)performBlock:onCompletion:，插入建议用 - (void)performBlockAndWait:
*
*  @return mainManagedObjectContext
*/
+ (NSManagedObjectContext *)mainManagedObjectContext;

/**
*  用作更新
*
*  @param block 更新时执行的 block，不会阻碍线程
*/
- (void)performBlock:(void (^)(NSManagedObjectContext *context))block
        onCompletion:(void (^)(BOOL success, NSError *error))completionBlock;

/**
*  用作插入
*
*  @param block 插入时执行的 block，会阻碍线程，插入后在主的 NSManagedObjectContext 能立即得到插入的对象，用 performBlock:onCompletion: 会有延时
*/
- (void)performBlockAndWait:(void(^)(NSManagedObjectContext *context))block;

/**
*  判断 HJMURLDownloadObject 关联的 HJMCDDownloadItem 是否存在
*
*  @param downloadObject HJMURLDownloadObject 对象
*
*  @return YES 说明已经存在，NO 说明不存在
*/
- (BOOL)downloadItemExistsForDownloadObject:(HJMURLDownloadObject *)downloadObject;

/**
*  判断与 identifier 相应的 HJMCDDownloadItem 是否存在
*
*  @param identifier identifier
*
*  @return YES 说明已经存在，NO 说明不存在
*/
- (BOOL)downloadItemExistsForIdentifier:(NSString *)identifier;

/**
*  根据 HJMURLDownloadObject 插入新的 HJMCDDownloadItem，如果已经存在则不会重复创建
*
*  @param downloadObject HJMURLDownloadObject 对象
*/
- (void)insertNewDownloadItemWithDownloadObject:(HJMURLDownloadObject *)downloadObject;

/**
*  根据 HJMURLDownloadObject 更新 HJMCDDownloadItem，如果它们之间没有关联，会重新建立联系
*
*  @param downloadObject HJMURLDownloadObject 对象
*  @param resumeData     恢复下载用到的数据
*/
- (void)updateDownloadItemWithDownloadObject:(HJMURLDownloadObject *)downloadObject andResumeData:(NSData *)resumeData;

/**
*  通过 block 来更 HJMCDDownloadItem 更新对象，防止不在一个线程更新造成死锁
*
*  @param downloadItem 其他线程传入的 HJMCDDownloadItem
*  @param updateBlock  转化成写入线程来更新 HJMCDDownloadItem 的 block
*/
- (void)updateDownloadItem:(HJMCDDownloadItem *)downloadItem
                 withBlock:(void(^)(HJMCDDownloadItem *aDownloadItem))updateBlock;

/**
*  根据唯一标示符删除相应的 HJMCDDownloadItem
*
*  @param identifier       唯一标示符
*/
- (void)deleteDownloadItemWithIdentifier:(NSString *)identifier;

- (void)deleteDownloadItem:(HJMCDDownloadItem *)downloadItem;

/**
*  用异步方法（iOS 8+）获取等待下载的列表
*
*  @param completionBlock 获取成功后的回调
*/
- (void)fetchAllDownloadItemsForStatus:(HJMURLDownloadStatus)status
                             withBlock:(void(^)(NSArray *fetchedItems))completionBlock;

- (void)fetchAllDownloadItemsForCategoryID:(id)categoryID
                                 withBlock:(void(^)(NSArray *fetchedItems))completionBlock;

- (NSDate *)createdDateForCategory:(NSString *)category;

- (NSUInteger)countDownloadedItemsWithPredicate:(NSPredicate *)predicate;

- (NSUInteger)countDownloadingItemsWithPredicate:(NSPredicate *)predicate;

- (NSUInteger)countUnreadDownloadedItemsWithPredicate:(NSPredicate *)predicate;

@end
