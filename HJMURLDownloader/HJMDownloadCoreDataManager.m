//
//  HJMDownloadCoreDataManager.m
//  HJMURLDownloader
//
//  Created by Yozone Wang on 14/12/24.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import "HJMDownloadCoreDataManager.h"
#import "HJMCDDownloadItem.h"
#import "HJMURLDownloadObject.h"
#import "NSManagedObject+Additions.h"
#import "HJMCDDownloadItem+HJMDownloadAdditions.h"

NSString * const HJMCDDownloadItemDidInsertedNotification = @"com.hujiang.hjmdownload.HJMCDDownloadItemDidInsertedNotification";
NSString * const HJMCDDownloadItemDidIsNewDownloadPropertyUpdatedNotification = @"com.hujiang.hjmdownload.HJMCDDownloadItemDidIsNewDownloadPropertyUpdatedNotification";
NSString * const HJMCDDownloadItemDidDeletedNotification = @"com.hujiang.hjmdownload.HJMCDDownloadItemDidDeletedNotification";

static void * const kHJMCoreDataQueueContextKey = (void *)&kHJMCoreDataQueueContextKey;

dispatch_queue_t hjm_coredata_queue() {
    static dispatch_queue_t hjm_coredata_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *bundleIdentifier = [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey];
        hjm_coredata_queue = dispatch_queue_create([[bundleIdentifier stringByAppendingString:@".hjmdownloader-coredata-queue"] UTF8String], DISPATCH_QUEUE_SERIAL);
        void *nonNullValue = kHJMCoreDataQueueContextKey;
        dispatch_queue_set_specific(hjm_coredata_queue, kHJMCoreDataQueueContextKey, nonNullValue, NULL);
    });
    return hjm_coredata_queue;
}

@interface HJMDownloadCoreDataManager ()

@end

@implementation HJMDownloadCoreDataManager

+ (NSManagedObjectContext *)mainManagedObjectContext {
    static NSManagedObjectContext *mainContext;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [mainContext performBlockAndWait:^{
            [mainContext setParentContext:[self rootManagedObjectContext]];
        }];
    });
    return mainContext;
}

+ (NSManagedObjectContext *)rootManagedObjectContext {
    static NSManagedObjectContext *rootContext;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void(^setRootManagedObjectContext)(void) = ^{
            rootContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            rootContext.mergePolicy = [[NSMergePolicy alloc] initWithMergeType:NSMergeByPropertyObjectTrumpMergePolicyType];
            [rootContext performBlockAndWait:^{
                rootContext.persistentStoreCoordinator = [self persistentStoreCoordinator];
            }];
        };
        if (dispatch_get_specific(kHJMCoreDataQueueContextKey) != NULL) {
            setRootManagedObjectContext();
        } else {
            dispatch_sync(hjm_coredata_queue(), setRootManagedObjectContext);
        }
    });
    return rootContext;
}

+ (void)saveContext {
    NSManagedObjectContext *mainManagedObjectContext = [self mainManagedObjectContext];
    NSManagedObjectContext *rootContext = [self rootManagedObjectContext];
    if (![mainManagedObjectContext hasChanges] && ![rootContext hasChanges]) {
        return;
    }
    [mainManagedObjectContext performBlockAndWait:^{
        NSError * __block saveError;
        BOOL __block success = [mainManagedObjectContext save:&saveError];
        if (!success) {
            NSLog(@"Main Manmanged Object Context Save Error: %@ - %@", saveError.localizedDescription, saveError.userInfo);
        }
        [rootContext performBlock:^{
            success = [rootContext save:&saveError];
            if (!success) {
                NSLog(@"Root Manmanged Object Context Save Error: %@ - %@", saveError.localizedDescription, saveError.userInfo);
            }
        }];
    }];
}

- (NSManagedObjectContext *)createManagedObjectContextWithParent:(NSManagedObjectContext *)parentContext {
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.parentContext = parentContext;
    return context;
}

