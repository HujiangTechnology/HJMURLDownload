//
//  HJMSpaceInformationView.h
//  HJMURLDownloader
//
//  Created by Yozone Wang on 15/1/19.
//
//

#import <UIKit/UIKit.h>

@interface HJMSpaceInformationView : UIView

@property (assign, nonatomic) NSUInteger precision;
@property (assign, nonatomic) CGFloat progress;
@property (strong, readonly, nonatomic) UILabel *informationLabel;

- (void)reloadSpaceInformation;

@end
