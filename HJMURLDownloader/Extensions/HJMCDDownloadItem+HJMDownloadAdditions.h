//
//  HJMCDDownloadItem+HJMDownloadAdditions.h
//  HJMURLDownloader
//
//  Created by Yozone Wang on 14/12/30.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import "HJMCDDownloadItem.h"

@interface HJMCDDownloadItem (HJMDownloadAdditions)

/**
 *  根据指定的 identifier 找到相应的 HJMCDDownloadItem
 *
 *  @param identifier 指定的 identifier
 *
 *  @return  如果找到则返回相应的 HJMCDDownloadItem，否则返回 nil
 */
+ (instancetype)downloadItemForIdentifier:(NSString *)identifier
                                   userID:(NSInteger)userID;

/**
 *  在指定的 NSManagedObjectContext 中，根据指定的 identifier 找到相应的 HJMCDDownloadItem
 *
 *  @param identifier 指定的 identifier
 *  @param context    指定的 NSManagedObjectContext
 *
 *  @return 如果找到则返回相应的 HJMCDDownloadItem，否则返回 nil
 */
+ (instancetype)downloadItemForIdentifier:(NSString *)identifier
                                   userID:(NSInteger)userID
                                inContext:(NSManagedObjectContext *)context;

- (NSString *)sectionName;

- (NSString *)fullPath;

@end
