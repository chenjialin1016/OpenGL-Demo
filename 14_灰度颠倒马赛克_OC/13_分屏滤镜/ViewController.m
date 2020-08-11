//
//  ViewController.m
//  13_分屏滤镜
//
//  Created by — on 2020/8/8.
//  Copyright © 2020 —. All rights reserved.
//

/*
 入口：
 1、默认显示viewDidLoad -- 初始化 -- shader加载 & 编译 & 使用 -- startAnimation
 2、filtebar切换 -- 某一个效果 -- 对应一组shader -- shader加载 & 编译 & 使用 -- startAnimation
 */

#import "ViewController.h"
#import "FilterBar.h"
#import <GLKit/GLKit.h>

//顶点数据
typedef struct {
    GLKMatrix3 positionCoord;//(x,y,z)
    GLKMatrix2 textureCoord;//(u,v)
}SenceVertex;

@interface ViewController ()<FilterBarDelegate>

@property (nonatomic, assign) SenceVertex *vertices;
//上下文
@property (nonatomic, strong) EAGLContext *context;

//用于刷新屏幕
@property (nonatomic, strong) CADisplayLink *displayLink;
//开始的时间戳
@property (nonatomic, assign) NSTimeInterval startTimeInterval;
//着色器程序
@property (nonatomic, assign) GLuint program;
//顶点缓存
@property (nonatomic, assign) GLuint vertexBuffer;
//纹理ID
@property (nonatomic, assign) GLuint textureID;
@end

@implementation ViewController

#pragma mark -- lifetime method


/// 释放
- (void)dealloc{
//    1、释放上下文
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    
//    2、顶点缓存区释放
    if (_vertexBuffer) {
        glDeleteBuffers(1, &_vertexBuffer);
        _vertexBuffer = 0;
    }
    
//    3、顶点数据释放
    if (_vertices) {
        free(_vertices);
        _vertices = nil;
    }
}

- (void)viewWillDisappear:(BOOL)animated{
//    移除displayLink
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    1、设置背景颜色
    self.view.backgroundColor = [UIColor blackColor];
    
//    2、创建滤镜工具栏
    [self setupFilterBar];
    
//    3、滤镜处理初始化
    [self filterInit];
    
//    4、开始一个滤镜动画
    [self startFilterAnimation];
    
    
}

#pragma mark -- setup

/// 创建滤镜工具栏
- (void)setupFilterBar{
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = 100;
    CGFloat y = [UIScreen mainScreen].bounds.size.height-height;
    FilterBar *filterBar = [[FilterBar alloc] initWithFrame:CGRectMake(0, y, width, height)];
    filterBar.delegate = self;
    [self.view addSubview:filterBar];
    
    NSArray *datasource = @[@"无",@"灰度",@"颠倒",@"正方形马赛克",@"六边形马赛克",@"三角形马赛克"];
    filterBar.itemList = datasource;
    
}

/// 滤镜处理初始化
- (void)filterInit{
    
//    1、上下文
    [self setupContext];
    
//    2、创建图层 & 绑定缓存区
    [self setupLayer];
    
//    3、设置顶点数据
    [self setupVertexData];
   
//    4、设置纹理
    [self setupTexture];
    
//    5、设置视口(视口设置必须位于设置顶点、纹理之后，否则图片显示异常，为一片空白)
    glViewport(0, 0, [self drawableWidth], [self drawableHeight]);
    
//    6、设置默认着色器
    [self setupNormalShaderProgram];
    
   
}

/// 设置上下文
- (void)setupContext{
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.context];
}


/// 设置layer & 绑定缓存区
- (void)setupLayer{
    CAEAGLLayer *layer = [[CAEAGLLayer alloc] init];
    layer.frame = CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.width);
    layer.contentsScale = [[UIScreen mainScreen] scale];
    [self.view.layer addSublayer:layer];
        
    //  绑定渲染缓存区/帧缓存区
    [self bindRenderLayer:layer];
}


/// 设置顶点数据
- (void)setupVertexData{
    //1、开辟顶点数组（开辟空间）
    self.vertices = malloc(sizeof(SenceVertex)*4);
    
//    2、添加顶点数据：初始化4个顶点坐标 & 纹理坐标
    self.vertices[0] = (SenceVertex){{-1, 1, 0}, {0, 1}};
    self.vertices[1] = (SenceVertex){{-1, -1, 0}, {0, 0}};
    self.vertices[2] = (SenceVertex){{1, 1, 0}, {1, 1}};
    self.vertices[3] = (SenceVertex){{1, -1, 0}, {1, 0}};
        
//    3、设置顶点缓存区
//    VAO：顶点数组
//    VBO：顶点缓存区
//    EBO:索引缓存区
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    GLsizeiptr bufferSizeBytes = sizeof(SenceVertex) * 4;
    glBufferData(GL_ARRAY_BUFFER, bufferSizeBytes, self.vertices, GL_STATIC_DRAW);

//    4、将顶点缓存区保存
    self.vertexBuffer = vertexBuffer;
}


