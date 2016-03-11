//
//  HJMSegmentedControl.m
//  HJMURLDownloader
//
//  Created by Yozone Wang on 15/1/20.
//
//

#import "HJMSegmentedControl.h"
#import "HJMSegment.h"
#import "UIColor+HJMDisabledColor.h"

// TODO: 实现 apportionsSegmentWidthsByContent
// TODO: 实现 selectedBackgroundView
// TODO: 实现 highlighted 和 selected 状态
// TODO: 实现 HJMSegment 比较多时的滚动

static CGFloat const kHJMSegmentedControlDefaultHeight = 30.0f;

@interface HJMSegmentedControl ()

@property (strong, nonatomic) UIView *indicatorView;
@property (strong, nonatomic) NSMutableArray *segmentItems;
@property (strong, nonatomic) NSMutableArray *separatorImageViews;
@property (strong, nonatomic) NSMutableDictionary *specifiedSegmentedWidths;
@property (strong, nonatomic) UIView *ghostIndicatorView;
@property (assign, nonatomic) NSUInteger previousTouchedSegmentIndex;
@property (assign, nonatomic) BOOL isObserving;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) NSMutableIndexSet *disabledIndexes;

@end

@implementation HJMSegmentedControl

- (void)dealloc {
    [self removeObserving];
    _scrollView = nil;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _segmentItems = [NSMutableArray array];
        _specifiedSegmentedWidths = [NSMutableDictionary dictionary];
        _separatorImageViews = [NSMutableArray array];

        _indicatorHeight = 2.0f;
        _indicatorView = [[UIView alloc] initWithFrame:CGRectMake(0,
                0,
                0,
                _indicatorHeight)];

        _indicatorView.backgroundColor = self.tintColor;
        [self addSubview:_indicatorView];

        _ghostIndicatorView = [[UIView alloc] initWithFrame:_indicatorView.frame];
        _ghostIndicatorView.backgroundColor = [_indicatorView.backgroundColor hjm_disabledColor];
        _ghostIndicatorView.hidden = YES;
        [self insertSubview:_ghostIndicatorView belowSubview:_indicatorView];

        _selectedSegmentIndex = 0;
        _showsIndicatorView = YES;
        _showsGhostIndicatorView = YES;
        _apportionsSegmentWidthsByContent = NO;
        _isObserving = NO;
        _disabledIndexes = [NSMutableIndexSet indexSet];
        _animatedSwitch = YES;
    }
    return self;
}

- (instancetype)initWithItems:(NSArray *)items {
    self = [self initWithFrame:CGRectZero];
    if (self) {
        [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            HJMSegment *segment = [HJMSegment segmentWithItem:obj];
            [self addSubview:segment];
            [self.segmentItems addObject:segment];
        }];

        [self sizeToFit];
    }
    return self;
}

- (void)setShowsGhostIndicatorView:(BOOL)showsGhostIndicatorView {
    if (_showsGhostIndicatorView != showsGhostIndicatorView) {
        _showsGhostIndicatorView = showsGhostIndicatorView;
        self.ghostIndicatorView.hidden = !showsGhostIndicatorView;
    }
}

- (void)setShowsIndicatorView:(BOOL)showsIndicatorView {
    if (_showsIndicatorView != showsIndicatorView) {
        _showsIndicatorView = showsIndicatorView;
        self.indicatorView.hidden = !showsIndicatorView;
    }
}

