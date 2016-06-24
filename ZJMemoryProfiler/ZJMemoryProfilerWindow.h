//
//  ZJMemoryProfilerWindow.h
//  ZJMemoryProfilerDemo
//
//  Created by Melody on 16/6/23.
//  Copyright © 2016年 Melody. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ZJMemoryProfilerWindowTouchesDelegate <NSObject>

- (BOOL)window:(nullable UIWindow *)window shouldReceiveTouchAtPoint:(CGPoint)point;

@end

/**
 Window that ZJMemoryProfiler will reside in.
 */
@interface ZJMemoryProfilerWindow : UIWindow

/**
 Whenever we receive a touch event, window needs to ask delegate if this event should be captured.
 */
@property (nonatomic, weak, nullable) id<ZJMemoryProfilerWindowTouchesDelegate> touchesDelegate;

@end
