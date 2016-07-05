//
//  ZJMemoryProfiler.h
//  ZJMemoryProfilerDemo
//
//  Created by Melody on 16/6/22.
//  Copyright © 2016年 Melody. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for ZJMemoryProfiler.
FOUNDATION_EXPORT double ZJMemoryProfilerVersionNumber;

//! Project version string for ZJMemoryProfiler.
FOUNDATION_EXPORT const unsigned char ZJMemoryProfilerVersionString[];

#import <UIKit/UIKit.h>

#import <FBMemoryProfiler/FBMemoryProfilerPluggable.h>
#import <FBRetainCycleDetector/FBObjectGraphConfiguration.h>

/**
 This will protect some internal parts that could use dangerous paths like private API's.
 Memory Profiler should be safe to use even without them, it's just going to have missing features.
 */
#ifdef ZJ_MEMORY_TOOLS
#define _INTERNAL_IMP_ENABLED_ (ZJ_MEMORY_TOOLS)
#else
#define _INTERNAL_IMP_ENABLED_ DEBUG
#endif // FB_MEMORY_TOOLS

@interface ZJMemoryProfiler : NSObject

+ (nullable instancetype)sharedProfiler;

/**
 Designated initializer
 @param plugins Plugins can take up some behavior like cache cleaning when we are working with profiler.
 Check FBMemoryProfilerPluggable for details.
 @param retainCycleDetectorConfiguration Retain cycle detector will use this configuration to determine how it should
 walk on object graph, check FBObjectGraphConfiguration to see what options you can define.
 @see FBObjectGraphConfiguration
 */
- (nonnull instancetype)initWithPlugins:(nullable NSArray<id<FBMemoryProfilerPluggable>> *)plugins
       retainCycleDetectorConfiguration:(nullable FBObjectGraphConfiguration *)retainCycleDetectorConfiguration NS_DESIGNATED_INITIALIZER;

- (void)enable;
- (void)disable;

@property (nonatomic, assign, getter=isEnabled) BOOL enabled;

@property(nonatomic, assign) CGPoint lastFloatingCenter;

@property(nonatomic, strong, nullable) NSArray<id<FBMemoryProfilerPluggable>> *fbPlugins;
@property(nonatomic, strong, nullable) FBObjectGraphConfiguration     *retainCycleDetectorConfiguration;

@property(nonatomic, assign) BOOL enableCheckRetainCycles;

- (void)updateViewControllerInfo:(nonnull UIViewController *)viewController;
- (void)updateTopVCInfo;

@property(nonatomic, assign) NSInteger autoCheckIntervalSeconds;

@end
