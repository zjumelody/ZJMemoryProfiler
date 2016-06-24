//
//  SecondViewController.m
//  ZJMemoryProfilerDemo
//
//  Created by Melody on 16/6/23.
//  Copyright © 2016年 Melody. All rights reserved.
//

#import "SecondViewController.h"
#import "ThirdViewController.h"


typedef void(^MyBlock)();

@interface SecondViewController ()
{
    MyBlock myBlock;
}

@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSStringFromClass([self class]);
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - 200) / 2.0, 100, 200, 50);
    [button setTitle:@"ThirdViewController" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
//    __weak typeof(self) wself = self;
    myBlock = ^() {
        // make a memory leak test
        self.view.backgroundColor = [UIColor whiteColor];
    };
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)buttonClicked:(id)sender
{
    ThirdViewController *vc = [[ThirdViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}


@end
