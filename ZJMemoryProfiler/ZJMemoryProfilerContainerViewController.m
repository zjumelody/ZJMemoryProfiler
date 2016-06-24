//
//  ZJMemoryProfilerContainerViewController.m
//  ZJMemoryProfilerDemo
//
//  Created by Melody on 16/6/23.
//  Copyright © 2016年 Melody. All rights reserved.
//

#import "ZJMemoryProfilerContainerViewController.h"
#import <tgmath.h>

@interface ZJMemoryProfilerContainerViewController ()
{
    UIViewController        *_presentedViewController;
    UIPanGestureRecognizer  *_panGestureRecognizer;
    
    CGSize  _size;
}

@end

@implementation ZJMemoryProfilerContainerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

CGFloat FBMemoryProfilerRoundPixelValue(CGFloat value) {
    CGFloat scale = [[UIScreen mainScreen] scale];
    return roundf(value * scale) / scale;
}

- (void)presentViewController:(UIViewController *)viewController
                     withSize:(CGSize)size
{
    if (_presentedViewController) {
        [self dismissCurrentViewController];
    }
    
    _presentedViewController = viewController;
    _size = size;
    CGSize adjustedSize = CGSizeMake(MIN(_size.width, CGRectGetWidth(self.view.bounds)),
                                     MIN(_size.height, CGRectGetHeight(self.view.bounds)));
    
    // Put content right under status bar, in the middle
    CGFloat heightOffset = 20;
    CGFloat widthOffset = FBMemoryProfilerRoundPixelValue((CGRectGetWidth(self.view.bounds) - adjustedSize.width) / 2.0);
    
    CGRect frame = CGRectMake(widthOffset, heightOffset, adjustedSize.width, adjustedSize.height);
    
    [self addChildViewController:_presentedViewController];
    _presentedViewController.view.frame = frame;
    [self.view addSubview:_presentedViewController.view];
    
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_pan)];
    _panGestureRecognizer.minimumNumberOfTouches = 1;
    _panGestureRecognizer.maximumNumberOfTouches = 1;
    [_presentedViewController.view addGestureRecognizer:_panGestureRecognizer];
    
    [_presentedViewController didMoveToParentViewController:self];
}

- (void)dismissCurrentViewController
{
    if (!_presentedViewController) {
        return;
    }
    
    [_presentedViewController willMoveToParentViewController:nil];
    
    [_panGestureRecognizer removeTarget:self action:NULL];
    _panGestureRecognizer = nil;
    
    [_presentedViewController.view removeFromSuperview];
    [_presentedViewController removeFromParentViewController];
}

- (void)_pan
{
    CGPoint translation = [_panGestureRecognizer translationInView:self.view];
    
    CGPoint center = _presentedViewController.view.center;
    center.x += translation.x;
    center.y += translation.y;
    
    CGFloat centerHeightOffset = FBMemoryProfilerRoundPixelValue(CGRectGetHeight(_presentedViewController.view.frame) / 2.0);
    CGFloat centerWidthOffset = FBMemoryProfilerRoundPixelValue(CGRectGetWidth(_presentedViewController.view.frame) / 2.0);
    
    // Make sure it stays on screen
    if (center.y - centerHeightOffset < 0) {
        center.y = centerHeightOffset;
    }
    if (center.x - centerWidthOffset < 0) {
        center.x = centerWidthOffset;
    }
    
    CGFloat maximumY = CGRectGetHeight(self.view.bounds) -  CGRectGetHeight(_presentedViewController.view.frame);
    if (center.y - centerHeightOffset > maximumY) {
        center.y = maximumY + centerHeightOffset;
    }
    
    CGFloat maximumX = CGRectGetWidth(self.view.bounds) - CGRectGetWidth(_presentedViewController.view.frame);
    if (center.x - centerWidthOffset > maximumX) {
        center.x = maximumX + centerWidthOffset;
    }
    
    _presentedViewController.view.center = center;
    
    [_panGestureRecognizer setTranslation:CGPointZero inView:self.view];
}

#pragma mark Rotations

- (UIViewController *)_viewControllerDecidingAboutRotations
{
#if _INTERNAL_IMP_ENABLED_
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    UIViewController *viewController = window.rootViewController;
    SEL viewControllerForSupportedInterfaceOrientationsSelector =
    NSSelectorFromString(@"_viewControllerForSupportedInterfaceOrientations");
    if ([viewController respondsToSelector:viewControllerForSupportedInterfaceOrientationsSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        viewController = [viewController performSelector:viewControllerForSupportedInterfaceOrientationsSelector];
#pragma clang diagnostic pop
    }
    return viewController;
#else
    return self;
#endif // _INTERNAL_IMP_ENABLED_
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    UIViewController *viewControllerToAsk = [self _viewControllerDecidingAboutRotations];
    UIInterfaceOrientationMask supportedOrientations = UIInterfaceOrientationMaskAll;
    if (viewControllerToAsk && viewControllerToAsk != self) {
        supportedOrientations = [viewControllerToAsk supportedInterfaceOrientations];
    }
    
    return supportedOrientations;
}

- (BOOL)shouldAutorotate
{
    UIViewController *viewControllerToAsk = [self _viewControllerDecidingAboutRotations];
    BOOL shouldAutorotate = YES;
    if (viewControllerToAsk && viewControllerToAsk != self) {
        shouldAutorotate = [viewControllerToAsk shouldAutorotate];
    }
    return shouldAutorotate;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                         duration:(NSTimeInterval)duration
{
    // We did rotate, we should update frame of contained window (it was depending on bounds)
    CGSize adjustedSize = CGSizeMake(MIN(_size.width, CGRectGetWidth(self.view.bounds)),
                                     MIN(_size.height, CGRectGetHeight(self.view.bounds)));
    
    CGFloat widthOffset = MIN(_presentedViewController.view.frame.origin.x,
                              CGRectGetWidth(self.view.bounds) - adjustedSize.width);
    CGFloat heightOffset = MIN(_presentedViewController.view.frame.origin.y,
                               CGRectGetHeight(self.view.bounds) - adjustedSize.height);
    
    CGRect frame = CGRectMake(widthOffset, heightOffset, adjustedSize.width, adjustedSize.height);
    
    [UIView animateWithDuration:duration animations:^{
        _presentedViewController.view.frame = frame;
    }];
    
}

@end
