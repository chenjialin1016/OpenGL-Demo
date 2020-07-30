//
//  ViewController.m
//  10_GLSL_01
//
//  Created by 陈嘉琳 on 2020/7/28.
//

#import "ViewController.h"
#import "MyView.h"

@interface ViewController ()

@property (nonnull, strong) MyView *myView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.myView = (MyView *)self.view;
}


@end
