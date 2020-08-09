//
//  RainViewController.m
//  12_CoreAnimation_01_红包雨等
//
//  Created by — on 2020/8/4.
//  Copyright © 2020 CJL. All rights reserved.
//

#import "RainViewController.h"

@interface RainViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *backImageView;

@property (nonatomic, strong) CAEmitterLayer *rainLayer;

@end

@implementation RainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupBtns];
    
    [self setupEmitter];
}

- (void)setupBtns{
    
    // 下雨按钮
    UIButton * startBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:startBtn];
    startBtn.frame = CGRectMake(20, self.view.bounds.size.height - 60, 80, 40);
    startBtn.backgroundColor = [UIColor whiteColor];
    [startBtn setTitle:@"雨停了" forState:UIControlStateNormal];
    [startBtn setTitle:@"下雨" forState:UIControlStateSelected];
    [startBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [startBtn setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
    [startBtn addTarget:self action:@selector(beginOrStopRain:) forControlEvents:UIControlEventTouchUpInside];
    
    // 雨量按钮
    UIButton * rainBIgBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:rainBIgBtn];
    rainBIgBtn.tag = 100;
    rainBIgBtn.frame = CGRectMake(self.view.center.x-40, self.view.bounds.size.height - 60, 80, 40);
    rainBIgBtn.backgroundColor = [UIColor whiteColor];
    [rainBIgBtn setTitle:@"下大点" forState:UIControlStateNormal];
    [rainBIgBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [rainBIgBtn addTarget:self action:@selector(bigOrSmallRain:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton * rainSmallBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:rainSmallBtn];
    rainSmallBtn.tag = 200;
    rainSmallBtn.frame = CGRectMake(self.view.frame.size.width-100, self.view.bounds.size.height - 60, 80, 40);
    rainSmallBtn.backgroundColor = [UIColor whiteColor];
    [rainSmallBtn setTitle:@"下小点" forState:UIControlStateNormal];
    [rainSmallBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [rainSmallBtn addTarget:self action:@selector(bigOrSmallRain:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark ---- segement method
- (void)selectItem:(UISegmentedControl*)segment{
    
}

- (void)beginOrStopRain:(UIButton*)sender{
    if (sender.selected) {
        NSLog(@"开始下雨");
        
        [self.rainLayer setValue:@1.f forKeyPath:@"birthRate"];
    }else{
        NSLog(@"雨停了");
        [self.rainLayer setValue:@0.f forKeyPath:@"birthRate"];
    }
    
    sender.selected = !sender.selected;
}

- (void)bigOrSmallRain:(UIButton*)sender{
    
    NSInteger rate = 5;
    CGFloat scale = 0.05;
    
    if (sender.tag == 100) {
        NSLog(@"下大点");
        
        if (self.rainLayer.birthRate < 30) {
            [self.rainLayer setValue:@(self.rainLayer.birthRate + rate) forKeyPath:@"birthRate"];
            [self.rainLayer setValue:@(self.rainLayer.scale + scale) forKeyPath:@"scale"];
        }
        
    }else if (sender.tag == 200){
        NSLog(@"下小点");
        
        if (self.rainLayer.birthRate > 1) {
           [self.rainLayer setValue:@(self.rainLayer.birthRate - rate) forKeyPath:@"birthRate"];
           [self.rainLayer setValue:@(self.rainLayer.scale - scale) forKeyPath:@"scale"];
       }
    }
}

#pragma mark ---- emitter
- (void)setupEmitter{
    
//    1、创建emitterLayer
    CAEmitterLayer *rainLayer = [CAEmitterLayer layer];
//    2、在背景图上添加粒子图层
    [self.backImageView.layer addSublayer:rainLayer];
    self.rainLayer = rainLayer;
    
//    3、设置粒子图层
    rainLayer.emitterShape = kCAEmitterLayerLine;
    //发射模式
    rainLayer.emitterMode = kCAEmitterLayerSurface;
    //发射源大小
    rainLayer.emitterSize = self.view.frame.size;
    //发射源位置 y最好不要设置为0 最好<0
    rainLayer.emitterPosition = CGPointMake(self.view.bounds.size.width*0.5, -10);
    
//    4、配置cell
    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    //粒子内容
    cell.contents = (id)[[UIImage imageNamed:@"rain_white"] CGImage];
    //每秒产生的粒子数量的系数
    cell.birthRate = 25.f;
    //粒子的生命周期
    cell.lifetime = 20.f;
    //speed粒子速度.图层的速率。用于将父时间缩放为本地时间，例如，如果速率是2，则本地时间的进度是父时间的两倍。默认值为1。
    cell.speed = 10.f;
    //粒子速度系数, 默认1.0
    cell.velocity = 10.f;
    //每个发射物体的初始平均范围,默认等于0
    cell.velocityRange = 10.f;
    //粒子在y方向的加速的
    cell.yAcceleration = 1000.f;
    //粒子缩放比例: scale
    cell.scale = 0.1;
    //粒子缩放比例范围:scaleRange
    cell.scaleRange = 0.f;
    
//    5、cell添加到图层上
    rainLayer.emitterCells = @[cell];
    
}

@end