- (void)performBlock:(void (^)(NSManagedObjectContext *context))block
        onCompletion:(void (^)(BOOL success, NSError *error))completionBlock {

    NSManagedObjectContext *parentManagedObjectContext = [[self class] mainManagedObjectContext];
    NSManagedObjectContext *context = [self createManagedObjectContextWithParent:parentManagedObjectContext];
    [context performBlock:^{
        block(context);
        if ([context hasChanges]) {
            NSError *error;
            if ([context.insertedObjects count] > 0) {

                [context obtainPermanentIDsForObjects:[context.insertedObjects allObjects]
                                                error:nil];
            }
            BOOL success = [context save:&error];

            [parentManagedObjectContext performBlock:^{
                if ([parentManagedObjectContext hasChanges]) {
                    [parentManagedObjectContext save:nil];
                }
                if (completionBlock) {
                    completionBlock(success, error);
                }
            }];
        } else {
            if (completionBlock) {
                completionBlock(YES, nil);
            }
        }
    }];
}

- (void)performBlockAndWait:(void (^)(NSManagedObjectContext *context))block {

    NSManagedObjectContext *parentManagedObjectContext = [[self class] mainManagedObjectContext];
    NSManagedObjectContext *context = [self createManagedObjectContextWithParent:parentManagedObjectContext];
    [context performBlockAndWait:^{
        block(context);
        if ([context.insertedObjects count] > 0) {
            [context obtainPermanentIDsForObjects:[context.insertedObjects allObjects] error:nil];
        }
        if ([context hasChanges]) {
            [context save:nil];
        }
        if ([parentManagedObjectContext hasChanges]) {
            [parentManagedObjectContext performBlockAndWait:^{
                [parentManagedObjectContext save:nil];
            }];
        }
    }];
}

+ (NSURL *)storeURL {

    static NSURL *storeURL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        storeURL = [[self downloaderDirectoryURL] URLByAppendingPathComponent:@"HJMDownloader.sqlite"];
    });
    return storeURL;
}

+ (NSPersistentStoreCoordinator *)persistentStoreCoordinator {

    static NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSURL *storeURL = [self storeURL];
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *managedObjectModelURL = [bundle URLForResource:@"HJMDownloader" withExtension:@"momd"];
    NSManagedObjectModel *MOM = [[NSManagedObjectModel alloc] initWithContentsOfURL:managedObjectModelURL];

    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:MOM];
    NSDictionary *storeOptions = @{
            NSMigratePersistentStoresAutomaticallyOption: @YES,
            NSInferMappingModelAutomaticallyOption: @YES
    };
    NSError *addStoreError;
    NSPersistentStore *store = [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                        configuration:nil
                                                                                  URL:storeURL
                                                                              options:storeOptions
                                                                                error:&addStoreError];
    if (!store) {
        NSLog(@"Add Store Error - %@", addStoreError);
        abort();
    }

    return persistentStoreCoordinator;
}

+ (NSURL *)applicationSupportURL {
    static NSURL *applicationSupportURL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        applicationSupportURL = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory
                                                                       inDomain:NSUserDomainMask
                                                              appropriateForURL:nil
                                                                         create:YES
                                                                          error:nil];

    });
    return applicationSupportURL;
}

+ (NSURL *)downloaderDirectoryURL {
    static NSURL *downloaderDirectoryURL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        downloaderDirectoryURL = [[self applicationSupportURL] URLByAppendingPathComponent:@"HJMDownloader"];
        NSFileManager *fm = [NSFileManager defaultManager];
        BOOL isDir = YES;
        if (![fm fileExistsAtPath:[downloaderDirectoryURL path] isDirectory:&isDir] && isDir) {

            [fm createDirectoryAtURL:downloaderDirectoryURL
         withIntermediateDirectories:YES
                          attributes:nil
                               error:nil];
        }
        [downloaderDirectoryURL setResourceValue:@YES
                                          forKey:NSURLIsExcludedFromBackupKey
                                           error:nil];
    });
    return downloaderDirectoryURL;
}

- (BOOL)downloadItemExistsForDownloadObject:(HJMURLDownloadObject *)downloadObject {
    return [self downloadItemExistsForIdentifier:downloadObject.identifier];
}

- (BOOL)downloadItemExistsForIdentifier:(NSString *)identifier {
    return [HJMCDDownloadItem downloadItemForIdentifier:identifier userID:self.userID] != nil;
}

