//
//  HJMFragmentCallBackModel.m
//  Pods
//
//  Created by lchen on 22/06/2017.
//
//

#import "HJMFragmentCallBackModel.h"

@implementation HJMFragmentCallBackModel

- (instancetype)initWithIdentifier:(NSString *)identifier delegate:(id<HJMFragmentsDownloadManagerDelegate>)delegate {
    if (self = [super init]) {
        self->_identifier = identifier;
        self->_delegate = delegate;
    }
    return self;
}

@end
