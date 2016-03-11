//
//  NSManagedObject+Additions.m
//  HJMURLDownloader
//
//  Created by Yozone Wang on 14/12/25.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import "NSManagedObject+Additions.h"
#import "HJMDownloadCoreDataManager.h"

@implementation NSManagedObject (Additions)

+ (instancetype)findFirstByAttribute:(NSString *)attribute
                           withValue:(id)value
                           forUserID:(NSInteger)userID {
    
    return [self findFirstByAttribute:attribute
                            withValue:value
                            forUserID:userID
                            inContext:[HJMDownloadCoreDataManager mainManagedObjectContext]];
    
}

+ (instancetype)findFirstByAttribute:(NSString *)attribute
                           withValue:(id)value
                           forUserID:(NSInteger)userID
                           inContext:(NSManagedObjectContext *)context {
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass(self)];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@ AND (userID = 0 OR userID = %d)", attribute, value, userID];
    request.predicate = predicate;
    request.fetchLimit = 1;
    NSArray *results = [context executeFetchRequest:request error:nil];
    return [results lastObject];
}


@end
