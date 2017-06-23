//
//  AppDelegate.m
//  HJMURLDownloaderExample
//
//  Created by Dong Han on 12/23/14.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import "AppDelegate.h"
#import <HJMURLDownload.h>
#import <HJMURLDownloader/HJMDownloadCoreDataManager.h>
#import "HJMURLDownloaderInstance.h"
#import <HJMURLDownloader/HJMFragmentsDownloadManager.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [HJMURLDownloaderInstance sharedInstance];
    [HJMFragmentsDownloadManager defaultManager];
    return YES;
}
// iOS 7
- (void)application:(UIApplication *)anApplication handleEventsForBackgroundURLSession:(NSString *)aBackgroundURLSessionIdentifier completionHandler:(void (^)())aCompletionHandler
{
    [[HJMURLDownloaderInstance sharedInstance] addCompletionHandler:aCompletionHandler forSession:aBackgroundURLSessionIdentifier];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [HJMDownloadCoreDataManager saveContext];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [HJMDownloadCoreDataManager saveContext];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [HJMDownloadCoreDataManager saveContext];
}

@end
