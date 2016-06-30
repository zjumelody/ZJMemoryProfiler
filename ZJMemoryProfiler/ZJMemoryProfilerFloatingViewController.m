//
//  ZJMemoryProfilerFloatingViewController.m
//  ZJMemoryProfilerDemo
//
//  Created by Melody on 16/6/23.
//  Copyright © 2016年 Melody. All rights reserved.
//

#import "ZJMemoryProfilerFloatingViewController.h"
#import "mach/mach.h"
#import <FBAllocationTracker/FBAllocationTrackerManager.h>
#import <FBAllocationTracker/FBAllocationTrackerSummary.h>
#import <FBRetainCycleDetector/FBRetainCycleDetector.h>

@interface ZJMemoryProfilerFloatingViewController ()
{
    NSTimer     *timer;
    
    NSString                    *infoString;
    NSMutableAttributedString   *attributedText;
    UITapGestureRecognizer      *onceTapGestureRecognizer;
    UITapGestureRecognizer      *doubleTapGestureRecognizer;
    
    NSArray<id<FBMemoryProfilerPluggable>> *fbPlugins;
    FBObjectGraphConfiguration      *_retainCycleDetectorConfiguration;
    
    NSArray     *summaryData;
    long long int totalMemory;
    NSString    *topVCMemory;
    NSString    *lastTopVCName;
    
    NSInteger   autoProfilerCount;
    
    NSByteCountFormatter *_byteCountFormatter;
    
    BOOL    needToRecheckTopVC;
}

@property(nonatomic, assign) BOOL hasALeak;
@property(nonatomic, assign) BOOL isCheckingTopVC;
@property(nonatomic, strong) FBAllocationTrackerSummary *currentSummary;

@end

@implementation ZJMemoryProfilerFloatingViewController

- (instancetype)init
{
    return [self initWithPlugins:nil retainCycleDetectorConfiguration:nil];
}

- (instancetype)initWithPlugins:(NSArray<id<FBMemoryProfilerPluggable>> *)plugins
retainCycleDetectorConfiguration:(FBObjectGraphConfiguration *)retainCycleDetectorConfiguration
{
    if (self = [super init]) {
        fbPlugins = plugins;
        _retainCycleDetectorConfiguration = retainCycleDetectorConfiguration;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor lightGrayColor];
    self.view.alpha = 0.8f;
    
    _hasALeak = NO;
    _isCheckingTopVC = NO;
    needToRecheckTopVC = NO;
    autoProfilerCount = 0;
    
    topVCMemory = @"-";
    lastTopVCName = nil;
    
    _byteCountFormatter = [NSByteCountFormatter new];
    
    [self setupInfoLabel];
    
    onceTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                       action:@selector(onceTapGestureRecognizer:)];
    [self.view addGestureRecognizer:onceTapGestureRecognizer];
    
    doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                         action:@selector(doubleTapGestureRecognizer:)];
    doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTapGestureRecognizer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setupTimer];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [timer invalidate];
    timer = nil;
}

#pragma mark -

- (void)setupInfoLabel
{
    _infoLabel = [[UILabel alloc] initWithFrame:self.view.bounds];
    _infoLabel.backgroundColor = [UIColor clearColor];
    _infoLabel.textColor = [UIColor whiteColor];
    _infoLabel.textAlignment = NSTextAlignmentCenter;
    _infoLabel.numberOfLines = 0;
    [self.view addSubview:_infoLabel];
}

- (void)setupTimer
{
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
    
    timer = [NSTimer scheduledTimerWithTimeInterval:2
                                             target:self
                                           selector:@selector(timer:)
                                           userInfo:nil
                                            repeats:YES];
//    NSRunLoop *main = [NSRunLoop currentRunLoop];
//    [main addTimer:timer forMode:NSRunLoopCommonModes];
    [timer fire];
}

- (void)timer:(id)sender
{
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [wself updateTotalMemory];
    });
    
    autoProfilerCount++;
    if (_isCheckingTopVC) {
        autoProfilerCount = 0;
    }
    else if (needToRecheckTopVC ||
             (_autoCheckIntervalSeconds > 0 && autoProfilerCount >= _autoCheckIntervalSeconds) ||
             ([topVCMemory isEqualToString:@"-"] || [topVCMemory isEqualToString:@"..."])) {
        
        needToRecheckTopVC = NO;
        [self checkTopVC];
    }
}

