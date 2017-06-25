//
//  HJMFragmentProducer.m
//  Pods
//
//  Created by lchen on 21/06/2017.
//
//

#import "HJMFragmentDBManager.h"
#import "HJMFragmentProducer.h"
#import "HJMFragmentsDownloadManager.h"

@interface HJMFragmentProducer ()

@property (nonatomic, strong) NSMutableArray <M3U8SegmentInfoList *> *pendingFragmentListArray;
@property (nonatomic, assign) NSInteger currentFragmentArrayCount;
@property (nonatomic, strong) HJMFragmentDBManager *dbManager;

@end

@implementation HJMFragmentProducer

- (instancetype)init {
    if (self = [super init]) {
        self.pendingFragmentListArray = [NSMutableArray array];
        self.dbManager = [HJMFragmentDBManager sharedManager];
    }
    return self;
}

- (BOOL)isTableExistInDatabaseWithIdentifier:(NSString *)identifier {
    return [self.dbManager isTableExist:identifier];
}

- (M3U8SegmentInfoList *)nextFragmentList {
    M3U8SegmentInfoList *list = [self.pendingFragmentListArray firstObject];
    if (list) {
        // 到这里说明要下载下一个队列了，将队列写入数据库
        self.currentFragmentArrayCount = list.segmentInfoList.count;
        self->_currentDownloadingIdentifier = list.identifier;
        [self insertFragmentArrayToDatabase:list];
        self.currentFragmentArrayCount = list.segmentInfoList.count;
        // 已经入库，将它从pending array中移除
        [self.pendingFragmentListArray removeObject:list];
    } else {
        // 没有队列了
        if ([self.delegate respondsToSelector:@selector(allFragmentListsHaveRunOut)]) {
            [self.delegate allFragmentListsHaveRunOut];
        }
        self.currentFragmentArrayCount = 0;
        self->_currentDownloadingIdentifier = nil;
    }
    return list;
}

- (NSInteger)leftFragmentCountWithIdentifier:(NSString *)identifier {
    return [self.dbManager leftRowCountInTable:identifier];
}

- (NSInteger)totalCountForCurrentFragmentList {
    return self.currentFragmentArrayCount;
}

- (void)addFragmentsArray:(M3U8SegmentInfoList *)fragmentArray {
    [self.pendingFragmentListArray addObject:fragmentArray];
}

- (void)removePendingFragmentArrayWithIdentifier:(NSString *)identifier {
    M3U8SegmentInfoList *listToRemove = nil;
    for (M3U8SegmentInfoList *fragmentList in self.pendingFragmentListArray) {
        if ([fragmentList.identifier isEqualToString:identifier]) {
            listToRemove = fragmentList;
        }
    }
    if (listToRemove) {
        [self.pendingFragmentListArray removeObject:listToRemove];
    }
}

- (NSArray <M3U8SegmentInfo *> *)fragmentsWithOriginalArray:(M3U8SegmentInfoList *)originalArray limitedCount:(NSInteger)limitedCount {
    // 到这里表示开始下载了 ，既然开始下载，就应该把整个队在数据库中做记录
    self.currentFragmentArrayCount = originalArray.segmentInfoList.count;
    self->_currentDownloadingIdentifier = originalArray.identifier;

    [self insertFragmentArrayToDatabase:originalArray];
    
    // 从数据库中拿数据给返回给manager
    NSArray *fragmentsToDownload = [self.dbManager fragmentsModelWithCount:limitedCount tableName:originalArray.identifier];
    if (fragmentsToDownload.count == 0) {
        self.currentFragmentArrayCount = 0;
        self->_currentDownloadingIdentifier = nil;
        [self.delegate fragmentListHasRunOutWithIdentifier:originalArray.identifier];
    }
    return fragmentsToDownload;
}

- (M3U8SegmentInfo *)oneMoreFragmentWithIdentifier:(NSString *)identifier {
    if ([self.dbManager pendingRowCountInTable:identifier]) {
        return [self.dbManager oneMoreFragmentModelInTable:identifier];
    } else if ([self.dbManager leftRowCountInTable:identifier] == 0) {
        [self.delegate fragmentListHasRunOutWithIdentifier:identifier];
        [self.dbManager dropTable:identifier];
        self.currentFragmentArrayCount = 0;
        self->_currentDownloadingIdentifier = nil;
    }
    return nil;
}

- (void)removeCompletedFragmentFromDBWithIdentifier:(NSString *)identifier {
    [self.dbManager removeFragmentModelCompletedWithIdentifier:identifier inTable:self.currentDownloadingIdentifier];
}

- (void)markFragmentFiredInDatabaseWithFragmentIdentifier:(NSString *)fragmentIdentifer identifier:(NSString *)identifier {
    [self.dbManager markFragmentModelFiredWithIdentifier:fragmentIdentifer inTable:identifier];
}

- (void)insertFragmentArrayToDatabase:(M3U8SegmentInfoList *)fragmentList {
    if (![self.dbManager isTableExist:fragmentList.identifier]) {
        // 没有这个表，以identifier为表名，将所有的下载队列记录进表
        [self.dbManager createTableWithName:fragmentList.identifier];
        [self.dbManager insertFragmentModelArray:fragmentList.segmentInfoList toTable:fragmentList.identifier];
        // 已经将数组入库，将它从pending array中移除
        [self removePendingArrayWithIdentifier:fragmentList.identifier];
    }
}

- (void)removePendingArrayWithIdentifier:(NSString *)identifier {
    M3U8SegmentInfoList *itemShouldRemove = nil;
    for (M3U8SegmentInfoList *fragmentList in self.pendingFragmentListArray) {
        if ([fragmentList.identifier isEqualToString:identifier]) {
            itemShouldRemove = fragmentList;
            break;
        }
    }
    if (itemShouldRemove) {
        [self.pendingFragmentListArray removeObject:itemShouldRemove];
    }
}

- (void)deleteFragemntListWithIdentifier:(NSString *)identifier {
    [self.dbManager dropTable:identifier];
}

@end