- (void)insertNewDownloadItemWithDownloadObject:(id<HJMURLDownloadExItem>)downloadObject {

    NSDate *categoryCreatedAt = [self createdDateForCategory:downloadObject.category];
    [self performBlockAndWait:^(NSManagedObjectContext *context) {

        HJMCDDownloadItem *downloadItem = [HJMCDDownloadItem findFirstByAttribute:@"identifier"
                                                                        withValue:downloadObject.identifier
                                                                        forUserID:self.userID
                                                                        inContext:context];
        if (!downloadItem) {
            downloadItem = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([HJMCDDownloadItem class])
                                                         inManagedObjectContext:context];

        }

        downloadItem.name = downloadObject.title;
        downloadItem.category = downloadObject.category;
        downloadItem.categoryCreatedAt = categoryCreatedAt ?: [NSDate date];
        downloadItem.downloadURLString = [downloadObject.remoteURL absoluteString];
        downloadItem.downloadedSize = @(downloadObject.receivedFileSizeInBytes);
        downloadItem.totalSize = @(downloadObject.expectedFileSizeInBytes);
        downloadItem.identifier = downloadObject.identifier;
        downloadItem.userInfo = downloadObject.userInfo;
        if (downloadObject.task) {
            downloadItem.taskIdentifier = @(downloadObject.task.taskIdentifier);
            downloadItem.taskDescription = downloadObject.task.taskDescription;
        }
        downloadItem.searchPathDirectory = @(downloadObject.searchPathDirectory);
        downloadItem.targetPath = downloadObject.relativePath;
        downloadItem.progress = @(downloadObject.downloadProgress);
        downloadItem.averageSpeed = @(downloadObject.averageSpeed);
        downloadItem.state = @(downloadObject.status) ?: @0;
        // TODO: 关联用户 ID
        downloadItem.userID = @(downloadObject.userID);
        downloadItem.categoryID = downloadObject.categoryID;
        downloadItem.sortIndex = @(downloadObject.sortIndex);
        downloadObject.downloadItemObjectID = downloadItem.objectID;
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:HJMCDDownloadItemDidInsertedNotification object:nil];
}

- (void)updateDownloadItem:(HJMCDDownloadItem *)downloadItem
                 withBlock:(void (^)(HJMCDDownloadItem *aDownloadItem))updateBlock {
    BOOL __block didIsNewPropertyChanged = NO;
    [self performBlock:^(NSManagedObjectContext *context) {
        if (downloadItem.objectID) {
            HJMCDDownloadItem *localDownloadItem = (HJMCDDownloadItem *)[context existingObjectWithID:downloadItem.objectID error:nil];
            updateBlock(localDownloadItem);
            didIsNewPropertyChanged = [localDownloadItem changedValues][@"isNewDownload"] != nil;
        }

    }     onCompletion:^(BOOL success, NSError *error) {
        if (didIsNewPropertyChanged) {
            [[self class] saveContext];
            [[NSNotificationCenter defaultCenter] postNotificationName:HJMCDDownloadItemDidIsNewDownloadPropertyUpdatedNotification object:nil];
        }
    }];
}

- (void)updateDownloadItemWithDownloadObject:(HJMURLDownloadObject *)downloadObject andResumeData:(NSData *)resumeData {
    BOOL __block shouldSave = NO;
    [self performBlockAndWait:^(NSManagedObjectContext *context) {
        HJMCDDownloadItem *downloadItem;
        if (!downloadObject.downloadItemObjectID || [downloadObject.downloadItemObjectID isTemporaryID]) {

            downloadItem = [HJMCDDownloadItem findFirstByAttribute:@"identifier"
                                                         withValue:downloadObject.identifier
                                                         forUserID:self.userID
                                                         inContext:context];

            downloadObject.downloadItemObjectID = downloadItem.objectID;
        } else {
            downloadItem = (HJMCDDownloadItem *) [context existingObjectWithID:downloadObject.downloadItemObjectID error:nil];
        }
        downloadItem.name = downloadObject.title;
        downloadItem.downloadedSize = @(downloadObject.receivedFileSizeInBytes);
        downloadItem.userInfo = downloadObject.userInfo;
        downloadItem.taskIdentifier = @(downloadObject.task.taskIdentifier);
        downloadItem.taskDescription = downloadObject.task.taskDescription;
        downloadItem.progress = @(downloadObject.downloadProgress);
        downloadItem.averageSpeed = @(downloadObject.averageSpeed);
        downloadItem.state = @(downloadObject.status);
        downloadItem.resumeData = resumeData;
        downloadItem.totalSize = @(downloadObject.expectedFileSizeInBytes);
        downloadItem.targetPath = downloadObject.relativePath;
        if (!downloadItem.startAt) {
            downloadItem.startAt = [NSDate date];
        }
        if (downloadObject.status == HJMURLDownloadStatusSucceeded) {
            downloadItem.finishedAt = [NSDate date];
            downloadItem.isNewDownload = @YES;
            shouldSave = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:HJMCDDownloadItemDidIsNewDownloadPropertyUpdatedNotification object:nil];
        }
        if (resumeData.length > 0) {
            shouldSave = YES;
        }
    }];
    if (shouldSave) {
        [[self class] saveContext];
    }
}

