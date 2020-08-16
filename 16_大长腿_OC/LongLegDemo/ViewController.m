//
//  ViewController.m
//  LongLegDemo
//
//  Created by 陈嘉琳 on 2020/8/15.
//  Copyright © 2020 CJL. All rights reserved.
//

#import "ViewController.h"
#import <Photos/Photos.h>

#import "LongLegView.h"

@interface ViewController ()<LongLegViewViewDelegate>

@property (weak, nonatomic) IBOutlet LongLegView *springView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topLineSpace;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomLineSpace;
//top按钮
@property (weak, nonatomic) IBOutlet UIButton *topButton;
//bottom按钮
@property (weak, nonatomic) IBOutlet UIButton *bottomButton;
//调节slider
@property (weak, nonatomic) IBOutlet UISlider *slider;
//topline
@property (weak, nonatomic) IBOutlet UIView *topLine;
//bottomline
@property (weak, nonatomic) IBOutlet UIView *bottomLine;
//遮罩层
@property (weak, nonatomic) IBOutlet UIView *mask;


// 上方横线距离纹理顶部的高度
@property (nonatomic, assign) CGFloat currentTop;
// 下方横线距离纹理顶部的高度
@property (nonatomic, assign) CGFloat currentBottom;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //1. 设置按钮的相关配置;
    [self setupButtons];
    //2. 设置SpringView 代理方法;
    self.springView.springDelegate = self;
    //3. 设计SpringView 上加载的图片(可修改~)
    [self.springView updateImage:[UIImage imageNamed:@"ym3.jpg"]];
    //4. 设置初始化的拉伸区域
    [self setupStretchArea];
}

- (void)viewDidAppear:(BOOL)animated {
    static dispatch_once_t onceToken;
    //单例~：一次拉伸必须是独一无二的，需要等size计算完成后才可以使用
    dispatch_once(&onceToken, ^{
        //这里的计算要用到view的size，所以等待AutoLayout把尺寸计算出来后再调用
        [self setupStretchArea];
    });
}

#pragma mark - Private

- (void)setupButtons {
    
    self.topButton.layer.borderWidth = 1;
    self.topButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    [self.topButton addGestureRecognizer:[[UIPanGestureRecognizer alloc]
                                          initWithTarget:self
                                          action:@selector(actionPanTop:)]];
    
    self.bottomButton.layer.borderWidth = 1;
    self.bottomButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    [self.bottomButton addGestureRecognizer:[[UIPanGestureRecognizer alloc]
                                             initWithTarget:self
                                             action:@selector(actionPanBottom:)]];
}

- (CGFloat)stretchAreaYWithLineSpace:(CGFloat)lineSpace {
    
    //
    return (lineSpace / self.springView.bounds.size.height - self.springView.textureTopY) / self.springView.textureHeight;
}

// 设置初始的拉伸区域位置
- (void)setupStretchArea {
   
    //currentTop/currentBottom 是比例值; 初始化比例是25%~75%
    self.currentTop = 0.25f;
    self.currentBottom = 0.75f;
  
    // 初始纹理占 View 的比例
    CGFloat textureOriginHeight = 0.7f;
    
    //currentTop * textureOriginHeight + (1 - textureOriginHeight)/2 * springViewHeight;
    self.topLineSpace.constant = ((self.currentTop * textureOriginHeight) + (1 - textureOriginHeight) / 2) * self.springView.bounds.size.height;
    NSLog(@"self.topLineSpace.constant %f",self.topLineSpace.constant);
    
    //currentBottom * textureOriginHeight + (1 - textureOriginHeight)/2 * springViewHeight;
    self.bottomLineSpace.constant = ((self.currentBottom * textureOriginHeight) + (1 - textureOriginHeight) / 2) * self.springView.bounds.size.height;
     NSLog(@"self.bottomLineSpace.constant %f",self.bottomLineSpace.constant);
    
}

//相关控件隐藏功能
- (void)setViewsHidden:(BOOL)hidden {
    self.topLine.hidden = hidden;
    self.bottomLine.hidden = hidden;
    self.topButton.hidden = hidden;
    self.bottomButton.hidden = hidden;
    self.mask.hidden = hidden;
}