/// 设置纹理
- (void)setupTexture{
    //获取处理的图片路径
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"mouse" ofType:@"jpg"];
    //读取图片
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    //将jpg图片转换成纹理图片
     GLuint textureID = [self createTextureWithImage:image];
    //设置纹理ID
    self.textureID = textureID;
}


/// 绑定渲染缓冲区和帧缓存区
/// @param layer 图层
- (void) bindRenderLayer: (CALayer<EAGLDrawable> *)layer{
//    帧缓存区、渲染缓存区
    //1.渲染缓存区,帧缓存区对象
    GLuint renderBuffer, frameBuffer;
    
    //2.获取帧渲染缓存区名称,绑定渲染缓存区以及将渲染缓存区与layer建立连接
    glGenRenderbuffers(1, &renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer);
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    
     //3.获取帧缓存区名称,绑定帧缓存区以及将渲染缓存区附着到帧缓存区上
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderBuffer);
    
}

/// 从图片中加载纹理
/// @param image 图片
- (GLuint)createTextureWithImage:(UIImage *)image{
//    1、将UIImage转换为CGImageRef & 判断图片是否转换成功
    CGImageRef cgImageRef = [image CGImage];
   
    if (!cgImageRef) {
        NSLog(@"Failed to load image");
        exit(1);
    }
//    2、获取图片的大小：宽和高
    GLuint width = (GLuint)CGImageGetWidth(cgImageRef);
    GLuint height = (GLuint)CGImageGetHeight(cgImageRef);
    //获取图片的rect
    CGRect rect = CGRectMake(0, 0, width, height);
    //获取图片的颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
//    3、获取图片的字节数:宽*高*4（RGBA）
    void *imageData = malloc(width*height*4);
    
//    4、创建上下文
    /*
    参数1：data,指向要渲染的绘制图像的内存地址
    参数2：width,bitmap的宽度，单位为像素
    参数3：height,bitmap的高度，单位为像素
    参数4：bitPerComponent,内存中像素的每个组件的位数，比如32位RGBA，就设置为8
    参数5：bytesPerRow,bitmap的没一行的内存所占的比特数
    参数6：colorSpace,bitmap上使用的颜色空间  kCGImageAlphaPremultipliedLast：RGBA
    */
    // width*4：一行占用的比特数
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, width*4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    //图片翻转
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(context, rect);
    
    //绘制图片:对图片进行重新绘制，得到一张新的解压缩后的位图
    CGContextDrawImage(context, rect, cgImageRef);
    
//    设置图片纹理属性
//    5、获取纹理ID
    GLuint textureID;
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);
    
//    6、载入纹理2D数据
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    
//    7、设置纹理属性
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
//    8、绑定纹理
    glBindTexture(GL_TEXTURE_2D, 0);
    
//    9、释放context、imageData
    CGContextRelease(context);
    free(imageData);
    
    return textureID;
}

#pragma mark -- animation

/// 开始一个滤镜动画:特效（时间段）
- (void)startFilterAnimation{
//    1、判断定时器是否为空
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
//    2、设置定时器方法
    self.startTimeInterval = 0;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(timeAnimation)];
    
//    3、将定时器 添加到runloop循环
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}


/// 动画：重新绘制
- (void)timeAnimation{
    
//    1、获取当前时间戳
    if (self.startTimeInterval == 0) {
        self.startTimeInterval = self.displayLink.timestamp;
    }
    
//    2、使用program & 绑定buffer
    glUseProgram(self.program);
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexBuffer);
    
//    3、传入时间
    CGFloat currentTime = self.displayLink.timestamp - self.startTimeInterval;
    GLuint time = glGetUniformLocation(self.program, "Time");
    glUniform1f(time, currentTime);
    
//    4、清除画布:不清除会有残留数据
    glClear(GL_COLOR_BUFFER_BIT);
    glClearColor(1, 1, 1, 1);
    
//    5、重绘 & 渲染到屏幕上
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
    
}

#pragma mark -- FilterBarDelegate
- (void)filterBar:(FilterBar *)filterBar didScrollToIndex:(NSUInteger)index{
    
    switch (index) {
        case 0:
            [self setupNormalShaderProgram];
            break;
        case 1:
            [self setupGrayShaderProgram];
            break;
        case 2:
            [self setupReversalShaderProgram];
            break;
        case 3:
            [self setupMosaicShaderProgram];
            break;
        case 4:
            [self setupHexagonMosaicShaderProgram];
            break;
        case 5:
            [self setupTriangularMosaicShaderProgram];
            break;
        default:
            [self setupNormalShaderProgram];
            break;
    }
    
//    开始滤镜效果
    [self startFilterAnimation];
}

