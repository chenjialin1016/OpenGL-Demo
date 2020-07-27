//
//  ViewController.m
//  08_GLKit_OC
//
//  Created by 陈嘉琳 on 2020/7/24.
//  Copyright © 2020 CJL. All rights reserved.
//

#import "ViewController.h"
#import "CAViewController.h"


@interface ViewController ()


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
   
}
- (IBAction)btnClick:(id)sender {
    CAViewController *vc = [[CAViewController alloc] init];
    [self presentViewController:vc animated:true completion:nil];
    
}



@end
