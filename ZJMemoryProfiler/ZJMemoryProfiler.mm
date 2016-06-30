//
//  ZJMemoryProfiler.m
//  ZJMemoryProfilerDemo
//
//  Created by Melody on 16/6/22.
//  Copyright © 2016年 Melody. All rights reserved.
//

#import "ZJMemoryProfiler.h"

#import <FBMemoryProfiler/FBMemoryProfiler.h>
#import <FBMemoryProfiler/FBMemoryProfilerOptions.h>
#import "ZJMemoryProfilerWindow.h"
#import "ZJMemoryProfilerContainerViewController.h"
#import "ZJMemoryProfilerFloatingViewController.h"

static const NSUInteger kZJFloatingViewHeight = 24.0;

@interface ZJMemoryProfiler () <ZJMemoryProfilerWindowTouchesDelegate>
{
    FBMemoryProfiler    *fbMemoryProfiler;
    ZJMemoryProfilerContainerViewController     *_containerViewController;
    ZJMemoryProfilerFloatingViewController      *_floatingViewController;
}

@property(nonatomic, strong) ZJMemoryProfilerWindow *memoryProfilerWindow;

@end

@implementation ZJMemoryProfiler

+ (nullable instancetype)sharedProfiler
{
    static ZJMemoryProfiler *sharedProfiler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedProfiler = [ZJMemoryProfiler new];
        sharedProfiler.lastFloatingCenter = CGPointMake(CGRectGetWidth([UIScreen mainScreen].bounds)/2+60, kZJFloatingViewHeight);
        sharedProfiler.autoCheckIntervalSeconds = 0;
    });
    return sharedProfiler;
}

- (instancetype)init
{
    return [self initWithPlugins:nil retainCycleDetectorConfiguration:nil];
}

- (instancetype)initWithPlugins:(NSArray<id<FBMemoryProfilerPluggable>> *)plugins retainCycleDetectorConfiguration:(FBObjectGraphConfiguration *)retainCycleDetectorConfiguration
{
    if (self = [super init]) {
        _fbPlugins = plugins;
        _retainCycleDetectorConfiguration = retainCycleDetectorConfiguration;
        self.lastFloatingCenter = CGPointMake(CGRectGetWidth([UIScreen mainScreen].bounds)/2+60, kZJFloatingViewHeight);
    }
    
    return self;
} 

- (void)enable
{
    // Put Memory profiler in status bar but save window for future reference when showing on screen
    _enabled = YES;
    
    _containerViewController = [ZJMemoryProfilerContainerViewController new];
    
    _memoryProfilerWindow = [[ZJMemoryProfilerWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _memoryProfilerWindow.touchesDelegate = self;
    _memoryProfilerWindow.rootViewController = _containerViewController;
    _memoryProfilerWindow.hidden = NO;
    
    if (fbMemoryProfiler) {
        [fbMemoryProfiler disable];
        fbMemoryProfiler = nil;
    }
    
    fbMemoryProfiler = [[FBMemoryProfiler alloc] initWithPlugins:_fbPlugins
                                retainCycleDetectorConfiguration:_retainCycleDetectorConfiguration];
    [fbMemoryProfiler addObserver:self forKeyPath:@"presentationMode"
                          options:NSKeyValueObservingOptionNew context:nil];
    [fbMemoryProfiler enable];
}

- (void)disable
{
    [fbMemoryProfiler disable];
    
    _memoryProfilerWindow = nil;
    
    _enabled = NO;
}

#pragma mark -

- (void)updateTopVCInfo
{
    [_floatingViewController updateTopVCInfo];
}

#pragma mark -

- (void)floatingViewControllerTapAction
{
    fbMemoryProfiler.presentationMode = FBMemoryProfilerPresentationModeFullWindow;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (fbMemoryProfiler.presentationMode == FBMemoryProfilerPresentationModeCondensed) {
        fbMemoryProfiler.presentationMode = FBMemoryProfilerPresentationModeDisabled;
        [self showFloatingView];
    }
    else if (fbMemoryProfiler.presentationMode == FBMemoryProfilerPresentationModeFullWindow) {
        [self hideFloatingView];
    }
}

#pragma mark - Floating button presentation

- (void)showFloatingView
{
    if (_floatingViewController) {
        [self hideFloatingView];
    }
    _floatingViewController = [[ZJMemoryProfilerFloatingViewController alloc] initWithPlugins:_fbPlugins
                                                             retainCycleDetectorConfiguration:_retainCycleDetectorConfiguration];
    
    _floatingViewController.autoCheckIntervalSeconds = _autoCheckIntervalSeconds;
    __weak typeof(self) wself = self;
    _floatingViewController.tapAction = ^(NSInteger times) {
        if (times == 2) {
            [wself floatingViewControllerTapAction];
        }
    };
    
    [_containerViewController presentViewController:_floatingViewController
                                           withSize:CGSizeMake(kZJFloatingViewHeight,
                                                               kZJFloatingViewHeight)];
    
    _floatingViewController.view.center = _lastFloatingCenter;
}

- (void)hideFloatingView
{
    _lastFloatingCenter = _floatingViewController.view.center;
    
    [_containerViewController dismissCurrentViewController];
    _floatingViewController = nil;
}

#pragma mark - ZJMemoryProfilerWindowTouchesDelegate

- (BOOL)window:(UIWindow *)window shouldReceiveTouchAtPoint:(CGPoint)point
{
    return CGRectContainsPoint(_floatingViewController.view.bounds,
                               [_floatingViewController.view convertPoint:point
                                                                 fromView:window]);
}

@end
