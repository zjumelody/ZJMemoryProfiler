//
//  ZJMemoryProfilerFloatingViewController.h
//  ZJMemoryProfilerDemo
//
//  Created by Melody on 16/6/23.
//  Copyright © 2016年 Melody. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <FBMemoryProfiler/FBMemoryProfilerPluggable.h>
#import <FBRetainCycleDetector/FBObjectGraphConfiguration.h>

typedef void(^ZJMemoryProfilerFloatingViewTapAction)(NSInteger times);

@interface ZJMemoryProfilerFloatingViewController : UIViewController

@property(nonatomic, strong) UILabel *infoLabel;
@property(nonatomic, copy) ZJMemoryProfilerFloatingViewTapAction tapAction;

@property(nonatomic, assign) NSInteger autoCheckIntervalSeconds;

@property(nonatomic, assign) BOOL enableCheckRetainCycles;

- (instancetype)initWithPlugins:(NSArray<id<FBMemoryProfilerPluggable>> *)plugins
retainCycleDetectorConfiguration:(FBObjectGraphConfiguration *)retainCycleDetectorConfiguration;

- (void)updateViewControllerInfo:(UIViewController *)viewController;
- (void)updateTopVCInfo;

@end
