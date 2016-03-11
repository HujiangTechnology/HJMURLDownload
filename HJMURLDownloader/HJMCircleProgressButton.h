//
//  HJMCircleProgressButton.h
//  HJMURLDownloader
//
//  Created by Yozone Wang on 15/1/12.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HJMCircleProgressButton : UIButton

/**
 *  进度
 */
@property (assign, nonatomic) CGFloat progress;

/**
 *  初始化方法
 *
 *  @param frame button的frame
 *
 *  @return button
 */
+ (instancetype)circleProgressButtonWithFrame:(CGRect)frame;

- (void)setTrackTintColor:(UIColor *)tintColor;
- (void)setLineWidth:(CGFloat)lineWidth;

@end

