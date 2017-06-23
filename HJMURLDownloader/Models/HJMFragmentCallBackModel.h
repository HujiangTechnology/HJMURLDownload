//
//  HJMFragmentCallBackModel.h
//  Pods
//
//  Created by lchen on 22/06/2017.
//
//

@protocol HJMFragmentsDownloadManagerDelegate;

#import <Foundation/Foundation.h>

@interface HJMFragmentCallBackModel : NSObject

- (instancetype)initWithIdentifier:(NSString *)identifier delegate:(id<HJMFragmentsDownloadManagerDelegate>)delegate;

@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, weak, readonly) id<HJMFragmentsDownloadManagerDelegate> delegate;

@end
