//
//  BaseViewController.m
//  ZJMemoryProfilerDemo
//
//  Created by Melody on 16/6/30.
//  Copyright © 2016年 Melody. All rights reserved.
//

#import "BaseViewController.h"
#import "ZJMemoryProfiler.h"

@interface BaseViewController ()

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[ZJMemoryProfiler sharedProfiler] updateViewControllerInfo:self];
}

@end
