//
//  HJMCDDownloadItem.h
//  HJMURLDownloader
//
//  Created by Yozone Wang on 15/1/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface HJMCDDownloadItem : NSManagedObject

@property (nonatomic, retain) NSNumber * averageSpeed;
@property (nonatomic, retain) NSString * category;
@property (nonatomic, retain) NSDate * categoryCreatedAt;
@property (nonatomic, retain) NSString * categoryID;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSNumber * downloadedSize;
@property (nonatomic, retain) NSString * downloadURLString;
@property (nonatomic, retain) NSDate * finishedAt;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * progress;
@property (nonatomic, retain) NSData * resumeData;
@property (nonatomic, retain) NSString * sessionIdentifier;
@property (nonatomic, retain) NSDate * startAt;
@property (nonatomic, retain) NSNumber * state;
@property (nonatomic, retain) NSNumber * sortIndex;
@property (nonatomic, retain) NSString * targetPath;
@property (nonatomic, retain) NSString * taskDescription;
@property (nonatomic, retain) NSNumber * taskIdentifier;
@property (nonatomic, retain) NSNumber * totalSize;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) id userInfo;
@property (nonatomic, retain) NSNumber * isMultipleExistedWithAnonymous;
@property (nonatomic, retain) NSNumber * isNewDownload;
@property (nonatomic, retain) NSNumber * userID;
@property (nonatomic, retain) NSNumber * searchPathDirectory;

@end
