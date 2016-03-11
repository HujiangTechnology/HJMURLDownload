//
//  HJMSegment.h
//  HJMURLDownloader
//
//  Created by Yozone Wang on 15/1/21.
//
//

#import <UIKit/UIKit.h>

@interface HJMSegment : UIView

@property (assign, nonatomic) CGFloat horizontalMargin;
@property (assign, nonatomic, getter=isEnabled) BOOL enabled;

+ (instancetype)segmentWithItem:(id)item;

- (instancetype)initWithTitle:(NSString *)title;
- (instancetype)initWithAttributedTitle:(NSAttributedString *)attributedTitle;
- (instancetype)initWithImage:(UIImage *)image;

- (NSString *)title;
- (void)setTitle:(NSString *)title;
- (NSAttributedString *)attributedTitle;
- (void)setAttributedTitle:(NSAttributedString *)attributedTitle;
- (UIImage *)image;
- (void)setImage:(UIImage *)image;

@end
