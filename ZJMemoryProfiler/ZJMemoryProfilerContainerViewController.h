//
//  ZJMemoryProfilerContainerViewController.h
//  ZJMemoryProfilerDemo
//
//  Created by Melody on 16/6/23.
//  Copyright © 2016年 Melody. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 Contains child view controller with given sizes, let's it being draggable all around within
 the window it was created in.
 */
@interface ZJMemoryProfilerContainerViewController : UIViewController

- (void)presentViewController:(nonnull UIViewController *)viewController
                     withSize:(CGSize)size;

- (void)dismissCurrentViewController;

@end