#pragma mark -- Shader

/// 默认着色器程序
- (void)setupNormalShaderProgram{
    [self setupShaderProgramWithName:@"Normal"];
}

/// 灰度
- (void)setupGrayShaderProgram{
    [self setupShaderProgramWithName:@"Gray"];
}

/// 颠倒
- (void)setupReversalShaderProgram{
    [self setupShaderProgramWithName:@"Reversal"];
}

/// 正方形马赛克
- (void)setupMosaicShaderProgram{
    [self setupShaderProgramWithName:@"Mosaic"];
}

/// 六边形马赛克
- (void)setupHexagonMosaicShaderProgram{
    [self setupShaderProgramWithName:@"HexagonMosaic"];
}

/// 三角形马赛克
- (void)setupTriangularMosaicShaderProgram{
    [self setupShaderProgramWithName:@"TriangularMosaic"];
}

/// 初始化着色器程序：公共的着色器传递数据方法
/// @param name 着色器
- (void)setupShaderProgramWithName:(NSString*)name{
//    1、获取program & 使用program
    GLuint program = [self programWithShaderName:name];
    glUseProgram(program);
    
//    2、数据传递（原始图片纹理坐标、顶点坐标）
//    获取position、texture、textureCoords的传递入口 & 打开2个通道（顶点坐标、纹理坐标），并传递数据
    //获取Position,Texture,TextureCoords 的索引位置
    GLuint positionSlot = glGetAttribLocation(program, "Position");
    GLuint textCoordsSlot = glGetAttribLocation(program, "TextureCoords");
    GLuint textureSlot = glGetUniformLocation(program, "Texture");
    
    //打开positionSlot 属性并且传递数据到positionSlot中(顶点坐标)
    glEnableVertexAttribArray(positionSlot);
    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL+offsetof(SenceVertex, positionCoord));
    
    //打开textureCoordsSlot 属性并传递数据到textureCoordsSlot(纹理坐标)
    glEnableVertexAttribArray(textCoordsSlot);
    glVertexAttribPointer(textCoordsSlot, 2, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL+offsetof(SenceVertex, textureCoord));
    
//    3、激活纹理，绑定纹理ID & 设置纹理采样器
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.textureID);
    glUniform1i(textureSlot, 0);
    
    
//    4、保存program，界面销毁时则释放
    self.program = program;
    
}


#pragma mark -- Shader compile and link

/// 链接program
/// @param shaderName 着色器名称
- (GLuint)programWithShaderName:(NSString *)shaderName{
    
//    1、编译顶点、片元着色器
    GLuint vertexShader = [self compileShaderWithName:shaderName type:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShaderWithName:shaderName type:GL_FRAGMENT_SHADER];
    
//    2、创建program & 将顶点、片元附着到program
    GLuint program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    
//    3、链接program
    glLinkProgram(program);
    
//    4、检查link是否成功
    GLint linkStatus;
    glGetProgramiv(program, GL_LINK_STATUS, &linkStatus);
    if (linkStatus == GL_FALSE) {
        GLchar message[512];
        glGetProgramInfoLog(program, sizeof(message), 0, &message[0]);
        NSString *messageString = [NSString stringWithUTF8String:message];
        NSAssert(NO, @"shader编译失败：%@", messageString);
        exit(1);
    }
    NSLog(@"program link success！");
    
//    5、返回program
    return program;
}

/// 编译shader代码
/// @param name 着色器名称
/// @param shaderType 着色器类型
- (GLuint)compileShaderWithName:(NSString *)name type:(GLenum)shaderType{
    
//    1、获取文件路径
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:name ofType:shaderType == GL_VERTEX_SHADER ? @"vsh" : @"fsh"];
    NSError *error;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSAssert(NO, @"读取shader失败");
        exit(1);
    }
    
//    2、创建shader
    GLuint shader = glCreateShader(shaderType);
    
//    3、将OC字符串转换为c字符串 & 获取shader source
    const char *shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shader, 1, &shaderStringUTF8, &shaderStringLength);
    
//    4、编译shader
    glCompileShader(shader);
    
//    5、获取编译状态
    GLint compileStatus;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compileStatus);
    if (compileStatus == GL_FALSE) {
        GLchar message[512];
        glGetShaderInfoLog(shader, sizeof(message), 0, &message[0]);
        NSString *messageString = [NSString stringWithUTF8String:message];
        NSAssert(NO, @"shader编译失败：%@", messageString);
        exit(1);
    }
    
//    6、返回shader
    return shader;
}

/// 获取渲染缓冲区的宽
- (GLint)drawableWidth{
    GLint backingWidth;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    return backingWidth;
}

/// 获取渲染缓存区的高
- (GLint)drawableHeight{
    GLint backingHeight;
       glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
       return backingHeight;
}

@end
