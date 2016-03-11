//
//  HJMCircleProgressButton.m
//  HJMURLDownloader
//
//  Created by Yozone Wang on 15/1/12.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import "HJMCircleProgressButton.h"

@interface HJMCircleProgressButton ()

@property (strong, nonatomic) CAShapeLayer *trackLayer;
@property (strong, nonatomic) CAShapeLayer *progressLayer;

@end

@implementation HJMCircleProgressButton

+ (instancetype)circleProgressButtonWithFrame:(CGRect)frame {
    HJMCircleProgressButton *circleProgressButton = [[HJMCircleProgressButton alloc] initWithFrame:frame];
    return circleProgressButton;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _trackLayer = [CAShapeLayer layer];
        _trackLayer.frame = self.bounds;
        _trackLayer.path = [UIBezierPath bezierPathWithOvalInRect:_trackLayer.bounds].CGPath;
        _trackLayer.lineWidth = 1.0f;
        
        _trackLayer.strokeColor = [UIColor colorWithRed:0.8549
                                                  green:0.8549
                                                   blue:0.8549
                                                  alpha:1.0].CGColor;
        
        _trackLayer.fillColor = [UIColor clearColor].CGColor;
        _trackLayer.contentsScale = [UIScreen mainScreen].scale;
        [self.layer addSublayer:_trackLayer];
        
        _progressLayer = [CAShapeLayer layer];
        _progressLayer.frame = self.bounds;
        UIBezierPath *progressPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetMidX(_progressLayer.bounds), CGRectGetMidY(_progressLayer.bounds))
                                                                    radius:MIN(CGRectGetWidth(_progressLayer.bounds), CGRectGetHeight(_progressLayer.bounds)) * 0.5f
                                                                startAngle:-M_PI_2
                                                                  endAngle:2.0f * M_PI - M_PI_2
                                                                 clockwise:YES];
        
        _progressLayer.path = progressPath.CGPath;
        _progressLayer.lineWidth = 1.0f;
        _progressLayer.strokeColor = self.tintColor.CGColor;
        _progressLayer.fillColor = [UIColor clearColor].CGColor;
        _progressLayer.contentsScale = [UIScreen mainScreen].scale;
        _progressLayer.strokeStart = -0.25f;
        [self.layer addSublayer:_progressLayer];
    }
    return self;
}

- (void)setProgress:(CGFloat)progress {
    _progress = progress;
    self.progressLayer.strokeEnd = progress;
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    self.progressLayer.strokeColor = self.tintColor.CGColor;
}

- (void)setTrackTintColor:(UIColor *)tintColor {
    self.trackLayer.strokeColor = tintColor.CGColor;
}

- (void)setLineWidth:(CGFloat)lineWidth {
    self.trackLayer.lineWidth = lineWidth;
    self.progressLayer.lineWidth = lineWidth;
}

@end
