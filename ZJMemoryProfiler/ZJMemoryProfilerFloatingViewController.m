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
    NSMutableAttributedString   *attributedText;
    UITapGestureRecognizer      *_tapGestureRecognizer;
    
    NSArray<id<FBMemoryProfilerPluggable>> *fbPlugins;
    FBObjectGraphConfiguration      *_retainCycleDetectorConfiguration;
}

@property(nonatomic, assign) BOOL hasALeak;
@property(nonatomic, assign) BOOL lastLeakStatus;

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
    _lastLeakStatus = NO;
    
    [self setupInfoLabel];
    
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizer:)];
    [self.view addGestureRecognizer:_tapGestureRecognizer];
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
//    _infoLabel.alpha = 0.5;
    _infoLabel.text = @"";
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
    
    timer = [NSTimer scheduledTimerWithTimeInterval:1
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
    [self updateInfoLabel];
}

- (void)updateInfoLabel
{
    NSByteCountFormatter *_byteCountFormatter;
    _byteCountFormatter = [NSByteCountFormatter new];
//    NSString *memstring = [_byteCountFormatter stringFromByteCount:ZJMemoryProfilerResidentMemoryInBytes()];
    long long int memoryInBytes = ZJMemoryProfilerResidentMemoryInBytes();
    
    FBAllocationTrackerSummary *currentSummary = nil;
    NSArray *allData = [[FBAllocationTrackerManager sharedManager] currentSummaryForGenerations];
    if (allData.count > 0) {
        NSArray *array = allData[0];
        for (FBAllocationTrackerSummary * summary in array) {
            if ([summary.className isEqualToString:NSStringFromClass([[self currentViewController] class])]) {
                currentSummary = summary;
                break;
            }
        }
    }
    
    NSString *currentBytes = @"-";
    if (currentSummary) {
        NSInteger alive = currentSummary.aliveObjects;
        NSInteger byteCount = alive * currentSummary.instanceSize;
        currentBytes = [NSString stringWithFormat:@"%ld(%@)", (long)alive, [_byteCountFormatter stringFromByteCount:byteCount]];
//        NSLog(@"%@", currentSummary.className);
        
        [self findRetainCyclesForClassesNamed:@[currentSummary.className]];
    }
    
    NSString *infoString = [NSString stringWithFormat:@"%.3f MB\n%@", memoryInBytes/1024.0f/1024.0f, currentBytes];
    attributedText = [[NSMutableAttributedString alloc] initWithString:infoString
                                                            attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:10.0f]}];
    if (_hasALeak) {
        [attributedText addAttribute:NSForegroundColorAttributeName
                               value:[UIColor redColor]
                               range:NSMakeRange([infoString rangeOfString:@"MB"].location + 2,
                                                 infoString.length - [infoString rangeOfString:@"MB"].location - 2)];
    }
    
    _infoLabel.attributedText = attributedText;
    
    CGRect rect = [attributedText boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                               context:nil];
    CGPoint lastCenter = self.view.center;
    CGRect frame = self.view.frame;
    frame.size.width = rect.size.width + 3;
    frame.size.height = rect.size.height;
    self.view.frame = frame;
    self.view.center = lastCenter;
    _infoLabel.frame = self.view.bounds;
}

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

#pragma mark -

- (void)tapGestureRecognizer:(id)sender
{
    if (_tapAction) {
        _tapAction();
    }
}

#pragma mark - 

- (void)findRetainCyclesForClassesNamed:(NSArray<NSString *> *)classesNamed
{
    __weak typeof(self) wself = self;
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (NSString *className in classesNamed) {
            Class aCls = NSClassFromString(className);
            NSArray *objects = [[FBAllocationTrackerManager sharedManager] instancesForClass:aCls
                                                                                inGeneration:0];
            FBObjectGraphConfiguration *configuration = _retainCycleDetectorConfiguration ?: [FBObjectGraphConfiguration new];
            FBRetainCycleDetector *detector = [[FBRetainCycleDetector alloc] initWithConfiguration:configuration];
            
            for (id object in objects) {
                [detector addCandidate:object];
            }
            
            NSSet<NSArray<FBObjectiveCGraphElement *> *> *retainCycles =
            [detector findRetainCyclesWithMaxCycleLength:8];
            
            for (id<FBMemoryProfilerPluggable> plugin in fbPlugins) {
                if ([plugin respondsToSelector:@selector(memoryProfilerDidFindRetainCycles:)]) {
                    [plugin memoryProfilerDidFindRetainCycles:retainCycles];
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                wself.lastLeakStatus = wself.hasALeak;
                if ([retainCycles count] > 0) {
                    // We've got a leak
                    wself.hasALeak = YES;
                }
                else {
                    wself.hasALeak = NO;
                }
                if (wself.lastLeakStatus != wself.hasALeak) {
                    [wself updateInfoLabel];
                }
                wself.lastLeakStatus = wself.hasALeak;
            });
        }
//    });
}

#pragma mark -

- (UIViewController *)findBestViewController:(UIViewController*)vc
{
    if (vc.presentedViewController) {
        
        // Return presented view controller
        return [self findBestViewController:vc.presentedViewController];
        
    } else if ([vc isKindOfClass:[UISplitViewController class]]) {
        
        // Return right hand side
        UISplitViewController* svc = (UISplitViewController*) vc;
        if (svc.viewControllers.count > 0)
            return [self findBestViewController:svc.viewControllers.lastObject];
        else
            return vc;
        
    } else if ([vc isKindOfClass:[UINavigationController class]]) {
        
        // Return top view
        UINavigationController* svc = (UINavigationController*) vc;
        if (svc.viewControllers.count > 0)
            return [self findBestViewController:svc.topViewController];
        else
            return vc;
        
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        
        // Return visible view
        UITabBarController* svc = (UITabBarController*) vc;
        if (svc.viewControllers.count > 0)
            return [self findBestViewController:svc.selectedViewController];
        else
            return vc;
        
    } else {
        
        // Unknown view controller type, return last child view controller
        return vc;
        
    }
    
}

- (UIViewController *)currentViewController
{
    // Find best view controller
    UIViewController* viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    return [self findBestViewController:viewController];
}

@end
