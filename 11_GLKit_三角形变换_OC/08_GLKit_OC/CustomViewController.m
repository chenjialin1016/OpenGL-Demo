//
//  CustomViewController.m
//  08_GLKit_OC
//
//  Created by 陈嘉琳 on 2020/8/1.
//  Copyright © 2020 CJL. All rights reserved.
//

#import "CustomViewController.h"
#import <OpenGLES/ES2/gl.h>

@interface CustomViewController ()

@property (nonatomic, strong) EAGLContext *mContext;
@property (nonatomic, strong) GLKBaseEffect *mEffect;

@property (nonatomic, assign) int count;

//旋转的度数
@property (nonatomic, assign) float xDegree;
@property (nonatomic, assign) float yDegree;
@property (nonatomic, assign) float zDegree;

//是否旋转x，y，z
@property (nonatomic, assign) BOOL bX;
@property (nonatomic, assign) BOOL bY;
@property (nonatomic, assign) BOOL bZ;

@end

@implementation CustomViewController

{
    dispatch_source_t timer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    self.view.backgroundColor = [UIColor blackColor];
    
    //1.新建图层
    [self setupContext];
    
    //2.渲染图形
    [self render];
    
}



- (void) setupContext{

    //1.新建OpenGL ES上下文
    self.mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    GLKView *view = (GLKView*)self.view;
    view.context = self.mContext;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [EAGLContext setCurrentContext:self.mContext];
    
    glEnable(GL_DEPTH_TEST);
    
}

//渲染图形
- (void)render{
    
    //1.顶点数据
       //前3个元素，是顶点数据；中间3个元素，是顶点颜色值，最后2个是纹理坐标
    GLfloat attrArr[] =
    {
        -0.5f, 0.5f, 0.0f,      1.0f, 0.0f, 1.0f, //左上
        0.5f, 0.5f, 0.0f,       1.0f, 0.0f, 1.0f, //右上
        -0.5f, -0.5f, 0.0f,     1.0f, 1.0f, 1.0f, //左下
        
        0.5f, -0.5f, 0.0f,      1.0f, 1.0f, 1.0f, //右下
        0.0f, 0.0f, 1.0f,       0.0f, 1.0f, 0.0f, //顶点
    };
    
    //2.绘图索引
    GLuint indices[] =
    {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };
    
    //顶点个数
    self.count = sizeof(indices) / sizeof(GLuint);
    
//    开辟顶点缓存区
    //将顶点数组放入数组缓冲区中 GL_ARRAY_BUFFER
    GLuint buffer;
    glGenBuffers(1, &buffer);
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_STATIC_DRAW);
    
//    开辟索引缓存区
    //将索引数组存储到索引缓冲区 GL_ELEMENT_ARRAY_BUFFER
    GLuint index;
    glGenBuffers(1, &index);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
   
//    打开通道
    //使用顶点数据
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*6, NULL);
    
    //使用颜色数据
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*6, (GLfloat*)NULL+3);
    
    //着色器
    self.mEffect = [[GLKBaseEffect alloc] init];
    
    //投影视图
    CGSize size = self.view.bounds.size;
    float aspect = fabs(size.width / size.height);
    
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90), aspect, 0.1, 100);
    projectionMatrix = GLKMatrix4Scale(projectionMatrix, 1.0f, 1.0f, 1.0f);
    self.mEffect.transform.projectionMatrix = projectionMatrix;
    
    //模型视图
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0, 0, -2.0);
    self.mEffect.transform.modelviewMatrix = modelViewMatrix;
    
//    定时器 GCD
    double seconds = 0.1;
    timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC, 0.0);
    dispatch_source_set_event_handler(timer, ^{
        self.xDegree += 0.1 * self.bX;
        self.yDegree += 0.1 * self.bY;
        self.zDegree += 0.1 * self.bZ;
    });
    
    dispatch_resume(timer);
}

- (IBAction)xClick:(id)sender {
    _bX = !_bX;
}
- (IBAction)yClick:(id)sender {
    _bY = !_bY;
}
- (IBAction)zClick:(id)sender {
    _bZ = !_bZ;
}

//场景数据变化
- (void)update{
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0, 0, -2.5);
    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, self.xDegree);
    modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, self.yDegree);
    modelViewMatrix = GLKMatrix4RotateZ(modelViewMatrix, self.zDegree);
    
    self.mEffect.transform.modelviewMatrix = modelViewMatrix;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    glClearColor(0.3, 0.3, 0.3, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
//    准备绘制
    [self.mEffect prepareToDraw];
    glDrawElements(GL_TRIANGLES, self.count, GL_UNSIGNED_INT, 0);
}

@end
