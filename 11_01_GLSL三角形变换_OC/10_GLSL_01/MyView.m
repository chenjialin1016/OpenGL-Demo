//
//  MyView.m
//  10_GLSL_01
//
//  Created by  on 2020/7/28.
//

#import "MyView.h"
#import <OpenGLES/ES2/gl.h>
#import "GLESMath.h"
#import "GLESUtils.h"

@interface MyView()

//在iOS和tvOS上绘制OpenGL ES内容的图层，继承与CALayer
@property (nonatomic, strong) CAEAGLLayer *myEagLayer;

@property (nonatomic, strong) EAGLContext *myContext;

//RenderBuffer、FrameBuffer的ID
@property (nonatomic, assign) GLuint myColorRenderBuffer;
@property (nonatomic, assign) GLuint myColorFrameBuffer;

@property (nonatomic, assign) GLuint myPrograme;
//顶点数据
@property (nonatomic, assign) GLuint myVertices;

@end

@implementation MyView
{
//    分别围绕x、y、z的旋转度数
    float xDegree;
    float yDegree;
    float zDegree;
//    是否围绕x/y/z旋转
    BOOL bX;
    BOOL bY;
    BOOL bZ;
    
//    一直旋转的定时器
    NSTimer *timer;
}

- (void)layoutSubviews{
    
//    1、创建图层
    [self setupLayer];
    
//    2、创建上下文
    [self setupContext];
    
//    3、清空缓存区
    [self deleteRenderAndFrameBuffer];
    
//    4、设置RenderBuffer
    [self setupRenderBuffer];
    
//    5、设置FrameBuffer
    [self setupFrameBuffer];
    
//    6、开始绘制
    [self renderLayer];
    
    
}

//1、创建图层
- (void)setupLayer{
    
    self.myEagLayer = (CAEAGLLayer*)self.layer;
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:@false, kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
}

//2、创建上下文
- (void)setupContext{
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!context) {
        NSLog(@"create context falied");
        return;
    }
    
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"set currentContext failed");
        return;
    }
  
    self.myContext = context;
}

//3、清空缓存区
- (void)deleteRenderAndFrameBuffer{
//   &_myColorRenderBuffer拿到的并不是地址，只是一个ID
    glDeleteBuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
    
    glDeleteBuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;

}
//4、设置RenderBuffer
- (void)setupRenderBuffer{
    //定义一个缓存区:已经全局定义了_myColorRenderBuffer
    //申请一个缓存区标志
    glGenRenderbuffers(1, &_myColorRenderBuffer);
    //将标识符绑定到GL_RENDERBUFFER
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
    
}

//5、设置FrameBuffer
- (void)setupFrameBuffer{

    //申请一个缓存区标志
    glGenBuffers(1, &_myColorFrameBuffer);
    //将标识符绑定到GL_FRAMEBUFFER
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
//    frameBuffer上可以附着多个renderBuffer，这种情况比较少见
    //将_myColorRenderBuffer 装配到GL_COLOR_ATTACHMENT0 附着点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorRenderBuffer);
    
}

//6、开始绘制
- (void)renderLayer{
    
    
    glClearColor(0, 0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
//    设置视口
    CGFloat scale = [[UIScreen mainScreen] scale];
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    
//    GLSL 着色器加载
     NSString* vertFile = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"glsl"];
       NSString* fragFile = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"glsl"];
    
    if (self.myPrograme) {
        glDeleteProgram(self.myPrograme);
        self.myPrograme = 0;
    }
    
    self.myPrograme = [self loadShaders:vertFile Withfrag:fragFile];
    
//    顶点数组、索引数组
    //8.创建顶点数组 & 索引数组
    //(1)顶点数组 前3顶点值（x,y,z），后3位颜色值(RGB)
    GLfloat attrArr[] =
    {
        -0.5f, 0.5f, 0.0f,      1.0f, 0.0f, 1.0f, //左上0
        0.5f, 0.5f, 0.0f,       1.0f, 0.0f, 1.0f, //右上1
        -0.5f, -0.5f, 0.0f,     1.0f, 1.0f, 1.0f, //左下2
        
        0.5f, -0.5f, 0.0f,      1.0f, 1.0f, 1.0f, //右下3
        0.0f, 0.0f, 1.0f,       0.0f, 1.0f, 0.0f, //顶点4
    };
    
    //(2).索引数组
    GLuint indices[] =
    {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };

    //(3).判断顶点缓存区是否为空，如果为空则申请一个缓存区标识符
    if (self.myVertices == 0) {
        glGenBuffers(1, &_myVertices);
    }
    
