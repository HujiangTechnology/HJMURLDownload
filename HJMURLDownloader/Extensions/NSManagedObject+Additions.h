//
//  NSManagedObject+Additions.h
//  HJMURLDownloader
//
//  Created by Yozone Wang on 14/12/25.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (Additions)

/**
 *  根据制定的属性名和属性值找到对应的 NSManagedObject，默认的 NSManagedObjectContext 为 HJMDownloadCoreDataManager 的 mainManagedObjectContext
 *
 *  @param attribute 属性名
 *  @param value     属性值
 *
 *  @return 相应的 NSManagedObject，如果是 nil 说明没有找到
 */
+ (instancetype)findFirstByAttribute:(NSString *)attribute
                           withValue:(id)value
                           forUserID:(NSInteger)userID;

/**
 *  在指定的 NSManagedObjectContext 中，根据制定的属性名和属性值找到对应的 NSManagedObject
 *
 *  @param attribute 属性名
 *  @param value     属性值
 *  @param context    指定的 NSManagedObjectContext
 *
 *  @return 相应的 NSManagedObject，如果是 nil 说明没有找到
 */
+ (instancetype)findFirstByAttribute:(NSString *)attribute
                           withValue:(id)value
                           forUserID:(NSInteger)userID
                           inContext:(NSManagedObjectContext *)context;


@end
