//
//  HJMFragmentDBManager.m
//  Pods
//
//  Created by lchen on 21/06/2017.
//
//

#import "HJMFragmentDBManager.h"
#import <FMDB/FMDB.h>

@interface HJMFragmentDBManager ()

@property (nonatomic, strong) FMDatabaseQueue *databaseQueue;

@end

@implementation HJMFragmentDBManager
static HJMFragmentDBManager *manager;

+ (NSString *)filePath {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *sqlPath = [path stringByAppendingPathComponent:@"com.hujiang.fragmentDownload.sqlite"];
    NSLog(@"sql path %@", sqlPath);
    return sqlPath;
}

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[HJMFragmentDBManager alloc] init];
    });
    return manager;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [super allocWithZone:zone];
    });
    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
        self.databaseQueue = [FMDatabaseQueue databaseQueueWithPath:[[self class] filePath]];
    }
    return self;
}

- (void)createTableWithName:(NSString *)tableName {
    [self.databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sqlString = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(\
                               id INTEGER PRIMARY KEY NOT NULL,\
                               url TEXT,\
                               md5String VARCHAR(255),\
                               fired BOOLEAN);", tableName];
        BOOL createSuccess = [db executeUpdate:sqlString];
        if (!createSuccess) {
            [db rollback];
        }
    }];
}

- (NSArray <M3U8SegmentInfo *> *)fragmentsModelWithCount:(NSInteger)count tableName:(NSString *)tableName {
    __block NSMutableArray <M3U8SegmentInfo *> *fragments = [NSMutableArray array];
    [self.databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sqlString = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE fired = %@ ORDER BY id ASC LIMIT %ld", tableName, @(NO), count];
        FMResultSet *resultSet = nil;
        resultSet = [db executeQuery:sqlString];
        while ([resultSet next]) {
            int index = [resultSet intForColumn:@"id"];
            NSString *url = [resultSet stringForColumn:@"url"];
            NSString *md5String = [resultSet stringForColumn:@"md5String"];
            M3U8SegmentInfo *fragment = [[M3U8SegmentInfo alloc] init];
            fragment.index = index;
            fragment.mediaURLString = url;
            fragment.md5String = md5String;
            [fragments addObject:fragment];
        }
        [resultSet close];
    }];
    
    for (M3U8SegmentInfo *fragment in fragments) {
        [self markFragmentModelFiredWithIdentifier:fragment.md5String inTable:tableName];
    }
    
    return fragments;
}

- (M3U8SegmentInfo *)oneMoreFragmentModelInTable:(NSString *)tableName {
    __block M3U8SegmentInfo *fragmentModel = [[M3U8SegmentInfo alloc] init];
    [self.databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sqlString = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE fired = %@ ORDER BY id ASC LIMIT 1", tableName, @(NO)];
        FMResultSet *resultSet = nil;
        resultSet = [db executeQuery:sqlString];
        if ([resultSet next]) {
            int index = [resultSet intForColumn:@"id"];
            NSString *url = [resultSet stringForColumn:@"url"];
            NSString *md5String = [resultSet stringForColumn:@"md5String"];
            fragmentModel.index = index;
            fragmentModel.mediaURLString = url;
            fragmentModel.md5String = md5String;
        }
        [resultSet close];
    }];
    [self markFragmentModelFiredWithIdentifier:fragmentModel.md5String inTable:tableName];
    return fragmentModel;
}

- (void)insertFragmentModelArray:(NSMutableArray <M3U8SegmentInfo *> *)fragmentModels toTable:(NSString *)tableName {
    [self.databaseQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        [fragmentModels enumerateObjectsUsingBlock:^(M3U8SegmentInfo * _Nonnull fragmentModel, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *sqlString = [NSString stringWithFormat:@"INSERT INTO %@(id, url, md5String, fired) VALUES (?, ?, ?, ?)", tableName];
            [db executeUpdate:sqlString, @(fragmentModel.index), fragmentModel.mediaURLString, fragmentModel.md5String, @(NO)];
        }];
    }];
}

- (void)markFragmentModelFiredWithIdentifier:(NSString *)fragmentIdentifier inTable:(NSString *)tableName {
    [self.databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sqlString = [NSString stringWithFormat:@"UPDATE %@ SET fired = %@ WHERE md5String = '%@'",tableName, @(YES), fragmentIdentifier];
        [db executeUpdate:sqlString];
    }];
}

- (void)removeFragmentModelCompletedWithIdentifier:(NSString *)fragmentIdentifier inTable:(NSString *)tableName {
    [self.databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sqlString = [NSString stringWithFormat:@"DELETE FROM %@ WHERE md5String = \"%@\"", tableName, fragmentIdentifier];
        [db executeUpdate:sqlString];
    }];
}

- (NSInteger)leftRowCountInTable:(NSString *)tableName {
    __block NSInteger count = 0;
    [self.databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sqlString = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@", tableName];
       count = [db intForQuery:sqlString];
    }];
    return count;
}

- (NSInteger)pendingRowCountInTable:(NSString *)tableName {
    __block NSInteger count = 0;
    [self.databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sqlString = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE fired = %@", tableName, @(NO)];
        count = [db intForQuery:sqlString];
    }];
    return count;
}

- (BOOL)isTableExist:(NSString *)tableName {
    __block BOOL isExist = NO;
    [self.databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        isExist = [db tableExists:tableName];
    }];
    return isExist;
}

- (void)dropTable:(NSString *)tableName {
    [self.databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sqlString = [NSString stringWithFormat:@"DROP TABLE IF EXISTS %@", tableName];
        [db executeUpdate:sqlString];
    }];
}


@end
