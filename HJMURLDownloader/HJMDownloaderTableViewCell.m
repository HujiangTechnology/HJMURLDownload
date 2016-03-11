//
//  HJMDownloaderTableViewCell.m
//  HJMURLDownloader
//
//  Created by Yozone Wang on 14/12/31.
//  Copyright (c) 2016 HJ. All rights reserved.
//

#import <sys/ucred.h>
#import "HJMDownloaderTableViewCell.h"
#import "HJMURLDownloadObject.h"
#import "HJMCDDownloadItem.h"
#import "HJMCircleProgressButton.h"

NSString * const HJMLastPlayedTimeKey = @"com.hujiang.hjmdownloader.lastPlayedTimeKey";

static NSDateFormatter * playTimeDateFormatter() {
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
    });
    return dateFormatter;
}

@interface HJMDownloaderTableViewCell ()

@property (strong, nonatomic) UIImageView *redDotImageView;
@property (strong, nonatomic) HJMCircleProgressButton *progressButton;
@property (strong, nonatomic) UILabel *lastPlayedTimeLabel;
@property (assign, nonatomic) NSInteger status;
@property (strong, nonatomic) NSByteCountFormatter *byteCountFormatter;

@end


@implementation HJMDownloaderTableViewCell

@synthesize delegate;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        self.multipleSelectionBackgroundView = [[UIView alloc] init];

        self.selectedBackgroundView = [UIView new];
        self.selectedBackgroundView.backgroundColor = [UIColor colorWithWhite:0.88
                                                                        alpha:1.0f];

        self.tintColor = [UIColor colorWithRed:0.098
                                         green:0.545
                                          blue:0.898
                                         alpha:1.000];

        self.textLabel.textColor = [UIColor colorWithRed:0.1490
                                                   green:0.1490
                                                    blue:0.1490
                                                   alpha:1.0];
        
        self.textLabel.font = [UIFont systemFontOfSize:16];

        self.detailTextLabel.textColor = [UIColor colorWithRed:0.5294
                                                         green:0.5294
                                                          blue:0.5294
                                                         alpha:1.0];
        
        self.detailTextLabel.font = [UIFont systemFontOfSize:14];

        _redDotImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"reddot"]];
        _redDotImageView.hidden = YES;
        [self.contentView addSubview:_redDotImageView];

        _lastPlayedTimeLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.font = [UIFont systemFontOfSize:13];
            label.textColor = [UIColor colorWithRed:0.098
                                              green:0.545
                                               blue:0.898
                                              alpha:1.000];
            
            [self.contentView addSubview:label];
            label;
        });

        _progressButton = [HJMCircleProgressButton circleProgressButtonWithFrame:CGRectMake(0,
                                                                                            0,
                                                                                            40,
                                                                                            40)];
        
        _progressButton.progress = 0.0f;
        self.accessoryView = _progressButton;
        _status = NSNotFound;

        _byteCountFormatter = [[NSByteCountFormatter alloc] init];
        _byteCountFormatter.countStyle = NSByteCountFormatterCountStyleFile;
        _byteCountFormatter.allowsNonnumericFormatting = NO;
    }
    return self;
}

