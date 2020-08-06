//
//  ColorBallViewController.m
//  12_CoreAnimation_01_红包雨等
//
//  Created by — on 2020/8/4.
//  Copyright © 2020 CJL. All rights reserved.
//

#import "ColorBallViewController.h"

@interface ColorBallViewController ()

@property (nonatomic, strong) CAEmitterLayer *colorBallLayer;

@end

@implementation ColorBallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    [self setuplabel];
    
    [self setupEmitter];
}

- (void)setuplabel{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, 50)];
    
    [self.view addSubview:label];
    label.textColor = [UIColor whiteColor];
    label.text = @"轻点或拖动来改变发射源位置";
    label.textAlignment = NSTextAlignmentCenter;
}

- (void)setupEmitter{
//    1、创建发射源
    CAEmitterLayer *colorBallLayer = [CAEmitterLayer layer];
    [self.view.layer addSublayer:colorBallLayer];
    self.colorBallLayer = colorBallLayer;
    
//    2、设置发射源属性
    //发射源的尺寸大小
    colorBallLayer.emitterSize = self.view.frame.size;
    //发射源的形状
    colorBallLayer.emitterShape = kCAEmitterLayerPoint;
    //发射模式
    colorBallLayer.emitterMode = kCAEmitterLayerPoints;
    //粒子发射形状的中心点位置
    colorBallLayer.emitterPosition = CGPointMake(self.view.layer.bounds.size.width, 100);
    
//    3、创建粒子cell
    CAEmitterCell * cell = [CAEmitterCell emitterCell];
    
//    4、设置cell属性
    //粒子名称，即粒子的唯一标识符
    cell.name = @"colorBallCell";
    //粒子产生率，默认0
    cell.birthRate = 20.0f;
    //粒子生命周期
    cell.lifetime = 10.0f;
    //粒子速度，默认0
    cell.velocity = 40.0f;
    //粒子速度平均量
    cell.velocityRange = 100.0f;
    //x、y、z方向上的加速度分量，都默认是0
    cell.yAcceleration = 15.0f;
    //指定维度，维度表示了在x-z平面坐标系中与x轴之间的夹角，默认0
    cell.emissionLongitude = M_PI;//向左
    //发射角度范围,默认0，以锥形分布开的发射角度。角度用弧度制。粒子均匀分布在这个锥形范围内;
    cell.emissionRange = M_PI_4;//围绕x轴向左90度
    //缩放比例
    cell.scale = 0.2;
    //缩放比例范围，默认是0
    cell.scaleRange = 0.1;
    //在生命周期内的缩放速度，默认是0
    cell.scaleSpeed = 0.02;
    //粒子的内容，为CGImageRef的对象
    cell.contents = (id)[[UIImage imageNamed:@"circle_white"]CGImage];
    //颜色
    cell.color = [[UIColor colorWithRed:0.5 green:0 blue:0.5 alpha:1] CGColor];
    //粒子颜色red,green,blue,alpha能改变的范围,默认0，范围是【0，1】
    cell.redRange = 1.0f;
    cell.greenRange = 1.0f;
    cell.alphaRange = 0.8;
    //粒子颜色red,green,blue,alpha在生命周期内的改变速度,默认都是0
    cell.blueRange = 1.0f;
    cell.alphaSpeed = -0.1f;
    
//    5、添加
    colorBallLayer.emitterCells = @[cell];
}

//点击
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    CGPoint point = [self locationFromTouchEvent:event];
    
    [self setBallInPosition:point];
}

//拖动
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    CGPoint point = [self locationFromTouchEvent:event];
    
    [self setBallInPosition:point];
}

//获取手指所在点
- (CGPoint)locationFromTouchEvent: (UIEvent*)event{
    UITouch *touch = [[event allTouches] anyObject];
    return  [touch locationInView:self.view];
}


//移动发射源到某个点上
- (void)setBallInPosition: (CGPoint)position{
    
//    1、创建基础动画
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"emitterCells.colorBallCell.scale"];
    //from
    anim.fromValue = @0.2f;
    //to
    anim.toValue = @0.5f;
    //duration
    anim.duration = 1.f;
    //线性起搏，使动画在其持续时间内均匀地发生
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    
//    2、用事务包装隐式动画
    [CATransaction begin];
    //设置是否禁止由于该事务组内的属性更改而触发的操作。
    [CATransaction setDisableActions:true];
    //为colorBallLayer 添加动画
    [self.colorBallLayer addAnimation:anim forKey:nil];
    //为colorBallLayer 指定位置添加动画效果
    [self.colorBallLayer setValue:[NSValue valueWithCGPoint:position] forKeyPath:@"emitterPosition"];
    
//    3、提交动画
    [CATransaction commit];
}

@end
