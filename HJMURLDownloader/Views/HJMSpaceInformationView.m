//
//  HJMSpaceInformationView.m
//  HJMURLDownloader
//
//  Created by Yozone Wang on 15/1/19.
//
//

#import "HJMSpaceInformationView.h"

@interface HJMSpaceInformationView ()

@property (strong, nonatomic) CAShapeLayer *progressLayer;
@property (strong, nonatomic) NSProgress *progressInfo;
@property (strong, readwrite, nonatomic) UILabel *informationLabel;
@property (strong, nonatomic) NSByteCountFormatter *byteCountFormatter;

@end

@implementation HJMSpaceInformationView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _progress = 0.0f;
        
        _progressLayer = [CAShapeLayer layer];
        _progressLayer.frame = self.bounds;
        _progressLayer.strokeColor = [UIColor clearColor].CGColor;
        _progressLayer.fillColor = self.tintColor.CGColor;
        _progressLayer.contentsScale = [UIScreen mainScreen].scale;
        _progressLayer.shouldRasterize = YES;
        [self.layer addSublayer:_progressLayer];
        
        _progressInfo = [[NSProgress alloc] initWithParent:nil userInfo:nil];
        
        _informationLabel = [[UILabel alloc] initWithFrame:CGRectInset(self.bounds,
                                                                       5.0f,
                                                                       0.0f)];
        
        _informationLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                             UIViewAutoresizingFlexibleHeight;
        
        _informationLabel.textAlignment = NSTextAlignmentRight;
        _informationLabel.font = [UIFont systemFontOfSize:CGRectGetHeight(self.bounds) * 0.9f];
        
        _informationLabel.textColor = [UIColor colorWithWhite:0.400
                                                        alpha:1.000];
        _informationLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:_informationLabel];

        _byteCountFormatter = [[NSByteCountFormatter alloc] init];
        _byteCountFormatter.countStyle = NSByteCountFormatterCountStyleFile;
        _byteCountFormatter.allowsNonnumericFormatting = NO;

        _precision = 1;
    }
    return self;
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    [self reloadSpaceInformation];
}

- (void)layoutSublayersOfLayer:(CALayer *)layer {
    [super layoutSublayersOfLayer:layer];
    
    self.progressLayer.frame = self.bounds;
    self.progressLayer.path = [UIBezierPath bezierPathWithRect:CGRectMake(0,
                                                                          0,
                                                                          CGRectGetWidth(self.bounds) * self.progress,
                                                                          CGRectGetHeight(self.bounds))].CGPath;
}

- (void)setProgress:(CGFloat)progress {
    if (progress < 0.0f) {
        progress = 0.0f;
    } else if (progress > 1.0f) {
        progress = 1.0f;
    }
    _progress = progress;
    self.progressLayer.path = [UIBezierPath bezierPathWithRect:CGRectMake(0,
                                                                          0,
                                                                          CGRectGetWidth(self.bounds) * progress,
                                                                          CGRectGetHeight(self.bounds))].CGPath;
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    _progressLayer.fillColor = self.tintColor.CGColor;
}

- (void)reloadSpaceInformation {
    [self loadSystemSpaceInformation];
    self.progress = (CGFloat)self.progressInfo.fractionCompleted;
    [self updateInformationLabel];
}

- (void)loadSystemSpaceInformation {
    NSString *appResourcePath = [[NSBundle mainBundle] resourcePath];
    NSDictionary *pathInfo = [[NSFileManager defaultManager] attributesOfFileSystemForPath:appResourcePath
                                                                                     error:nil];
    
    self.progressInfo.totalUnitCount = [pathInfo[NSFileSystemSize] longLongValue];
    self.progressInfo.completedUnitCount = self.progressInfo.totalUnitCount - [pathInfo[NSFileSystemFreeSize] longLongValue];
}

- (void)updateInformationLabel {
    
    self.byteCountFormatter.includesCount = YES;
    self.byteCountFormatter.includesUnit = NO;
    CGFloat spaceUsed = (CGFloat)[[self.byteCountFormatter stringFromByteCount:self.progressInfo.completedUnitCount] doubleValue];
    CGFloat spaceTotal = (CGFloat)[[self.byteCountFormatter stringFromByteCount:self.progressInfo.totalUnitCount] doubleValue];

    self.byteCountFormatter.includesCount = NO;
    self.byteCountFormatter.includesUnit = YES;
    NSString *spaceUsedUnit = [self.byteCountFormatter stringFromByteCount:self.progressInfo.completedUnitCount];
    NSString *spaceTotalUnit = [self.byteCountFormatter stringFromByteCount:self.progressInfo.totalUnitCount];

    NSString *spaceInformationFormatString = [NSString stringWithFormat:@"%%.%luf %@/%%.%luf %@", (unsigned long)self.precision, spaceUsedUnit, (unsigned long)self.precision, spaceTotalUnit];
    self.informationLabel.text = [NSString stringWithFormat:spaceInformationFormatString, spaceUsed, spaceTotal];
}

@end
