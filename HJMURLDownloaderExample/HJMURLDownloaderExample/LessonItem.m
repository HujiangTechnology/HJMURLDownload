//
//  LessonItem.m
//  HJMURLDownloaderExample
//
//  Created by Dong Han on 12/30/14.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import "LessonItem.h"

@implementation LessonItem

@synthesize task,status, isIgnoreResumeDataAfterCancel;

- (NSSearchPathDirectory)searchPathDirectory {
    return NSDocumentDirectory;
}

@end
