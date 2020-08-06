//
//  ViewController.m
//  12_CoreAnimation_01_红包雨等
//
//  Created by — on 2020/8/4.
//  Copyright © 2020 CJL. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong) CAEmitterLayer *rainlayer;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segementControl;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.segementControl.selectedSegmentIndex = 0;
    [self.segementControl addTarget:self action:@selector(selectItem:) forControlEvents:UIControlEventValueChanged];
    
    [self zongZiRain];
}



- (void)selectItem:(UISegmentedControl *)sender {
    
    NSLog(@"sender %d", sender.selectedSegmentIndex);
    [self.rainlayer removeFromSuperlayer];
    
    switch (sender.selectedSegmentIndex) {
        case 0:
            [self zongZiRain];
            break;
        case 1:
            [self hongBaoRain];
            break;
        case 2:
            [self jingBiRain];
            break;
        default:
            [self allRain];
            break;
    }
}

- (void)zongZiRain{
//    1、设置CAEmitterLayer
    CAEmitterLayer *rainLayer = [CAEmitterLayer layer];
    
//    2、在背景图上添加粒子图层
    [self.view.layer addSublayer:rainLayer];
    self.rainlayer = rainLayer;
    
//    3、发射形状--线性
    rainLayer.emitterShape = kCAEmitterLayerLine;
    //发射模式
    rainLayer.emitterMode = kCAEmitterLayerSurface;
    //发射形状的大小
    rainLayer.emitterSize = self.view.frame.size;
    //发射的中心点位置
    rainLayer.emitterPosition = CGPointMake(self.view.bounds.size.width*0.5, -10);
    
//    4、配置cell
    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    //粒子图片
    cell.contents = (id)[[UIImage imageNamed:@"zongzi2.jpg"] CGImage];
    //每秒钟创建的粒子对象，默认是0
    cell.birthRate = 1.0;
    //粒子的生存周期，以s为单位，默认是0
    cell.lifetime = 30;
    //粒子发射的速率，默认是1
    cell.speed = 2;
    //粒子的初始平均速度及范围，默认为0
    cell.velocity = 10.0f;
    cell.velocityRange = 10.0f;
    //y方向的加速度矢量,默认是0
    cell.yAcceleration = 60;
    //粒子的缩放比例及范围，默认是[1,0]
    cell.scale = 0.05;
    cell.scaleRange = 0.0f;
    
//    5、添加到图层上
    rainLayer.emitterCells = @[cell];
}

- (void)hongBaoRain{
    //    1、设置CAEmitterLayer
    CAEmitterLayer *rainLayer = [CAEmitterLayer layer];
        
    //    2、在背景图上添加粒子图层
    [self.view.layer addSublayer:rainLayer];
    self.rainlayer = rainLayer;
        
    //    3、发射形状--线性
    rainLayer.emitterShape = kCAEmitterLayerLine;
    rainLayer.emitterMode = kCAEmitterLayerSurface;
    rainLayer.emitterSize = self.view.frame.size;
    rainLayer.emitterPosition = CGPointMake(self.view.bounds.size.width*0.5, -10);
        
    //    4、配置cell
    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    cell.contents = (id)[[UIImage imageNamed:@"hongbao.png"] CGImage];
    cell.birthRate = 1.0;
    cell.lifetime = 30;
    cell.speed = 2;
    cell.velocity = 10.0f;
    cell.velocityRange = 10.0f;
    cell.yAcceleration = 60;
    cell.scale = 0.05;
    cell.scaleRange = 0.0f;
        
    //    5、添加到图层上
    rainLayer.emitterCells = @[cell];
}

- (void)jingBiRain{
    //    1、设置CAEmitterLayer
    CAEmitterLayer *rainLayer = [CAEmitterLayer layer];
        
    //    2、在背景图上添加粒子图层
    [self.view.layer addSublayer:rainLayer];
    self.rainlayer = rainLayer;
        
    //    3、发射形状--线性
    rainLayer.emitterShape = kCAEmitterLayerLine;
    rainLayer.emitterMode = kCAEmitterLayerSurface;
    rainLayer.emitterSize = self.view.frame.size;
    rainLayer.emitterPosition = CGPointMake(self.view.bounds.size.width * 0.5, -10);
        
    //    4、配置cell
    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    cell.contents = (id)[[UIImage imageNamed:@"jinbi.png"] CGImage];
    cell.birthRate = 1.0;
    cell.lifetime = 30;
    cell.speed = 2;
    cell.velocity = 10.0f;
    cell.velocityRange = 10.0f;
    cell.yAcceleration = 60;
    cell.scale = 0.05;
    cell.scaleRange = 0.f;
        
    //    5、添加到图层上
    rainLayer.emitterCells = @[cell];
}

- (void) allRain{
    //    1、设置CAEmitterLayer
    CAEmitterLayer *rainLayer = [CAEmitterLayer layer];
        
    //    2、在背景图上添加粒子图层
    [self.view.layer addSublayer:rainLayer];
    self.rainlayer = rainLayer;
        
    //    3、发射形状--线性
    rainLayer.emitterShape = kCAEmitterLayerLine;
    rainLayer.emitterMode = kCAEmitterLayerSurface;
    rainLayer.emitterSize = self.view.frame.size;
    rainLayer.emitterPosition = CGPointMake(self.view.frame.size.width*0.5, -10);
        
    //    4、配置cell
    CAEmitterCell *zongzi = [CAEmitterCell emitterCell];
    zongzi.contents = (id)[[UIImage imageNamed:@"zongzi2.jpg"] CGImage];
    zongzi.birthRate = 1.0;
    zongzi.lifetime = 30;
    zongzi.speed = 2;
    zongzi.velocity = 10.f;
    zongzi.velocityRange = 10.f;
    zongzi.yAcceleration = 60;
    zongzi.scale = 0.05;
    zongzi.scaleRange = 0.f;
    
    
    CAEmitterCell *hongbao = [CAEmitterCell emitterCell];
    hongbao.contents = (id)[[UIImage imageNamed:@"hongbao.png"] CGImage];
    hongbao.birthRate = 1.0;
    hongbao.lifetime = 30;
    hongbao.speed = 2;
    hongbao.velocity = 10.f;
    hongbao.velocityRange = 10.f;
    hongbao.yAcceleration = 60;
    hongbao.scale = 0.05;
    hongbao.scaleRange = 0.f;
    
    CAEmitterCell *jinbi = [CAEmitterCell emitterCell];
    jinbi.contents = (id)[[UIImage imageNamed:@"jinbi.png"] CGImage];
    jinbi.birthRate = 1.0;
    jinbi.lifetime = 30;
    jinbi.speed = 2;
    jinbi.velocity = 10.f;
    jinbi.velocityRange = 10.f;
    jinbi.yAcceleration = 60;
    jinbi.scale = 0.1;
    jinbi.scaleRange = 0.f;
    
        
    //    5、添加到图层上
    
    rainLayer.emitterCells = @[zongzi, hongbao, jinbi];
}

- (void)dealloc{
    self.rainlayer.emitterCells = @[];
}

@end