// 保存图片到相册
- (void)saveImage:(UIImage *)image {
    //将图片通过PHPhotoLibrary保存到系统相册
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromImage:image];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        NSLog(@"success = %d, error = %@ 图片已保存到相册", success, error);
    }];
}

#pragma mark - Action
//当调用buttopTop按钮时,界面变换(需要重新子view的位置以及约束信息)
- (void)actionPanTop:(UIPanGestureRecognizer *)pan {
//   1、判断springView是否发生改变
   if ([self.springView hasChange]) {
//        2、更新纹理
       [self.springView updateTexture];
//        3、重置滑杆位置(因为此时相当于对一个张新图重新进行拉伸处理~)
       self.slider.value = 0.5f;
   }
   
//    4、修改约束：UI调整
    CGPoint translation = [pan translationInView:self.view ];
    //修改topLineSpace的预算条件;
    self.topLineSpace.constant = MIN(self.topLineSpace.constant + translation.y,
    self.bottomLineSpace.constant);
    
    //纹理Top = springView的height * textureTopY
    //606
    CGFloat textureTop = self.springView.bounds.size.height * self.springView.textureTopY;
    NSLog(@"textureTop ：%f,%f",self.springView.bounds.size.height,self.springView.textureTopY);
    NSLog(@"textureTop：%f",textureTop);
    
    //设置topLineSpace的约束常量;
    self.topLineSpace.constant = MAX(self.topLineSpace.constant, textureTop);
    //将pan移动到view的Zero位置;
    [pan setTranslation:CGPointZero inView:self.view];
    
    //计算移动了滑块后的currentTop和currentBottom
    self.currentTop = [self stretchAreaYWithLineSpace:self.topLineSpace.constant];
    self.currentBottom = [self stretchAreaYWithLineSpace:self.bottomLineSpace.constant];
}

//与buttopTop 按钮事件所发生的内容几乎一样,不做详细注释了.
- (void)actionPanBottom:(UIPanGestureRecognizer *)pan {
   if ([self.springView hasChange]) {
       [self.springView updateTexture];
       self.slider.value = 0.5f;
   }
   
   CGPoint translation = [pan translationInView:self.view];
   self.bottomLineSpace.constant = MAX(self.bottomLineSpace.constant + translation.y,
                                       self.topLineSpace.constant);
   CGFloat textureBottom = self.springView.bounds.size.height * self.springView.textureBottomY;
   self.bottomLineSpace.constant = MIN(self.bottomLineSpace.constant, textureBottom);
   [pan setTranslation:CGPointZero inView:self.view];
   
   self.currentTop = [self stretchAreaYWithLineSpace:self.topLineSpace.constant];
   self.currentBottom = [self stretchAreaYWithLineSpace:self.bottomLineSpace.constant];
}

#pragma mark - IBAction
//当Slider的值发生改变时,直接影响springView中纹理的计算
- (IBAction)sliderValueDidChanged:(UISlider *)sender {

//    1、获得中间拉伸区域的高度
    CGFloat newHeight = (self.currentBottom - self.currentTop) * (sender.value + 0.5);
    
//    2、将currentTop和currentBottom以及新图片的高度传给springView,进行拉伸操作;
    [self.springView stretchingFromStartY:self.currentTop toEndY:self.currentBottom withNewHeight:newHeight];
}

//当SliderTouchDown时,则隐藏控件;
- (IBAction)sliderDidTouchDown:(id)sender {
    [self setViewsHidden:YES];
}

//当sliderDidTouchUp时,则显示控件;
- (IBAction)sliderDidTouchUp:(id)sender {
    [self setViewsHidden:NO];
}

//保存图片
- (IBAction)saveAction:(id)sender {
   
//    1、获取处理后的图片
    UIImage *image = [self.springView createResult];
    
//    2、图片存储到相册中
    [self saveImage:image];
}

#pragma mark - MFSpringViewDelegate
//代理方法(SpringView拉伸区域修改)
- (void)springViewStretchAreaDidChanged:(LongLegView *)springView {
    
    //拉伸结束后,更新topY,bottomY,topLineSpace,bottomLineSpace 位置;
    CGFloat topY = self.springView.bounds.size.height * self.springView.stretchAreaTopY;
    CGFloat bottomY = self.springView.bounds.size.height * self.springView.stretchAreaBottomY;
    self.topLineSpace.constant = topY;
    self.bottomLineSpace.constant = bottomY;
}

@end
