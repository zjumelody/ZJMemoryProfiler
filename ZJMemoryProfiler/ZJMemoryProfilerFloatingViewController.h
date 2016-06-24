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

typedef void(^ZJMemoryProfilerFloatingViewTapAction)();

@interface ZJMemoryProfilerFloatingViewController : UIViewController

@property(nonatomic, strong) UILabel *infoLabel;
@property(nonatomic, copy) ZJMemoryProfilerFloatingViewTapAction tapAction;

- (instancetype)initWithPlugins:(NSArray<id<FBMemoryProfilerPluggable>> *)plugins
retainCycleDetectorConfiguration:(FBObjectGraphConfiguration *)retainCycleDetectorConfiguration;

@end