- (void)setSelectedSegmentIndex:(NSUInteger)selectedSegmentIndex {
    if (_selectedSegmentIndex != selectedSegmentIndex) {
        _selectedSegmentIndex = selectedSegmentIndex;
        if (self.showsIndicatorView) {
            HJMSegment *segment = self.segmentItems[selectedSegmentIndex];
            CGFloat offsetX = CGRectGetMinX(segment.frame);
            CGFloat width = CGRectGetWidth(segment.frame);

            CGRect indicatorFrame = CGRectMake(offsetX,
                    CGRectGetHeight(self.bounds) - self.indicatorHeight,
                    width,
                    self.indicatorHeight);

            if (self.animatedSwitch) {
                [self animationWithBlock:^{
                    self.indicatorView.frame = indicatorFrame;
                } completion:^(BOOL finished) {
                    self.ghostIndicatorView.hidden = YES;
                }];
            } else {
                self.indicatorView.frame = indicatorFrame;
                self.ghostIndicatorView.hidden = YES;
            }
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    [self layoutSegmentItemsAnimated:NO];
}

- (void)sizeToFit {
    [super sizeToFit];
    [self.specifiedSegmentedWidths removeAllObjects];
    CGFloat __block maxSegmentWidth = 0.0f;
    [self.segmentItems enumerateObjectsUsingBlock:^(HJMSegment *segment, NSUInteger idx, BOOL *stop) {
        [segment sizeToFit];
        CGFloat segmentWidth = CGRectGetWidth(segment.bounds);
        if (segmentWidth > maxSegmentWidth) {
            maxSegmentWidth = segmentWidth;
        }
    }];
    CGFloat width = maxSegmentWidth * [self.segmentItems count];
    CGRect frame = self.frame;
    frame.size.width = width;
    frame.size.height = kHJMSegmentedControlDefaultHeight;
    self.frame = frame;
    [self layoutSegmentItemsAnimated:NO];
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    [self updateColors];
}

- (void)updateColors {
    UIColor *subViewTintColor = self.isEnabled ? self.tintColor : [self.tintColor hjm_disabledColor];
    [self.segmentItems setValue:self.tintColor forKeyPath:@"tintColor"];
    self.indicatorView.backgroundColor = subViewTintColor;
    self.ghostIndicatorView.backgroundColor = [subViewTintColor hjm_disabledColor];
}

- (void)layoutSegmentItemsAnimated:(BOOL)animated {
    CGFloat __block segmentWidth = 0.0f;
    CGPoint __block previousOrigin = CGPointZero;
    UIImageView * __block separatorImageView;
    NSArray *allSpecifiedWidths = [self.specifiedSegmentedWidths allValues];
    NSNumber *totalSpecifiedWidthValue = [allSpecifiedWidths valueForKeyPath:@"@sum.SELF"];
    CGFloat totalSpecifiedWidth;
    [totalSpecifiedWidthValue getValue:&totalSpecifiedWidth];
    CGFloat averageWidth = 0;
    if (totalSpecifiedWidth > 0) {
        averageWidth = (CGRectGetWidth(self.bounds) - totalSpecifiedWidth) / ([self.segmentItems count] - [allSpecifiedWidths count]);
    } else {
        averageWidth = CGRectGetWidth(self.bounds) / [self.segmentItems count];
    }
    void(^animationBlock)(void) = ^{
        [self.segmentItems enumerateObjectsUsingBlock:^(HJMSegment *segmentView, NSUInteger idx, BOOL *stop) {
            NSValue *specifiedWidth = self.specifiedSegmentedWidths[@(idx)];
            if (specifiedWidth) {
                [specifiedWidth getValue:&segmentWidth];
            } else {
                segmentWidth = averageWidth;
            }
            if (self.separatorImage) {
                if (idx > 0) {
                    if (idx > [self.separatorImageViews count]) {
                        separatorImageView = [[UIImageView alloc] initWithImage:self.separatorImage];
                        [self.separatorImageViews addObject:separatorImageView];
                        [self addSubview:separatorImageView];
                    } else {
                        separatorImageView = self.separatorImageViews[idx - 1];
                    }
                    separatorImageView.frame = CGRectMake(
                            previousOrigin.x - self.separatorImage.size.width * 0.5f,
                            (CGRectGetHeight(self.frame) - self.separatorImage.size.height) * 0.5f,
                            self.separatorImage.size.width,
                            self.separatorImage.size.height
                    );
                }
            }
            CGRect segmentFrame = CGRectZero;
            segmentFrame.origin = previousOrigin;
            segmentFrame.size.height = CGRectGetHeight(self.bounds);
            segmentFrame.size.width = segmentWidth;
            segmentView.frame = segmentFrame;
            previousOrigin.x += segmentWidth;
            if (self.showsIndicatorView && self.selectedSegmentIndex == idx) {
                CGFloat offsetX = CGRectGetMinX(segmentFrame);
                CGFloat width = CGRectGetWidth(segmentFrame);

                CGRect indicatorFrame = CGRectMake(offsetX,
                        CGRectGetHeight(self.bounds) - self.indicatorHeight,
                        width,
                        self.indicatorHeight);

                self.indicatorView.frame = indicatorFrame;
                self.ghostIndicatorView.frame = indicatorFrame;
            }
        }];
    };

    animated ? [self animationWithBlock:animationBlock completion:nil] : animationBlock();
}

- (void)setSeparatorImage:(UIImage *)separatorImage {
    if (_separatorImage != separatorImage) {
        _separatorImage = separatorImage;
        [self layoutSegmentItemsAnimated:NO];
    }
}

#pragma mark - Managing Segment Content

- (void)setTitle:(NSString *)title forSegmentAtIndex:(NSUInteger)segmentIndex {
    HJMSegment *segment = self.segmentItems[segmentIndex];
    [segment setTitle:title];
}

- (NSString *)titleForSegmentAtIndex:(NSUInteger)segmentIndex {
    HJMSegment *segment = self.segmentItems[segmentIndex];
    return segment.title;
}

- (void)setAttributedTitle:(NSAttributedString *)attributedTitle
         forSegmentAtIndex:(NSUInteger)segmentIndex {

    HJMSegment *segment = self.segmentItems[segmentIndex];
    [segment setAttributedTitle:attributedTitle];
}

- (NSAttributedString *)attributedTitleForSegmentAtIndex:(NSUInteger)segmentIndex {
    HJMSegment *segment = self.segmentItems[segmentIndex];
    return segment.attributedTitle;
}

- (void)setImage:(UIImage *)image forSegmentAtIndex:(NSUInteger)segmentIndex {
    HJMSegment *segment = self.segmentItems[segmentIndex];
    [segment setImage:image];
}

- (UIImage *)imageForSegmentAtIndex:(NSUInteger)segmentIndex {
    HJMSegment *segment = self.segmentItems[segmentIndex];
    return segment.image;
}

#pragma mark - Managing Segments

- (NSUInteger)numberOfSegments {
    return [self.segmentItems count];
}

- (void)removeAllSegments {
    [self.segmentItems enumerateObjectsUsingBlock:^(HJMSegment *segment, NSUInteger idx, BOOL *stop) {
        [segment removeFromSuperview];
    }];
    [self.segmentItems removeAllObjects];
    [self.separatorImageViews enumerateObjectsUsingBlock:
            ^(UIImageView *imageView, NSUInteger idx, BOOL *stop) {
                [imageView removeFromSuperview];
            }];
    [self.separatorImageViews removeAllObjects];
    [self.specifiedSegmentedWidths removeAllObjects];
}

- (void)removeSegmentAtIndex:(NSUInteger)segmentIndex
                    animated:(BOOL)animated {

    HJMSegment *segment = self.segmentItems[segmentIndex];
    [segment removeFromSuperview];
    [self.segmentItems removeObjectAtIndex:segmentIndex];
    [self.specifiedSegmentedWidths removeObjectForKey:@(segmentIndex)];
    if ([self.separatorImageViews count] > 0) {
        NSUInteger separatorImageIndex = 0;
        if (segmentIndex > 0) {
            separatorImageIndex = segmentIndex - 1;
        }
        UIImageView *separatorImageView = self.separatorImageViews[separatorImageIndex];
        [separatorImageView removeFromSuperview];
        [self.separatorImageViews removeObjectAtIndex:separatorImageIndex];
    }
    if (self.selectedSegmentIndex == [self.segmentItems count]) {
        _selectedSegmentIndex = [self.segmentItems count] - 1;
    }
    [self layoutSegmentItemsAnimated:animated];
}

- (void)insertSegmentWithImage:(UIImage *)image
                       atIndex:(NSUInteger)segmentIndex
                      animated:(BOOL)animated {

    HJMSegment *segment = [[HJMSegment alloc] initWithImage:image];
    [self addSubview:segment];
    [self.segmentItems insertObject:segment atIndex:segmentIndex];
    [self layoutSegmentItemsAnimated:animated];
}

- (void)insertSegmentWithTitle:(NSString *)title
                       atIndex:(NSUInteger)segmentIndex
                      animated:(BOOL)animated {

    HJMSegment *segment = [[HJMSegment alloc] initWithTitle:title];
    [self addSubview:segment];
    [self.segmentItems insertObject:segment atIndex:segmentIndex];
    [self layoutSegmentItemsAnimated:animated];
}

- (void)insertSegmentWithAttributedTitle:(NSAttributedString *)attributedTitle
                                 atIndex:(NSUInteger)segmentIndex
                                animated:(BOOL)animated {

    HJMSegment *segment = [[HJMSegment alloc] initWithAttributedTitle:attributedTitle];
    [self addSubview:segment];
    [self.segmentItems insertObject:segment atIndex:segmentIndex];
    [self layoutSegmentItemsAnimated:animated];
}

#pragma mark - Managing Segment Behavior and Appearance

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    if (self.isEnabled) {
        [self.segmentItems enumerateObjectsUsingBlock:^(HJMSegment *segment, NSUInteger idx, BOOL *stop) {
            if (![self.disabledIndexes containsIndex:idx]) {
                segment.enabled = YES;
            }
        }];
    } else {
        [self.segmentItems setValue:@(NO) forKeyPath:@"enabled"];
    }
    [self updateColors];
}

- (void)setEnabled:(BOOL)enabled
 forSegmentAtIndex:(NSUInteger)segmentIndex {

    HJMSegment *segment = self.segmentItems[segmentIndex];
    segment.enabled = enabled;
    if (!enabled) {
        [self.disabledIndexes addIndex:segmentIndex];
    } else {
        [self.disabledIndexes removeIndex:segmentIndex];
    }
}

- (BOOL)isEnabledForSegmentAtIndex:(NSUInteger)segmentIndex {
    HJMSegment *segment = self.segmentItems[segmentIndex];
    return segment.isEnabled;
}

- (void)setWidth:(CGFloat)width
        forSegmentAtIndex:(NSUInteger)segmentIndex {

    self.specifiedSegmentedWidths[@(segmentIndex)] = @(width);
    [self layoutSegmentItemsAnimated:YES];
}

- (CGFloat)widthForSegmentAtIndex:(NSUInteger)segmentIndex {
    HJMSegment *segment = self.segmentItems[segmentIndex];
    return segment.frame.size.width;
}


#pragma mark  - Tracking Touches and Redrawing Controls

- (BOOL)beginTrackingWithTouch:(UITouch *)touch
                     withEvent:(UIEvent *)event {

    if (self.showsIndicatorView) {
        self.ghostIndicatorView.hidden = !self.showsGhostIndicatorView;
        NSUInteger touchedSegmentIndex = [self.segmentItems indexOfObjectPassingTest:
                ^BOOL(HJMSegment *segment, NSUInteger idx, BOOL *stop) {
                    BOOL found = CGRectContainsPoint(segment.frame, [touch locationInView:self]);
                    if (found) {
                        *stop = YES;
                        return YES;
                    }
                    return NO;
                }];
        if (touchedSegmentIndex != NSNotFound && self.previousTouchedSegmentIndex != touchedSegmentIndex) {
            self.previousTouchedSegmentIndex = touchedSegmentIndex;
            HJMSegment *segment = self.segmentItems[touchedSegmentIndex];
            CGFloat offsetX = CGRectGetMinX(segment.frame);
            CGFloat width = CGRectGetWidth(segment.frame);

            CGRect indicatorFrame = CGRectMake(
                    offsetX,
                    CGRectGetHeight(self.bounds) - self.indicatorHeight,
                    width,
                    self.indicatorHeight
            );

            self.ghostIndicatorView.frame = self.indicatorView.frame;
            if (self.animatedSwitch) {
                [self animationWithBlock:^{
                    self.ghostIndicatorView.frame = indicatorFrame;
                }             completion:nil];
            } else {
                self.ghostIndicatorView.frame = indicatorFrame;
            }
        }
    }
    return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch
                        withEvent:(UIEvent *)event {

    if (self.showsIndicatorView) {
        NSUInteger touchedSegmentIndex = [self.segmentItems indexOfObjectPassingTest:
                ^BOOL(HJMSegment *segment, NSUInteger idx, BOOL *stop) {
                    BOOL found = CGRectContainsPoint(segment.frame, [touch locationInView:self]);
                    if (found) {
                        *stop = YES;
                        return YES;
                    }
                    return NO;
                }];
        if (touchedSegmentIndex != NSNotFound && self.previousTouchedSegmentIndex != touchedSegmentIndex) {
            self.previousTouchedSegmentIndex = touchedSegmentIndex;
            HJMSegment *segment = self.segmentItems[touchedSegmentIndex];
            CGFloat offsetX = CGRectGetMinX(segment.frame);
            CGFloat width = CGRectGetWidth(segment.frame);

            CGRect indicatorFrame = CGRectMake(offsetX,
                    CGRectGetHeight(self.bounds) - self.indicatorHeight,
                    width,
                    self.indicatorHeight);

            if (self.animatedSwitch) {
                [self animationWithBlock:^{
                    self.ghostIndicatorView.frame = indicatorFrame;
                } completion:nil];
            } else {
                self.ghostIndicatorView.frame = indicatorFrame;
            }
        }
    }
    return YES;
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
    if (self.showsIndicatorView) {
        self.ghostIndicatorView.hidden = YES;
        self.previousTouchedSegmentIndex = NSNotFound;
    }
}

- (void)endTrackingWithTouch:(UITouch *)touch
                   withEvent:(UIEvent *)event {

    if (self.showsIndicatorView) {
        NSUInteger selectedIndex = [self.segmentItems indexOfObjectPassingTest:
                ^BOOL(HJMSegment *segment, NSUInteger idx, BOOL *stop) {
                    BOOL found = CGRectContainsPoint(segment.frame, [touch locationInView:self]);
                    if (found) {
                        *stop = YES;
                        return YES;
                    }
                    return NO;
                }];
        self.previousTouchedSegmentIndex = NSNotFound;
        if (selectedIndex != NSNotFound && selectedIndex != self.selectedSegmentIndex) {
            HJMSegment *segment = self.segmentItems[selectedIndex];
            if (segment.isEnabled) {
                self.selectedSegmentIndex = selectedIndex;
                [self sendActionsForControlEvents:UIControlEventValueChanged];
            } else {
                if (self.animatedSwitch) {
                    [self animationWithBlock:^{
                        self.ghostIndicatorView.frame = self.indicatorView.frame;
                    } completion:^(BOOL finished) {
                        self.ghostIndicatorView.hidden = YES;
                    }];
                } else {
                    self.ghostIndicatorView.hidden = YES;
                }
            }
        } else {
            self.ghostIndicatorView.hidden = YES;
        }
    }
}

#pragma mark - Associate with  UIScrollView

- (void)associateWithScrollView:(UIScrollView *)scrollView {
    self.scrollView = scrollView;
    [self addObserving];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {

    if ([keyPath isEqualToString:@"contentOffset"]) {
        [self scrollViewDidScroll:[change[NSKeyValueChangeNewKey] CGPointValue]];
    } else {

        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    if (!self.scrollView.isScrollEnabled) {
        return;
    }
    CGFloat scrollViewWidth = CGRectGetWidth(self.scrollView.bounds);
    CGFloat currentPageOffset = self.selectedSegmentIndex * scrollViewWidth;
    CGFloat relativeOffset = contentOffset.x - currentPageOffset;
    CGFloat offsetRatio = relativeOffset / scrollViewWidth;

    NSUInteger nextSelectedIndex = self.selectedSegmentIndex;

    if (offsetRatio > 0) {
        if (nextSelectedIndex < [self.segmentItems count] - 1) {
            nextSelectedIndex += 1;
        }
    } else {
        if (nextSelectedIndex > 0 && nextSelectedIndex < [self.segmentItems count]) {
            nextSelectedIndex -= 1;
        }
    }

    if (nextSelectedIndex != self.selectedSegmentIndex) {
        HJMSegment *nextSegment = self.segmentItems[nextSelectedIndex];
        CGRect nextSegmentFrame = nextSegment.frame;
        HJMSegment *currentSegment = self.segmentItems[self.selectedSegmentIndex];
        CGRect currentSegmentFrame = currentSegment.frame;
        self.indicatorView.frame = CGRectMake(
                CGRectGetMinX(currentSegmentFrame) + ABS(CGRectGetMinX(currentSegmentFrame) - CGRectGetMinX(nextSegmentFrame)) * offsetRatio,
                CGRectGetMinY(self.indicatorView.frame),
                CGRectGetWidth(currentSegmentFrame) + (CGRectGetWidth(currentSegmentFrame) - CGRectGetWidth(nextSegmentFrame)) * offsetRatio,
                self.indicatorHeight
        );
        if (ABS(offsetRatio) == 1.0f) {
            if (self.isEnabled && nextSegment.isEnabled) {
                _selectedSegmentIndex = nextSelectedIndex;
            } else {
                CGFloat offsetX = CGRectGetMinX(currentSegmentFrame);
                CGFloat width = CGRectGetWidth(currentSegmentFrame);

                CGRect indicatorFrame = CGRectMake(offsetX,
                        CGRectGetHeight(self.bounds) - self.indicatorHeight,
                        width,
                        self.indicatorHeight);

                if (self.animatedSwitch) {
                    [self removeObserving];
                    [self animationWithBlock:^{
                        self.indicatorView.frame = indicatorFrame;
                        [self.scrollView setContentOffset:CGPointMake(currentPageOffset, 0) animated:NO];
                    }             completion:^(BOOL finished) {
                        [self addObserving];
                    }];
                } else {
                    self.indicatorView.frame = indicatorFrame;
                    [self.scrollView setContentOffset:CGPointMake(currentPageOffset, 0) animated:NO];
                }
            }
        }
    }
}

- (void)addObserving {
    if (!self.isObserving) {

        [self.scrollView addObserver:self
                          forKeyPath:@"contentOffset"
                             options:NSKeyValueObservingOptionNew
                             context:NULL];

        self.isObserving = YES;
    }
}

- (void)removeObserving {
    if (self.isObserving) {

        [self.scrollView removeObserver:self
                             forKeyPath:@"contentOffset"
                                context:NULL];

        self.isObserving = NO;
    }
}

- (void)animationWithBlock:(dispatch_block_t)animationBlock
                completion:(void(^)(BOOL finished))completionBlock {

    [UIView animateWithDuration:0.25
                          delay:0
         usingSpringWithDamping:0.6f
          initialSpringVelocity:0.0f
                        options:UIViewAnimationOptionCurveLinear
                     animations:animationBlock completion:completionBlock];
}

@end