//    从CPU拷贝至GPU
    //(1).将_myVertices绑定到GL_ARRAY_BUFFER标识符上
    glBindBuffer(GL_ARRAY_BUFFER, _myVertices);
    //(2).把顶点数据从CPU内存复制到GPU上
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
//    将顶点数据传递到着色器(打开通道：顶点坐标、顶点颜色)
    //(3).将顶点数据通过myPrograme中的传递到顶点着色程序的position
    //1.glGetAttribLocation,用来获取vertex attribute的入口的.
    //2.告诉OpenGL ES,通过glEnableVertexAttribArray，
    //3.最后数据是通过glVertexAttribPointer传递过去的。
    //注意：第二参数字符串必须和shaderv.vsh中的输入变量：position保持一致
    GLuint position = glGetAttribLocation(self.myPrograme, "position");
    //(4).打开position
    glEnableVertexAttribArray(position);
    //(5).设置读取方式
    //参数1：index,顶点数据的索引
    //参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
    //参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
    //参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
    //参数5：stride,连续顶点属性之间的偏移量，默认为0；
    //参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*6, NULL);
    
    //10.--------处理顶点颜色值-------
    //(1).glGetAttribLocation,用来获取vertex attribute的入口的.
    //注意：第二参数字符串必须和shaderv.glsl中的输入变量：positionColor保持一致
    GLuint positionColor = glGetAttribLocation(self.myPrograme, "positionColor");
    //(2).设置合适的格式从buffer里面读取数据
    glEnableVertexAttribArray(positionColor);
    //(3).设置读取方式
    glVertexAttribPointer(positionColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 6, (float *)NULL + 3);
    
