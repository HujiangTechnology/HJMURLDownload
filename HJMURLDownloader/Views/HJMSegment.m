//
//  HJMSegment.m
//  HJMURLDownloader
//
//  Created by Yozone Wang on 15/1/21.
//
//

#import "HJMSegment.h"
#import "UIColor+HJMDisabledColor.h"

@interface HJMSegment ()

@property (strong, nonatomic) UILabel *segmentLabel;
@property (strong, nonatomic) UIImageView *segmentImageView;
@property (copy, nonatomic) NSAttributedString *originalAttributedTitle;

@end

@implementation HJMSegment

+ (instancetype)segmentWithItem:(id)item {
    if ([item isKindOfClass:[UIImage class]]) {
        return [[self alloc] initWithImage:item];
    } else if ([item isKindOfClass:[NSString class]]) {
        return [[self alloc] initWithTitle:item];
    } else {
        return [[self alloc] initWithAttributedTitle:item];
    }
}


- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        _enabled = YES;
        _segmentLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _segmentLabel.textColor = self.tintColor;
        _segmentLabel.font = [UIFont systemFontOfSize:13.0f];
        _segmentLabel.textAlignment = NSTextAlignmentCenter;
        _segmentLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_segmentLabel];

        _segmentImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _segmentImageView.contentMode = UIViewContentModeScaleAspectFit;
        _segmentImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_segmentImageView];

        NSDictionary *variableBindings = NSDictionaryOfVariableBindings(_segmentImageView, _segmentLabel);
        NSMutableArray *constraints = [NSMutableArray array];
        
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_segmentLabel]|"
                                                                                 options:kNilOptions
                                                                                 metrics:nil
                                                                                   views:variableBindings]];
        
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_segmentImageView]|"
                                                                                 options:kNilOptions
                                                                                 metrics:nil
                                                                                   views:variableBindings]];
        
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_segmentLabel]|"
                                                                                 options:kNilOptions
                                                                                 metrics:nil
                                                                                   views:variableBindings]];
        
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_segmentImageView]|"
                                                                                 options:kNilOptions
                                                                                 metrics:nil
                                                                                   views:variableBindings]];
        
        [self addConstraints:constraints];

        _horizontalMargin = 5.0f;
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title {
    self = [self initWithFrame:CGRectZero];
    if (self) {
        _segmentLabel.text = title;
        _segmentImageView.hidden = YES;
    }
    return self;
}

- (instancetype)initWithAttributedTitle:(NSAttributedString *)attributedTitle {
    self = [self initWithFrame:CGRectZero];
    if (self) {
        _segmentLabel.attributedText = attributedTitle;
        _originalAttributedTitle = attributedTitle;
        _segmentImageView.hidden = YES;
    }
    return self;}

- (instancetype)initWithImage:(UIImage *)image {
    self = [self initWithFrame:CGRectZero];
    if (self) {
        _segmentImageView.image = image;
        _segmentLabel.hidden = YES;
    }
    return self;
}

- (NSString *)title {
    return self.segmentLabel.text;
}

- (void)setTitle:(NSString *)title {
    self.segmentLabel.hidden = NO;
    self.segmentLabel.text = title;
    self.originalAttributedTitle = nil;
    self.segmentImageView.hidden = YES;
}

- (NSAttributedString *)attributedTitle {
    return self.segmentLabel.attributedText;
}

- (void)setAttributedTitle:(NSAttributedString *)attributedTitle {
    self.segmentLabel.hidden = NO;
    self.segmentLabel.attributedText = attributedTitle;
    self.originalAttributedTitle = attributedTitle;
    self.segmentImageView.hidden = YES;
    [self updateColors];
}

- (UIImage *)image {
    return self.segmentImageView.image;
}

- (void)setImage:(UIImage *)image {
    self.segmentImageView.hidden = NO;
    self.segmentImageView.image = image;
    self.segmentLabel.hidden = YES;
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    [self updateColors];
}

- (void)sizeToFit {
    [super sizeToFit];
    [self.segmentLabel sizeToFit];
    [self.segmentImageView sizeToFit];
    CGRect tmpRect = CGRectUnion(self.segmentImageView.bounds, self.segmentLabel.bounds);
    tmpRect.size.width += self.horizontalMargin * 2.0f;
    CGRect frame = self.frame;
    frame.size = tmpRect.size;
    self.frame = frame;
}

- (void)setEnabled:(BOOL)enabled {
    if (_enabled != enabled) {
        _enabled = enabled;
        [self updateColors];
    }
}

- (void)updateColors {
    if (self.isEnabled) {
        self.segmentLabel.textColor = self.tintColor;
        self.segmentLabel.attributedText = self.originalAttributedTitle;
        self.segmentImageView.tintColor = self.tintColor;
    } else {
        UIColor *disabledColor = [self.tintColor hjm_disabledColor];
        self.segmentLabel.textColor = disabledColor;
        self.segmentImageView.tintColor = disabledColor;
        NSMutableAttributedString *disabledAttributedString = [self.originalAttributedTitle mutableCopy];
        [disabledAttributedString enumerateAttribute:NSForegroundColorAttributeName
                                             inRange:NSMakeRange(0, [disabledAttributedString length])
                                             options:NSAttributedStringEnumerationReverse
                                          usingBlock:^(UIColor *currentColor, NSRange range, BOOL *stop) {
                                              
            UIColor *disabledAttributedStringColor = [currentColor hjm_disabledColor];
            NSRange effectiveRange;
            UIFont *font = [disabledAttributedString attributesAtIndex:range.location effectiveRange:&effectiveRange][NSFontAttributeName];
            [disabledAttributedString setAttributes:@{
                    NSForegroundColorAttributeName: disabledAttributedStringColor,
                    NSFontAttributeName: font
            } range:range];
        }];
        self.segmentLabel.attributedText = [disabledAttributedString copy];
    }
}

@end