#pragma mark - Data

- (void)updateTotalMemory
{
    totalMemory = ZJMemoryProfilerResidentMemoryInBytes();
    [self updateInfoLabel];
}

- (void)updateInfoLabel
{
    infoString = [NSString stringWithFormat:@"%.3f MB\n%@", totalMemory/1024.0f/1024.0f, topVCMemory];
    attributedText = [[NSMutableAttributedString alloc] initWithString:infoString
                                                            attributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:10.0f]}];
    
    [self updateInfoLabelStatus];
    
    CGRect rect = [attributedText boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                               context:nil];
    CGPoint lastCenter = self.view.center;
    CGRect frame = self.view.frame;
    frame.size.width = rect.size.width + 3;
    frame.size.height = rect.size.height;
    __weak typeof(self) wself = self;
    [UIView animateWithDuration:0.1f animations:^{
        wself.view.frame = frame;
        wself.view.center = lastCenter;
        wself.infoLabel.frame = self.view.bounds;
    }];
}

- (void)updateInfoLabelStatus
{
    NSInteger location = [infoString rangeOfString:@"MB"].location + 2;
    NSInteger length = infoString.length - location;
    if (infoString.length > location && length > 0) {
        UIColor *color = [UIColor whiteColor];
        if (!_isCheckingTopVC && ![topVCMemory isEqualToString:@"-"] && ![topVCMemory isEqualToString:@"..."]) {
            color = _hasALeak ? [UIColor redColor] : [UIColor greenColor];
        }
        [attributedText addAttribute:NSForegroundColorAttributeName
                               value:color
                               range:NSMakeRange(location, length)];
    }
    _infoLabel.attributedText = attributedText;
}

- (void)checkTopVC
{
    if (_isCheckingTopVC ||
        ![[FBAllocationTrackerManager sharedManager] isAllocationTrackerEnabled]) {
        needToRecheckTopVC = YES;
        return;
    }
    
    autoProfilerCount = 0;
    _isCheckingTopVC = YES;
    _hasALeak = NO;
    topVCMemory = @"...";
    [self performSelectorOnMainThread:@selector(updateInfoLabel) withObject:nil waitUntilDone:YES];
    
    summaryData = [[FBAllocationTrackerManager sharedManager] currentSummaryForGenerations];
    
    _currentSummary = nil;
    
    if (summaryData.count > 0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            __weak typeof(self) wself = self;
            for (int i = 0; i < summaryData.count; i++) {
                NSArray *array = summaryData[i];
                for (FBAllocationTrackerSummary * summary in array) {
                    if ([summary.className isEqualToString:NSStringFromClass([[self currentViewController] class])]) {
                        wself.currentSummary = summary;
                        break;
                    }
                }
                if (wself.currentSummary) {
                    break;
                }
            }
            if (wself.currentSummary) {
//                if ([wself.currentSummary.className isEqualToString:@"UIAlertController"]) {
//                    wself.isCheckingTopVC = NO;
//                    return;
//                }
//                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [wself updateTopVCMemory];
                    });
//                }
            }
            else {
                wself.isCheckingTopVC = NO;
                topVCMemory = @"-";
                [wself updateInfoLabel];
            }
        });
    }
    else {
        _isCheckingTopVC = NO;
        topVCMemory = @"-";
        [self updateInfoLabel];
    }
}

- (void)updateTopVCMemory
{
    long alive = _currentSummary.aliveObjects;
    long byteCount = alive * _currentSummary.instanceSize;
    NSMutableString *string = [NSMutableString stringWithString:@""];
//    NSLog(@"%li", byteCount);
//    topVCMemory = [NSString stringWithFormat:@"%ld(%@)", (long)alive,
//                   [_byteCountFormatter stringFromByteCount:byteCount]];
//    byteCount = 123456;
    if (byteCount < 1000) {
        [string appendFormat:@"%li bytes", byteCount];
    }
    else if (byteCount < 1000 * 1000) {
        [string appendFormat:@"%.3f KB", byteCount / 1000.0];
    }
    else if (byteCount < 1000 * 1000 * 1000) {
        [string appendFormat:@"%.3f MB", byteCount / 1000.0 / 1000.0];
    }
    [string appendFormat:@" (%ld)", (long)alive];
    topVCMemory = string;
    
    [self updateInfoLabel];
    
    if (_currentSummary.className) {
//        NSLog(@"%@", _currentSummary.className);
        [self findRetainCyclesForClassName:_currentSummary.className];
    }
    else {
        _isCheckingTopVC = NO;
        topVCMemory = @"-";
        [self updateInfoLabel];
    }
}

