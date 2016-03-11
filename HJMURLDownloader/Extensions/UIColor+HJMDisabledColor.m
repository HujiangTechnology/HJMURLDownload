//
//  UIColor+HJMDisabledColor.m
//  HJMURLDownloader
//
//  Created by Yozone Wang on 15/1/23.
//
//

#import "UIColor+HJMDisabledColor.h"

@implementation UIColor (HJMDisabledColor)

- (UIColor *)hjm_disabledColor {
    CGFloat hue, saturation, brightness, alpha, white;
    
    if ([self getHue:&hue
          saturation:&saturation
          brightness:&brightness
               alpha:&alpha]) {
        
        if (saturation <= 0.01f) {
            brightness += (1.0 - brightness) * 0.5f;
        } else {
            saturation *= 0.5f;
        }
        return [UIColor colorWithHue:hue
                          saturation:saturation
                          brightness:brightness
                               alpha:alpha];
        
    } else if ([self getWhite:&white
                        alpha:&alpha]) {
        
        white += (1.0 - white) * 0.5f;
        
        return [UIColor colorWithWhite:white
                                 alpha:alpha];
    }

    return self;
}

@end
