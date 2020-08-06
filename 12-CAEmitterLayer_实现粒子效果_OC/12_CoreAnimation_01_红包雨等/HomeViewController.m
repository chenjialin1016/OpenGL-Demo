//
//  HomeViewController.m
//  12_CoreAnimation_01_红包雨等
//
//  Created by — on 2020/8/4.
//  Copyright © 2020 CJL. All rights reserved.
//

#import "HomeViewController.h"
#import "ViewController.h"
#import "LikeViewController.h"
#import "ColorBallViewController.h"
#import "RainViewController.h"

@interface HomeViewController ()

@property (nonatomic, strong) NSArray *dataArr;
@property (nonatomic, strong) NSArray *vcArr;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dataArr = @[@"红包雨等 粒子效果", @"点赞 粒子效果", @"烟花 粒子效果", @"雨 粒子效果"];
   
    ViewController *firstVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"FirstVC"];
    
    LikeViewController *likeVC = [[LikeViewController alloc] init];
    
    ColorBallViewController *colorBallVC = [[ColorBallViewController alloc] init];
    
    RainViewController *rainVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"RainVC"];
    
    self.vcArr = @[firstVC, likeVC, colorBallVC, rainVC];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
   
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    
    return self.dataArr.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.textLabel.text = self.dataArr[indexPath.row];
    
    return  cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [self.navigationController pushViewController:self.vcArr[indexPath.row] animated:true];
}


@end
