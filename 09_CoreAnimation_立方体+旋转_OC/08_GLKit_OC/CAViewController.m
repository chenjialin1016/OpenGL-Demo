//
//  CAViewController.m
//  08_GLKit_OC
//
//  Created by 陈嘉琳 on 2020/7/26.
//  Copyright © 2020 CJL. All rights reserved.
//

#import "CAViewController.h"

@interface CAViewController ()
@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (strong, nonatomic) IBOutlet UIView *view0;
@property (strong, nonatomic) IBOutlet UIView *view1;
@property (strong, nonatomic) IBOutlet UIView *view2;
@property (strong, nonatomic) IBOutlet UIView *view3;
@property (strong, nonatomic) IBOutlet UIView *view4;
@property (strong, nonatomic) IBOutlet UIView *view5;

@property (nonatomic, strong) NSArray *faces;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property(nonatomic, assign) NSInteger angle;

@end

@implementation CAViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.containerView.backgroundColor = [UIColor lightGrayColor];
    
//    添加面
    [self addFaces];
    
//    
    [self addCADisplayLink];
}


//添加面
- (void)addFaces{
    self.faces = @[_view0, _view1, _view2, _view3, _view4, _view5];
    
//    主view
    CATransform3D perspective = CATransform3DIdentity;
//    为什么加这句？？去掉也是可以的
//    核心动画设置透视投影
    perspective.m34 = -1.0 / 500.0;
//    围绕x，y分别旋转，M_PI_4 = π/4，π=180°
//      x:顺时针旋转45°，y：顺时针旋转45°
    perspective = CATransform3DRotate(perspective, -M_PI_4, 1, 0, 0);
    perspective = CATransform3DRotate(perspective, -M_PI_4, 0, 1, 0);
    self.containerView.layer.sublayerTransform = perspective;
    
    //添加face1
//    z轴平移100
//    （除了第一个视图外，其余的视图都是基于第一个视图的位置进行平移+旋转的）
    CATransform3D transform = CATransform3DMakeTranslation(0, 0, 100);
    [self addFace:0 withTransform:transform];
    
////    添加face2 --平移y+旋转y
    transform = CATransform3DMakeTranslation(100, 0, 0);
    transform = CATransform3DRotate(transform, M_PI_2, 0, 1, 0);
    [self addFace:1 withTransform:transform];
//
//     添加face3 -- 平移y+旋转x
    transform = CATransform3DMakeTranslation(0, -100, 0);
    transform = CATransform3DRotate(transform, M_PI_2, 1, 0, 0);
//    [self addFace:2 withTransform:transform];
    
//    添加face4 -- 平移y+旋转x
    transform = CATransform3DMakeTranslation(0, 100, 0);
    transform = CATransform3DRotate(transform, -M_PI_2, 1, 0, 0);
    [self addFace:3 withTransform:transform];

//    添加face5 -- 平移+旋转
    transform = CATransform3DMakeTranslation(-100, 0, 0);
    transform = CATransform3DRotate(transform, -M_PI_2, 0, 1, 0);
    [self addFace:4 withTransform:transform];

//    添加face6 -- 平移z+旋转y
    transform = CATransform3DMakeTranslation(0, 0, -100);
    transform = CATransform3DRotate(transform, M_PI, 0, 1, 0);
    [self addFace:5 withTransform:transform];
}

- (void)addFace: (NSInteger)index withTransform: (CATransform3D)transform
{
//    获取face视图，并将其加入容器中
    UIView *face = self.faces[index];
    [self.containerView addSubview:face];
    
//    将face视图放在容器的中心
    CGSize containerSize = self.containerView.bounds.size;
    face.center = CGPointMake(containerSize.width/2.0, containerSize.height/2.0);
    
//    添加tansform，tansform就是一个矩阵
    face.layer.transform = transform;
}

//添加定时器
- (void)addCADisplayLink{
    self.angle = 0;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}


- (void)update{
    
//    计算旋转度数
    self.angle = (self.angle + 5) % 360;
//    将度数转化为弧度
    float deg = self.angle * (M_PI / 180);
    CATransform3D temp = CATransform3DIdentity;
//    围绕（0.3, 1, 0.7）方向旋转
    temp = CATransform3DRotate(temp, deg, 0.3, 1, 0.7);
//    旋转容器的子layer
    self.containerView.layer.sublayerTransform = temp;
}
@end