- (void)deleteDownloadItemWithIdentifier:(NSString *)identifier {
    HJMCDDownloadItem *downloadItem = [HJMCDDownloadItem findFirstByAttribute:@"identifier"
                                                                    withValue:identifier
                                                                    forUserID:self.userID
                                                                    inContext:[[self class] mainManagedObjectContext]];
    [self deleteDownloadItem:downloadItem];
}

- (void)deleteDownloadItem:(HJMCDDownloadItem *)downloadItem {

    if (downloadItem.objectID) {
        [self performBlock:^(NSManagedObjectContext *context) {
            HJMCDDownloadItem *localDownloadItem = (HJMCDDownloadItem *)[context existingObjectWithID:downloadItem.objectID error:nil];
            if (localDownloadItem) {
                [context deleteObject:localDownloadItem];
            }
        }     onCompletion:^(BOOL success, NSError *error) {
            [[self class] saveContext];
            [[NSNotificationCenter defaultCenter] postNotificationName:HJMCDDownloadItemDidDeletedNotification object:nil];
        }];
    }
}

- (void)fetchAllDownloadItemsForStatus:(HJMURLDownloadStatus)status
                             withBlock:(void (^)(NSArray *fetchedItems))completionBlock{

    NSManagedObjectContext *context = [[self class] mainManagedObjectContext];
    [context performBlock:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"HJMCDDownloadItem"];
        fetchRequest.sortDescriptors = @[
                [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES]
        ];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"state = %d AND ((userID = 0 AND (isMultipleExistedWithAnonymous = NO OR isMultipleExistedWithAnonymous = nil)) OR userID = %d)", status, self.userID];
        if (NSClassFromString(@"NSAsynchronousFetchRequest")) {
            NSAsynchronousFetchRequest *asynchronousFetchRequest = [[NSAsynchronousFetchRequest alloc] initWithFetchRequest:fetchRequest
                                                                                                            completionBlock:^(NSAsynchronousFetchResult *result) {
                                                                                                                completionBlock(result.finalResult);
                                                                                                            }];

            [context executeRequest:asynchronousFetchRequest
                              error:nil];
        } else {

            NSArray *results = [context executeFetchRequest:fetchRequest
                                                      error:nil];
            completionBlock(results);
        }
    }];
}

- (void)fetchAllDownloadItemsForCategoryID:(id)categoryID
                                 withBlock:(void (^)(NSArray *fetchedItems))completionBlock {

    NSManagedObjectContext *context = [[self class] mainManagedObjectContext];
    [context performBlock:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"HJMCDDownloadItem"];
        fetchRequest.sortDescriptors = @[
                [NSSortDescriptor sortDescriptorWithKey:@"createdAt"
                                              ascending:YES]
        ];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"categoryID = %@ AND ((userID = 0 AND (isMultipleExistedWithAnonymous = NO OR isMultipleExistedWithAnonymous = nil)) OR userID = %d)", categoryID, self.userID];
        if (NSClassFromString(@"NSAsynchronousFetchRequest")) {
            NSAsynchronousFetchRequest *asynchronousFetchRequest = [[NSAsynchronousFetchRequest alloc] initWithFetchRequest:fetchRequest
                                                                                                            completionBlock:^(NSAsynchronousFetchResult *result) {
                                                                                                                completionBlock(result.finalResult);
                                                                                                            }];
            [context executeRequest:asynchronousFetchRequest
                              error:nil];
        } else {
            NSArray *results = [context executeFetchRequest:fetchRequest
                                                      error:nil];
            completionBlock(results);
        }
    }];
}

