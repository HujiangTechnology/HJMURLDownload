//
//  HJMFragmentDBManager.h
//  Pods
//
//  Created by lchen on 21/06/2017.
//
//

#import <Foundation/Foundation.h>
#import "M3U8SegmentInfo.h"
#import "HJMURLDownloadExItem.h"

@interface HJMFragmentDBManager : NSObject

+ (instancetype)sharedManager;

- (void)createTableWithName:(NSString *)tableName;

- (M3U8SegmentInfo *)oneMoreFragmentModelInTable:(NSString *)tableName;

- (void)insertFragmentModelArray:(NSArray <HJMURLDownloadExItem> *)fragmentModels toTable:(NSString *)tableName;

- (void)removeFragmentModel:(id<HJMURLDownloadExItem>)fragmentModel inTable:(NSString *)tableName;

- (NSInteger)rowCountInTable:(NSString *)tableName;

- (BOOL)isTableExist:(NSString *)tableName;

- (void)dropTable:(NSString *)tableName;

@end