- (void)updateCellWithDownloadItem:(HJMCDDownloadItem *)downloadItem {
    HJMURLDownloadStatus status = (HJMURLDownloadStatus)[downloadItem.state integerValue];
    self.textLabel.text = downloadItem.name;

    if (status != HJMURLDownloadStatusSucceeded) {
        if ([downloadItem.totalSize longLongValue] > 0) {
            
            NSString *totalSizeString = [self.byteCountFormatter stringFromByteCount:[downloadItem.totalSize longLongValue]];
            NSString *downloadedSizeString = [self.byteCountFormatter stringFromByteCount:[downloadItem.downloadedSize longLongValue]];
            self.detailTextLabel.text = [NSString stringWithFormat:@"%@/%@", downloadedSizeString, totalSizeString];
            
        } else {
            self.detailTextLabel.text = @" ";
        }
    } else {
        self.detailTextLabel.text = [self.byteCountFormatter stringFromByteCount:[downloadItem.totalSize longLongValue]];
    }


    NSDictionary *userInfo = downloadItem.userInfo;
    NSUInteger playTime = [userInfo[HJMLastPlayedTimeKey] unsignedIntegerValue];
    
    if (playTime > 0) {
        
        NSDateComponents *dc = [[NSDateComponents alloc] init];
        dc.second = playTime;
        NSDateFormatter *dateFormatter = playTimeDateFormatter();
        NSDate *lastPlayTime = [[NSCalendar autoupdatingCurrentCalendar] dateFromComponents:dc];
        
        NSDateComponents *dateComponents = [[NSCalendar autoupdatingCurrentCalendar] components:NSCalendarUnitHour |
                                                                                                NSMinuteCalendarUnit |
                                                                                                NSSecondCalendarUnit
                                                                                       fromDate:lastPlayTime];
        if (dateComponents.hour == 0) {
            dateFormatter.dateFormat = @"mm:ss";
        } else {
            dateFormatter.dateFormat = @"HH:mm:ss";
        }
        self.lastPlayedTimeLabel.textColor = [UIColor colorWithRed:0.6
                                                             green:0.6
                                                              blue:0.6
                                                             alpha:1];
        
        self.lastPlayedTimeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"上次听到：%@", @""), [dateFormatter stringFromDate:lastPlayTime]];
    } else {
        if (status == HJMURLDownloadStatusDownloadFailed) {
            
            self.lastPlayedTimeLabel.textColor = [UIColor colorWithRed:0.97
                                                                 green:0.42
                                                                  blue:0.41
                                                                 alpha:1];
            
            self.lastPlayedTimeLabel.text = NSLocalizedString(@"下载错误，请重试", @"");
        } else {
            self.lastPlayedTimeLabel.text = nil;
        }
    }


    if (status == HJMURLDownloadStatusSucceeded) {
        self.progressButton.progress = 0.0f;
    } else {
        self.progressButton.progress = [downloadItem.progress floatValue];
    }

    if (status == HJMURLDownloadStatusSucceeded) {
        self.redDotImageView.hidden = ![downloadItem.isNewDownload boolValue];
    } else {
        self.redDotImageView.hidden = YES;
    }

    if (self.status != status) {
        self.status = status;
        NSArray *actions = [self.progressButton actionsForTarget:self
                                                 forControlEvent:UIControlEventTouchUpInside];
        
        for (NSString *actionName in actions) {
            if (actionName) {
                [self.progressButton removeTarget:self
                                           action:NSSelectorFromString(actionName)
                                 forControlEvents:UIControlEventTouchUpInside];
            }
        }
        switch (status) {
            case HJMURLDownloadStatusDownloading:
                [self.progressButton setImage:[UIImage imageNamed:@"pause-icon"]
                                     forState:UIControlStateNormal];
                
                [self.progressButton addTarget:self
                                        action:@selector(cancelDownloadAction:)
                              forControlEvents:UIControlEventTouchUpInside];
                
                break;
            case HJMURLDownloadStatusWaiting:
                [self.progressButton setImage:[UIImage imageNamed:@"waiting-icon"]
                                     forState:UIControlStateNormal];
                
                [self.progressButton addTarget:self
                                        action:@selector(cancelDownloadAction:)
                              forControlEvents:UIControlEventTouchUpInside];
                
                break;
            case HJMURLDownloadStatusSucceeded:
                [self.progressButton setImage:[UIImage imageNamed:@"play-icon"]
                                     forState:UIControlStateNormal];
                
                [self.progressButton addTarget:self
                                        action:@selector(otherAction:)
                              forControlEvents:UIControlEventTouchUpInside];
                
                break;
            default:
                [self.progressButton setImage:[UIImage imageNamed:@"download-icon"]
                                     forState:UIControlStateNormal];
                
                [self.progressButton addTarget:self
                                        action:@selector(downloadAction:)
                              forControlEvents:UIControlEventTouchUpInside];
                
                break;
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat contentWidth = CGRectGetWidth(self.contentView.bounds);
//    CGFloat contentHeight = CGRectGetHeight(self.contentView.bounds);

    [self.textLabel sizeToFit];
    CGRect frame = self.textLabel.frame;
    frame.origin = CGPointMake(16.0f, 18.0f);
    if (CGRectGetWidth(self.textLabel.frame) + 30 > contentWidth) {
        frame.size.width = contentWidth - 30.0f;
    }
    self.textLabel.frame = frame;

    self.redDotImageView.center = CGPointMake(CGRectGetMaxX(frame), CGRectGetMinY(frame));

    // detailTextLabel
    [self.detailTextLabel sizeToFit];
    frame = self.detailTextLabel.frame;
    frame.origin.x = CGRectGetMinX(self.textLabel.frame);
    frame.origin.y = CGRectGetMaxY(self.textLabel.frame) + 6;
    self.detailTextLabel.frame = frame;

    [self.lastPlayedTimeLabel sizeToFit];
    CGPoint center = self.lastPlayedTimeLabel.center;
    center.x = CGRectGetMaxX(frame) + CGRectGetWidth(self.lastPlayedTimeLabel.bounds) * 0.5f + 15.0f;
    center.y = self.detailTextLabel.center.y;
    self.lastPlayedTimeLabel.center = center;
}

#pragma mark - perform actions

- (void)downloadAction:(UIButton *)button {
    [self.delegate performResumeActionForCell:self];
}

- (void)otherAction:(UIButton *)button {
    [self.delegate performOtherActionForCell:self];
}

- (void)cancelDownloadAction:(UIButton *)button {
    [self.delegate performCancelActionForCell:self];
}

@end