//    构建martix 传递到 顶点着色器：投影、模型视图
    GLuint projectionMatrixSlot = glGetUniformLocation(self.myPrograme, "projectionMatrix");
    GLuint modelViewMatrixSlot = glGetUniformLocation(self.myPrograme, "modelViewMatrix");
    
    //屏幕纵横比
    float width = self.frame.size.width;
    float height = self.frame.size.height;

    
    //创建4*4的投影矩阵
    KSMatrix4 _projectionMatrix;
    //(1)获取单元矩阵
    //往投影矩阵加载一个单元矩阵--即初始化
    ksMatrixLoadIdentity(&_projectionMatrix);
    //(2)计算纵横比例 = 长/宽
    //获取纵横比
    float aspect = width / height;
    //(3)获取透视矩阵
    /*
     参数1：矩阵
     参数2：视角，度数为单位
     参数3：纵横比
     参数4：近平面距离
     参数5：远平面距离
     参考PPT
     */
    //设置透视投影
    ksPerspective(&_projectionMatrix, 30.0, aspect, 5.0f, 20.0f);
    
    //(4)将投影矩阵传递到顶点着色器
    /*
     void glUniformMatrix4fv(GLint location,  GLsizei count,  GLboolean transpose,  const GLfloat *value);
     参数列表：
     location:指要更改的uniform变量的位置
     count:更改矩阵的个数
     transpose:是否要转置矩阵，并将它作为uniform变量的值。必须为GL_FALSE
     value:执行count个元素的指针，用来更新指定uniform变量
     */
    glUniformMatrix4fv(projectionMatrixSlot, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
    
    //创建4*4的模型视图矩阵
    KSMatrix4 _modelViewMatrix;
    //初始化
    //(1)获取单元矩阵
    ksMatrixLoadIdentity(&_modelViewMatrix);
    //为了方便观察，围绕z轴往屏幕里平移10个像素点
    //(2)平移，z轴平移-10
    ksTranslate(&_modelViewMatrix, 0.0, 0.0, -10.0);
    
    //创建旋转
    //(3)创建一个4 * 4 矩阵，旋转矩阵
    KSMatrix4 _rotationMatrix;
    //初始化
    //(4)初始化为单元矩阵
    ksMatrixLoadIdentity(&_rotationMatrix);
    //有可能围绕 x / y / z任一轴旋转(为什么不写一行？不确定围绕哪个轴旋转)
    //(5)旋转
    ksRotate(&_rotationMatrix, xDegree, 1, 0, 0);
    ksRotate(&_rotationMatrix, yDegree, 0, 1, 0);
    ksRotate(&_rotationMatrix, zDegree, 0, 0, 1);
    
    //(6)把变换矩阵相乘.将_modelViewMatrix矩阵与_rotationMatrix矩阵相乘，结合到模型视图
    //矩阵相乘 modelview = rotation x modelview
    ksMatrixMultiply(&_modelViewMatrix, &_rotationMatrix, &_modelViewMatrix);
    
    //将mv矩阵传递到顶点着色器
    //(7)将模型视图矩阵传递到顶点着色器
    /*
     void glUniformMatrix4fv(GLint location,  GLsizei count,  GLboolean transpose,  const GLfloat *value);
     参数列表：
     location:指要更改的uniform变量的位置
     count:更改矩阵的个数
     transpose:是否要转置矩阵，并将它作为uniform变量的值。必须为GL_FALSE
     value:执行count个元素的指针，用来更新指定uniform变量
     */
    glUniformMatrix4fv(modelViewMatrixSlot, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
    
//    开启正背面剔除，也可以同时打开深度测试
    glEnable(GL_CULL_FACE);
//    glEnable(GL_DEPTH_TEST);
    
//    索引绘图！！！！！
    //15.使用索引绘图
    /*
     void glDrawElements(GLenum mode,GLsizei count,GLenum type,const GLvoid * indices);
     参数列表：
     mode:要呈现的画图的模型
                GL_POINTS
                GL_LINES
                GL_LINE_LOOP
                GL_LINE_STRIP
                GL_TRIANGLES
                GL_TRIANGLE_STRIP
                GL_TRIANGLE_FAN
     count:绘图个数
     type:类型
             GL_BYTE
             GL_UNSIGNED_BYTE
             GL_SHORT
             GL_UNSIGNED_SHORT
             GL_INT
             GL_UNSIGNED_INT
     indices：绘制索引数组

     */
    /*
     model : 图元装配方式
     count： 绘图顶点个数（并不是顶点个数，是索引个数）
     type：类型，GL_UNSIGNED_BYTE
     indices：索引数组
     */
    glDrawElements(GL_TRIANGLES, sizeof(indices) / sizeof(indices[0]), GL_UNSIGNED_INT, indices);
    
//    准备绘制
    //16.要求本地窗口系统显示OpenGL ES渲染<目标>
   [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark --xyzClick
- (IBAction)xRotationClick:(id)sender {
    
//    开启定时器
    if (!timer) {
        timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    
    bX = !bX;
    
}
- (IBAction)yRotationClick:(id)sender {
    if (!timer) {
        timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    
    bY = !bY;
}
- (IBAction)zRotationClick:(id)sender {
    if (!timer) {
        timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    
    bZ = !bZ;
}

- (void)reDegree{
    
    //如果停止X轴旋转，X = 0则度数就停留在暂停前的度数.
    //更新度数
    xDegree += bX * 5;
    yDegree += bY * 5;
    zDegree += bZ * 5;
     //重新渲染
    [self renderLayer];
}



+ (Class)layerClass{
    return [CAEAGLLayer class];
}

#pragma mark --shader
//加载shader
-(GLuint)loadShaders:(NSString *)vert Withfrag:(NSString *)frag
{
    //创建2个临时的变量，verShader,fragShader
    GLuint verShader, fragShader;
    //创建一个Program
    GLuint program = glCreateProgram();
    
    //编译文件
    //编译顶点着色程序、片元着色器程序
    //参数1：编译完存储的底层地址
    //参数2：编译的类型，GL_VERTEX_SHADER（顶点）、GL_FRAGMENT_SHADER(片元)
    //参数3：文件路径
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    //创建最终的程序
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    //释放不需要的shader
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    glLinkProgram(program);
    GLint linkStatus;
    glGetProgramiv(program, GL_LINK_STATUS, &linkStatus);
    if (linkStatus == GL_FALSE) {
        GLchar message[512];
        glGetProgramInfoLog(program, sizeof(message), 0, &message[0]);
        NSString *messageString = [NSString stringWithUTF8String:message];
        NSLog(@"link program failed error: %@", messageString);
        exit(1);
    }
    NSLog(@"link program success");
    glUseProgram(program);
    
    return program;
}

//编译shader
- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file{
    //读取文件路径字符串
    NSString *content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    //获取文件路径字符串，C语言字符串
    const GLchar *source = (GLchar *)[content UTF8String];
    
    //创建一个shader（根据type类型）
    *shader = glCreateShader(type);
    
    //将顶点着色器源码附加到着色器对象上。
    //参数1：shader,要编译的着色器对象 *shader
    //参数2：numOfStrings,传递的源码字符串数量 1个
    //参数3：strings,着色器程序的源码（真正的着色器程序源码）
    //参数4：lenOfStrings,长度，具有每个字符串长度的数组，或NULL，这意味着字符串是NULL终止的
    glShaderSource(*shader, 1, &source, NULL);
    
    //把着色器源代码编译成目标代码
    glCompileShader(*shader);
    
}

@end





