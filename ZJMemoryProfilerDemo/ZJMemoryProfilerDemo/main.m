//
//  main.m
//  ZJMemoryProfilerDemo
//
//  Created by Melody on 16/6/22.
//  Copyright © 2016年 Melody. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

#import <FBAllocationTracker/FBAllocationTrackerManager.h>

int main(int argc, char * argv[]) {
    @autoreleasepool {
        
        [[FBAllocationTrackerManager sharedManager] startTrackingAllocations];
        [[FBAllocationTrackerManager sharedManager] enableGenerations];
        
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
