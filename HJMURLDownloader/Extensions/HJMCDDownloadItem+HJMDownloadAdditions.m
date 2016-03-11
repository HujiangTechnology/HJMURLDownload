//
//  HJMCDDownloadItem+HJMDownloadAdditions.m
//  HJMURLDownloader
//
//  Created by Yozone Wang on 14/12/30.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import "HJMCDDownloadItem+HJMDownloadAdditions.h"
#import "NSManagedObject+Additions.h"

@implementation HJMCDDownloadItem (HJMDownloadAdditions)

+ (instancetype)downloadItemForIdentifier:(NSString *)identifier
                                   userID:(NSInteger)userID {
    
    return [self findFirstByAttribute:@"identifier"
                            withValue:identifier
                            forUserID:userID];
}

+ (instancetype)downloadItemForIdentifier:(NSString *)identifier
                                   userID:(NSInteger)userID
                                inContext:(NSManagedObjectContext *)context {
    
    return [self findFirstByAttribute:@"identifier"
                            withValue:identifier
                            forUserID:userID
                            inContext:context];
    
}

- (NSString *)sectionName {
    return self.category ?: @"";
}

- (NSString *)fullPath {
    
    NSSearchPathDirectory searchPathDirectory = (NSSearchPathDirectory)[self.searchPathDirectory unsignedIntegerValue];
    if (searchPathDirectory == kNilOptions) {
        return self.targetPath;
    }
    NSString *mainPath = [NSSearchPathForDirectoriesInDomains(searchPathDirectory, NSUserDomainMask, YES) lastObject];
    return [mainPath stringByAppendingPathComponent:self.targetPath];
}

- (void)awakeFromInsert {
    [super awakeFromInsert];
    self.createdAt = [NSDate date];
}

- (void)willSave {
    [super willSave];
    [self setPrimitiveValue:[NSDate date] forKey:@"updatedAt"];
}

@end
