//
//  HJMSegmentedControl.h
//  HJMURLDownloader
//
//  Created by Yozone Wang on 15/1/20.
//
//

#import <UIKit/UIKit.h>

@interface HJMSegmentedControl : UIControl

@property (strong, nonatomic) UIView *selectedBackgroundView NS_UNAVAILABLE;
@property (assign, nonatomic) UIEdgeInsets backgroundViewInsets NS_UNAVAILABLE;
@property (assign, nonatomic) BOOL showsIndicatorView;
@property (assign, nonatomic) CGFloat indicatorHeight;
@property (strong, nonatomic) UIImage *separatorImage;
@property (assign, nonatomic) NSUInteger selectedSegmentIndex;
@property (assign, nonatomic) BOOL animatedSwitch;
@property (assign, nonatomic) BOOL showsGhostIndicatorView;

/**
*  初始化 HJMSegmentedControl
*
*  @param items HJMSegmentedControl title，可以是 NSString, NSAttributedString 和 UIImage
*
*  @return 初始化后的 HJMSegmentedControl 实例
*/
- (instancetype)initWithItems:(NSArray *)items;

#pragma mark - Managing Segment Content

- (void)setTitle:(NSString *)title
        forSegmentAtIndex:(NSUInteger)segmentIndex;

- (NSString *)titleForSegmentAtIndex:(NSUInteger)segmentIndex;

- (void)setAttributedTitle:(NSAttributedString *)attributedTitle
         forSegmentAtIndex:(NSUInteger)segmentIndex;

- (NSAttributedString *)attributedTitleForSegmentAtIndex:(NSUInteger)segmentIndex;

- (void)setImage:(UIImage *)image
        forSegmentAtIndex:(NSUInteger)segmentIndex;

- (UIImage *)imageForSegmentAtIndex:(NSUInteger)segmentIndex;

#pragma mark - Managing Segments

- (NSUInteger)numberOfSegments;

- (void)removeAllSegments;

- (void)removeSegmentAtIndex:(NSUInteger)segmentIndex
                    animated:(BOOL)animated;

- (void)insertSegmentWithImage:(UIImage *)image
                       atIndex:(NSUInteger)segmentIndex
                      animated:(BOOL)animated;

- (void)insertSegmentWithTitle:(NSString *)title
                       atIndex:(NSUInteger)segmentIndex
                      animated:(BOOL)animated;

- (void)insertSegmentWithAttributedTitle:(NSAttributedString *)attributedTitle
                                 atIndex:(NSUInteger)segmentIndex
                                animated:(BOOL)animated;

#pragma mark - Managing Segment Behavior and Appearance

- (void)setEnabled:(BOOL)enabled
 forSegmentAtIndex:(NSUInteger)segmentIndex;

- (BOOL)isEnabledForSegmentAtIndex:(NSUInteger)segmentIndex;

- (void)setWidth:(CGFloat)width
        forSegmentAtIndex:(NSUInteger)segmentIndex;

- (CGFloat)widthForSegmentAtIndex:(NSUInteger)segmentIndex;

@property (assign, nonatomic) BOOL apportionsSegmentWidthsByContent NS_UNAVAILABLE;

#pragma mark - Associate with  UIScrollView

- (void)associateWithScrollView:(UIScrollView *)scrollView;

@end