- (void)findRetainCyclesForClassName:(NSString *)className
{
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Class aCls = NSClassFromString(className);
        NSArray *objects = [[FBAllocationTrackerManager sharedManager] instancesForClass:aCls
                                                                            inGeneration:0];
        FBObjectGraphConfiguration *configuration = _retainCycleDetectorConfiguration ?: [FBObjectGraphConfiguration new];
        FBRetainCycleDetector *detector = [[FBRetainCycleDetector alloc] initWithConfiguration:configuration];
        
        for (id object in objects) {
            [detector addCandidate:object];
        }
        
        NSSet<NSArray<FBObjectiveCGraphElement *> *> *retainCycles = [detector findRetainCyclesWithMaxCycleLength:8];
        
        for (id<FBMemoryProfilerPluggable> plugin in fbPlugins) {
            if ([plugin respondsToSelector:@selector(memoryProfilerDidFindRetainCycles:)]) {
                [plugin memoryProfilerDidFindRetainCycles:retainCycles];
            }
        }
        
        if ([className isEqualToString:NSStringFromClass([[self currentViewController] class])]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([retainCycles count] > 0) {
                    // We've got a leak
                    wself.hasALeak = YES;
                }
                else {
                    wself.hasALeak = NO;
                }
                wself.isCheckingTopVC = NO;
                [wself updateInfoLabelStatus];
            });
        }
        else {
            wself.isCheckingTopVC = NO;
            [wself checkTopVC];
        }
    });
}

#pragma mark - Action

- (void)onceTapGestureRecognizer:(id)sender
{
    [self checkTopVC];
    
    if (_tapAction) {
        _tapAction(1);
    }
}

- (void)doubleTapGestureRecognizer:(id)sender
{
    if (_tapAction) {
        _tapAction(2);
    }
}

- (void)updateTopVCInfo
{
    _hasALeak = NO;
    topVCMemory = @"...";
    [self performSelectorOnMainThread:@selector(updateInfoLabel) withObject:nil waitUntilDone:YES];
    
    [self checkTopVC];
}

#pragma mark - others

uint64_t ZJMemoryProfilerResidentMemoryInBytes() {
    kern_return_t rval = 0;
    mach_port_t task = mach_task_self();
    
    struct task_basic_info info = {0};
    mach_msg_type_number_t tcnt = TASK_BASIC_INFO_COUNT;
    task_flavor_t flavor = TASK_BASIC_INFO;
    
    task_info_t tptr = (task_info_t) &info;
    
    if (tcnt > sizeof(info))
        return 0;
    
    rval = task_info(task, flavor, tptr, &tcnt);
    if (rval != KERN_SUCCESS) {
        return 0;
    }
    
    return info.resident_size;
}

- (UIViewController *)findBestViewController:(UIViewController*)vc
{
    if (vc.presentedViewController) {
        // Return presented view controller
        return [self findBestViewController:vc.presentedViewController];
    }
    else if ([vc isKindOfClass:[UISplitViewController class]]) {
        // Return right hand side
        UISplitViewController *svc = (UISplitViewController *)vc;
        if (svc.viewControllers.count > 0) {
            return [self findBestViewController:svc.viewControllers.lastObject];
        }
        else {
            return vc;
        }
    }
    else if ([vc isKindOfClass:[UINavigationController class]]) {
        // Return top view
        UINavigationController *svc = (UINavigationController *)vc;
        if (svc.viewControllers.count > 0) {
            return [self findBestViewController:svc.topViewController];
        }
        else {
            return vc;
        }
    }
    else if ([vc isKindOfClass:[UITabBarController class]]) {
        // Return visible view
        UITabBarController *svc = (UITabBarController *)vc;
        if (svc.viewControllers.count > 0) {
            return [self findBestViewController:svc.selectedViewController];
        }
        else {
            return vc;
        }
    }
    else {
        // Unknown view controller type, return last child view controller
        return vc;
    }
}

- (UIViewController *)currentViewController
{
    // Find best view controller
    UIViewController *viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    return [self findBestViewController:viewController];
}

@end
