//
//  LikeViewController.m
//  12_CoreAnimation_01_红包雨等
//
//  Created by — on 2020/8/4.
//  Copyright © 2020 CJL. All rights reserved.
//

#import "LikeViewController.h"
#import "LikeButton.h"

@interface LikeViewController ()

@end

@implementation LikeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.view.backgroundColor = [UIColor whiteColor];
    
//    添加点赞按钮
    [self setupBtn];
    
}

- (void)setupBtn{
    LikeButton *btn = [LikeButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(200, 150, 30, 130);
    [btn setImage:[UIImage imageNamed:@"dislike"] forState:UIControlStateNormal];
    [btn setImage:[UIImage imageNamed:@"like_orange"] forState:UIControlStateSelected];
    [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:btn];
}

- (void)btnClick:(UIButton *)button{
    
    if (!button.selected) {
        NSLog(@"点赞");
    }else{
        NSLog(@"取消点赞");
    }
    button.selected = !button.selected;
}


@end
