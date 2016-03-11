//
//  HJMDownloaderHeaderView.h
//  HJMURLDownloader
//
//  Created by Yozone Wang on 15/1/26.
//
//

#import <UIKit/UIKit.h>
#import "HJMDownloaderTableViewCellAndHeaderProtocol.h"

@interface HJMDownloaderHeaderView : UITableViewHeaderFooterView <HJMDownloaderHeaderViewProtocol>

@property (strong, readonly, nonatomic) UILabel *titleLabel;

@end
