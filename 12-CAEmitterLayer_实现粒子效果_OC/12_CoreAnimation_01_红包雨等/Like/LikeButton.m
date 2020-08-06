//
//  LikeButton.m
//  12_CoreAnimation_01_红包雨等
//
//  Created by — on 2020/8/4.
//  Copyright © 2020 CJL. All rights reserved.
//

#import "LikeButton.h"

@interface LikeButton()

@property (nonatomic, strong) CAEmitterLayer *explosionLayer;

@end

@implementation LikeButton

//initWithFrame只适用纯代码创建时调用，不涉及xib或storyboard。
//initWithCoder、awakeFromNib是从xib、storyboard中创建时会调用
- (void)awakeFromNib{
    [super awakeFromNib];
    
//    设置粒子效果
    [self setupExplosion];
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupExplosion];
    }
    return self;
}


- (void)setupExplosion{
//    1、创建粒子
    CAEmitterCell *explosionCell = [CAEmitterCell emitterCell];
    
//    2、配置粒子
    //粒子图片
    explosionCell.contents = (id)[[UIImage imageNamed:@"spark_red"] CGImage];
    //粒子标识符
    explosionCell.name = @"explosionCell";
    //透明度变化速度
    explosionCell.alphaSpeed = -1.f;
    //透明值范围
    explosionCell.alphaRange = 0.1;
    //生命周期
    explosionCell.lifetime = 1;
    //生命周期范围
    explosionCell.lifetimeRange = 0.1;
    //粒子速度
    explosionCell.velocity = 40.0f;
    //粒子速度范围
    explosionCell.velocityRange = 10.0f;
    //缩放比例
    explosionCell.scale = 0.08;
    //缩放比例范围
    explosionCell.scaleRange = 0.02;
    
//    3、创建发射源layer
    CAEmitterLayer *explosionLayer = [CAEmitterLayer layer];
    [self.layer addSublayer:explosionLayer];
    self.explosionLayer = explosionLayer;
    
//    配置发射源
    //emitterShape表示粒子从什么形状发射出来,圆形形状
    explosionLayer.emitterShape = kCAEmitterLayerCircle;
    //emitterMode发射模型,轮廓模式,从形状的边界上发射粒子
    explosionLayer.emitterMode = kCAEmitterLayerOutline;
    //发射源尺寸大小
    explosionLayer.emitterSize = CGSizeMake(self.bounds.size.width+40, self.bounds.size.height+40);
    //渲染模式
    explosionLayer.renderMode = kCAEmitterLayerOldestFirst;
    
//    5、添加到layer的粒子数组中
    explosionLayer.emitterCells = @[explosionCell];
    
}

- (void)layoutSubviews{
//    设置发射源的中心点
    self.explosionLayer.position = CGPointMake(self.bounds.size.width*0.5, self.bounds.size.height*0.5);
    
    [super layoutSubviews];
}


//选中状态，实现缩放
- (void)setSelected:(BOOL)selected{
    [super setSelected:selected];
    
//    通过关键帧动画实现缩放
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
    
//    设置动画路径
    animation.keyPath = @"transform.scale";
    
    if (selected) {
//        从没有点击到点击状态，会有爆炸的动画效果
        animation.values = @[@1.5, @2.0, @0.8, @1.0];
        animation.duration = 0.5;
//        计算关键帧方式
        animation.calculationMode = kCAAnimationCubic;
//        为图层添加动画
        [self.layer addAnimation:animation forKey:nil];
        
//        让放大动画先执行完毕，再执行爆炸动画
        [self performSelector:@selector(startAnimation) withObject:nil afterDelay:0.25];
    }else{
//        从点击状态normal状态 无动画效果，如果点赞之后马上取消，那么也立即停止动画
        [self stopAnimation];
    }
    
    
}

//没有高亮状态
- (void)setHighlighted:(BOOL)highlighted{
    [super setHighlighted:highlighted];
}

//开始动画
- (void)startAnimation{
//    用kvc设置颗粒个数
    [self.explosionLayer setValue:@1000 forKeyPath:@"emitterCells.explosionCell.birthRate"];
    
//    开始动画
    self.explosionLayer.beginTime = CACurrentMediaTime();
    
//    延迟停止动画
    [self performSelector:@selector(stopAnimation) withObject:nil afterDelay:0.15];
    
}

//动画结束
- (void)stopAnimation{
//    用KVC设置颗粒个数
    [self.explosionLayer setValue:@0 forKeyPath:@"emitterCells.explosionCell.birthRate"];
    
//    移除动画
    [self.explosionLayer removeAllAnimations];
    
}

- (void)drawRect:(CGRect)rect{
    
}
@end
