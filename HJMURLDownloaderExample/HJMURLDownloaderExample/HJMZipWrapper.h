//
//  HJMZipWrapper.h
//  HJMURLDownloaderExample
//
//  Created by HJ Mobile on 13-7-8.
//  Copyright (c) 2016 HJ. All rights reserved.
//

@import Foundation;
@import UIKit;

@class HJMZipWrapper;

typedef void(^HJMUnzipProcessBlock)(HJMZipWrapper * unzipWrapper, CGFloat progress);
typedef void(^HJMUnzipCompleteBlock)(HJMZipWrapper * unzipWrapper);
typedef void(^HJMUnzipFailureBlock)(HJMZipWrapper * unzipWrapper, NSError * error);

@interface HJMZipWrapper : NSObject

@property (strong, nonatomic) id associatedObject;
@property (strong, nonatomic) NSString * password;
@property (strong, nonatomic) NSString * archivePath;
@property (strong, nonatomic) NSString * targetPath;
@property (strong, nonatomic) NSDictionary * userInfo;
@property (nonatomic,assign) float progress;

- (id)init;
- (void)unzipFileWithProgress:(HJMUnzipProcessBlock)progressBlock complete:(HJMUnzipCompleteBlock)completeBlock failure:(HJMUnzipFailureBlock)failureBlock;

@end