- (NSDate *)createdDateForCategory:(NSString *)category {
    NSManagedObjectContext *mainContext = [[self class] mainManagedObjectContext];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"HJMCDDownloadItem"];
    request.fetchLimit = 1;
    request.predicate = [NSPredicate predicateWithFormat:@"category = %@ AND userID = %d", category, self.userID];
    request.sortDescriptors = @[
            [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES]
    ];
    NSArray * __block result;
    if ([NSThread isMainThread]) {
        result = [mainContext executeFetchRequest:request
                                            error:nil];
    } else {
        [mainContext performBlockAndWait:^{
            result = [mainContext executeFetchRequest:request
                                                error:nil];
        }];
    }
    HJMCDDownloadItem *downloadItem = [result firstObject];
    return downloadItem.categoryCreatedAt;
}


- (NSUInteger)countDownloadedItemsWithPredicate:(NSPredicate *)predicate {

    NSUInteger __block count = 0;
    NSManagedObjectContext *mainContext = [[self class] mainManagedObjectContext];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"HJMCDDownloadItem"];
    NSPredicate *requestPredicate = [NSPredicate predicateWithFormat:@"state = %d AND ((userID = 0 AND (isMultipleExistedWithAnonymous = NO OR isMultipleExistedWithAnonymous = nil)) OR userID = %d)", HJMURLDownloadStatusSucceeded, self.userID];
    if (predicate) {
        requestPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[requestPredicate, predicate]];
    }
    request.predicate = requestPredicate;
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    if ([processInfo respondsToSelector:@selector(isOperatingSystemAtLeastVersion:)]) {
        NSOperatingSystemVersion minVersion = {.majorVersion=9, .minorVersion=0, .patchVersion=0};
        if ([processInfo isOperatingSystemAtLeastVersion:minVersion]) {
            if ([NSThread isMainThread]) {
                count = [mainContext countForFetchRequest:request
                                                    error:nil];
            } else {
                [mainContext performBlockAndWait:^{
                    count = [mainContext countForFetchRequest:request
                                                        error:nil];
                }];
            }
            return count;
        }
    }
    // iOS 9 一下有 bug，所以只能用这种效率低下的方法
    request.includesPropertyValues = NO;
    request.includesSubentities = NO;
    NSArray *array = [mainContext executeFetchRequest:request
                                                error:nil];
    count = [array count];

    return count;
}

- (NSUInteger)countDownloadingItemsWithPredicate:(NSPredicate *)predicate {

    NSUInteger __block count = 0;
    NSManagedObjectContext *mainContext = [[self class] mainManagedObjectContext];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"HJMCDDownloadItem"];
    NSPredicate *requestPredicate = [NSPredicate predicateWithFormat:@"state != %d AND ((userID = 0 AND (isMultipleExistedWithAnonymous = NO OR isMultipleExistedWithAnonymous = nil)) OR userID = %d)", HJMURLDownloadStatusSucceeded, self.userID];
    if (predicate) {
        requestPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[requestPredicate, predicate]];
    }
    request.predicate = requestPredicate;
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    if ([processInfo respondsToSelector:@selector(isOperatingSystemAtLeastVersion:)]) {
        NSOperatingSystemVersion minVersion = {.majorVersion=9, .minorVersion=0, .patchVersion=0};
        if ([processInfo isOperatingSystemAtLeastVersion:minVersion]) {
            if ([NSThread isMainThread]) {
                count = [mainContext countForFetchRequest:request
                                                    error:nil];
            } else {
                [mainContext performBlockAndWait:^{
                    count = [mainContext countForFetchRequest:request
                                                        error:nil];
                }];
            }
            return count;
        }
    }
    // iOS 9 一下有 bug，所以只能用这种效率低下的方法
    request.includesPropertyValues = NO;
    request.includesSubentities = NO;
    NSArray *array = [mainContext executeFetchRequest:request
                                                error:nil];
    count = [array count];
    
    return count;
}

- (NSUInteger)countUnreadDownloadedItemsWithPredicate:(NSPredicate *)predicate {
    NSPredicate *unreadPredicate = [NSPredicate predicateWithFormat:@"isNewDownload = YES"];
    if (predicate) {
        unreadPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[unreadPredicate, predicate]];
    }
    return [self countDownloadedItemsWithPredicate:unreadPredicate];
}


@end
