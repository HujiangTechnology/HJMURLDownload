//
//  HJMDownloaderHeaderView.m
//  HJMURLDownloader
//
//  Created by Yozone Wang on 15/1/26.
//
//

#import "HJMDownloaderHeaderView.h"

@interface HJMDownloaderHeaderView ()

@property (strong, readwrite, nonatomic) UILabel *titleLabel;

@property (strong, nonatomic) UIView *bottomSeparatorView;
@property (strong, nonatomic) UIView *topSeparatorView;

@end

@implementation HJMDownloaderHeaderView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        _titleLabel = [[UILabel alloc] initWithFrame:self.bounds];
        _titleLabel.textColor = [UIColor colorWithRed:0.4549
                                                green:0.4549
                                                 blue:0.4549
                                                alpha:1.0];
        
        _titleLabel.font = [UIFont systemFontOfSize:14];
        [self.contentView addSubview:_titleLabel];

        self.backgroundView = [[UIView alloc] init];
        self.backgroundView.backgroundColor = [UIColor colorWithRed:0.9294
                                                              green:0.9294
                                                               blue:0.9294
                                                              alpha:1.0];
        

        CGFloat separatorHeight = 1.0f / [UIScreen mainScreen].scale;
        _bottomSeparatorView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                        CGRectGetHeight(self.bounds) - separatorHeight,
                                                                        CGRectGetWidth(self.bounds),
                                                                        separatorHeight)];
        
        _bottomSeparatorView.backgroundColor = [UIColor colorWithRed:0.8078
                                                               green:0.8078
                                                                blue:0.8078
                                                               alpha:1.0];
        
        [self addSubview:_bottomSeparatorView];

        _topSeparatorView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                     0,
                                                                     CGRectGetWidth(self.bounds),
                                                                     separatorHeight)];
        
        _topSeparatorView.backgroundColor = [UIColor colorWithRed:0.8078
                                                            green:0.8078
                                                             blue:0.8078
                                                            alpha:1.0];
        
        [self addSubview:_topSeparatorView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.titleLabel.frame = CGRectInset(self.bounds, 10, 0);

    CGFloat separatorHeight = 1.0f / [UIScreen mainScreen].scale;
    self.bottomSeparatorView.frame = CGRectMake(0,
                                                CGRectGetHeight(self.bounds) - separatorHeight,
                                                CGRectGetWidth(self.bounds),
                                                separatorHeight);
    
    self.topSeparatorView.frame = CGRectMake(0,
                                             0,
                                             CGRectGetWidth(self.bounds),
                                             separatorHeight);
}

@end
