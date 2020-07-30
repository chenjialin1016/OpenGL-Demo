//
//  MyView.m
//  10_GLSL_01
//
//  Created by  on 2020/7/28.
//

/*
 不采用GLKBaseEffect,使用编译链接自定的着色器，用简单的glsl语言来实现顶点、片元着色器，并图形进行简单的变换
 
 四路：
 1、创建图层
 2、创建上下文
 3、清空缓存区
 4、设置RenderBuffer
 5、设置FrameBuffer
 6、开始绘制
 
 
 一般shader 有问题:
 1. 检查 编写的shader 是否有误
 2. 检查 传递值的地方 标识是否写错了
 */

#import "MyView.h"
#import <OpenGLES/ES2/gl.h>

@interface MyView()

//在iOS和tvOS上绘制OpenGL ES内容的图层，继承与CALayer
@property (nonatomic, strong) CAEAGLLayer *myEagLayer;

@property (nonatomic, strong) EAGLContext *myContext;

@property (nonatomic, assign) GLuint myColorRenderBuffer;
@property (nonatomic, assign) GLuint myColorFrameBuffer;

@property (nonatomic, assign) GLuint myPrograme;

@end

@implementation MyView

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
//    1、创建特殊图层
    /*
    重写layerClass，将CCView返回的图层从CALayer替换成CAEAGLLayer
    */
    self.myEagLayer = (CAEAGLLayer*)self.layer;
    
//    2、设置scale
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    
//    3、设置描述属性
    /*
    kEAGLDrawablePropertyRetainedBacking  表示绘图表面显示后，是否保留其内容。
    kEAGLDrawablePropertyColorFormat
        可绘制表面的内部颜色缓存区格式，这个key对应的值是一个NSString指定特定颜色缓存区对象。默认是kEAGLColorFormatRGBA8；
    
        kEAGLColorFormatRGBA8：32位RGBA的颜色，4*8=32位
        kEAGLColorFormatRGB565：16位RGB的颜色，
        kEAGLColorFormatSRGBA8：sRGB代表了标准的红、绿、蓝，即CRT显示器、LCD显示器、投影机、打印机以及其他设备中色彩再现所使用的三个基本色素。sRGB的色彩空间基于独立的色彩坐标，可以使色彩在不同的设备使用传输中对应于同一个色彩坐标体系，而不受这些设备各自具有的不同色彩坐标的影响。


    */
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:@false, kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}

//2、创建上下文
- (void)setupContext{
//    1、指定OpenGL ES 渲染API版本
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
//    2、创建图形上下文
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:api];
//    3、判断是否创建成功
    if (!context) {
        NSLog(@"Create context failed!");
        return;
    }
    
//    4、设置图形上下文
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"setCurrentContext failed");
        return;
    }
    
//    5、将局部变量赋值给全局变量
    self.myContext = context;
}

//3、清空缓存区
- (void)deleteRenderAndFrameBuffer{
//    清空渲染缓存区
    glDeleteBuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
    
//    清空帧缓存区
    glDeleteBuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
}

//4、设置RenderBuffer
- (void)setupRenderBuffer{
//    1、定义一个缓存区ID
    GLuint buffer;
    
//    2、申请一个缓存区标识符
    glGenRenderbuffers(1, &buffer);
    
//    3、赋值给全局变量
    self.myColorRenderBuffer = buffer;
    
//    4、将标识符绑定到GL_RENDERBUFFER
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    
//    5、将可绘制对象drawable object的CAEAGLLayer的存储绑定到OpenGL ES renderBuffer对象
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
}

//5、设置FrameBuffer
- (void)setupFrameBuffer{
//    1、定义一个ID
    GLuint buffer;
    
//    2、申请一个缓存区标识符
    glGenBuffers(1, &buffer);
    
//    3、赋值给全局变量
    self.myColorFrameBuffer = buffer;
    
//    4、将标识符绑定到GL_FRAMEBUFFER
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    
//    5、将渲染缓存区的myColorRenderBuffer 通过 glFramebufferRenderbuffer函数绑定到GL_COLOR_ATTACHMENT0上
    /*
     glFramebufferRenderbuffer (GLenum target, GLenum attachment, GLenum renderbuffertarget, GLuint renderbuffer)
     参数1：绑定到的目标
     参数2：FrameBuffer的附着点
     参数3：需要绑定的渲染缓冲区目标
     参数4：渲染缓冲区
     */
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorRenderBuffer);
}

//6、开始绘制
- (void)renderLayer{
    
//    设置清屏颜色 & 清除屏幕
    glClearColor(0.3f, 0.45f, 0.5f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
//    1、设置视口大小
    CGFloat scale = [[UIScreen mainScreen] scale];
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    
//    2、读取顶点着色器、片元着色器
    NSString *vertFile = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"vsh"];
    NSString *fragFile = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"fsh"];
    
    NSLog(@"vertFile:%@",vertFile);
    NSLog(@"fragFile:%@",fragFile);
    
//    3、加载shader
    self.myPrograme = [self loadShaders:vertFile Withfrag:fragFile];
    
//    4、链接 & 获取链接状态
    glLinkProgram(self.myPrograme);
    GLint linkStatus;
//    获取链接状态
    glGetProgramiv(self.myPrograme, GL_LINK_STATUS, &linkStatus);
    if (linkStatus == GL_FALSE) {
        GLchar message[512];
//       获取错误信息日志
        glGetProgramInfoLog(self.myPrograme, sizeof(message), 0, &message[0]);
        NSString *messageString = [NSString stringWithUTF8String:message];
        NSLog(@"programe Link error: %@", messageString);
        return;
        
    }
    NSLog(@"Program Link Success!");
    
//    5、使用program
    glUseProgram(self.myPrograme);
    
//    6、设置顶点数据、纹理数据
    //前3个是顶点坐标，后2个是纹理坐标
    GLfloat attrArr[] =
    {
        0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
        -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
        -0.5f, -0.5f, -1.0f,    0.0f, 0.0f,
        
        0.5f, 0.5f, -1.0f,      1.0f, 1.0f,
        -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
        0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
    };
    
    
//    7、-----处理顶点数据--------
//    （1）顶点缓冲区
//    （2）申请一个缓存区标识符
//    （3）将attrBuffer绑定到GL_ARRAY_BUFFER标识符上
//    （4）将顶点数据从CPU拷贝到GPU上
    GLuint attrBuffer;
    glGenBuffers(1, &attrBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
//    8.将顶点数据通过myPrograme中的传递到顶点着色程序的position
//      1.glGetAttribLocation,用来获取vertex attribute的入口的.
//      2.告诉OpenGL ES,通过glEnableVertexAttribArray，
//      3.最后数据是通过glVertexAttribPointer传递过去的。

//     (1)注意：第二参数字符串必须和shaderv.vsh中的输入变量：position保持一致
    GLuint position = glGetAttribLocation(self.myPrograme, "position");
//     (2).设置合适的格式从buffer里面读取数据
    glEnableVertexAttribArray(position);
//     (3).设置读取方式
//          参数1：index,顶点数据的索引
//          参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
//                 参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
//          参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
//          参数5：stride,连续顶点属性之间的偏移量，默认为0；
//          参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, NULL);
    
//    9、处理纹理数据
//    (1).glGetAttribLocation,用来获取vertex attribute的入口的.
//    注意：第二参数字符串必须和shaderv.vsh中的输入变量：textCoordinate保持一致
//    (2).设置合适的格式从buffer里面读取数据
//    (3).设置读取方式
    GLuint textColor = glGetAttribLocation(self.myPrograme, "textCoordinate");
    glEnableVertexAttribArray(textColor);
    glVertexAttribPointer(textColor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, (float *)NULL+3);
    
//    10、加载纹理
    [self setupTexture:@"mouse"];
    
//    11、设置纹理采样器
    glUniform1i(glGetUniformLocation(self.myPrograme, "colorMap"), 0);
    
//    ！！！！！解决纹理倒置--方法1
    [self rotateTextureImage];
    
//    12、绘制
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
//    13、从渲染缓存区显示到屏幕上
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
    
}

- (void)rotateTextureImage{
    //注意，想要获取shader里面的变量，这里记得要在glLinkProgram后面，后面，后面！
       //1. rotate等于shaderv.vsh中的uniform属性，rotateMatrix
    
    GLuint rotate = glGetUniformLocation(self.myPrograme, "rotateMatrix");
    
    //2.获取渲旋转的弧度
    float radius = 180 * 3.14159f / 180.0f;
    //3.求得弧度对于的sin\cos值
    float s = sin(radius);
    float c = cos(radius);
    
    //4.因为在3D课程中用的是横向量，在OpenGL ES用的是列向量
    /*
     参考Z轴旋转矩阵
     */
    GLfloat zRotation[16] = {
        c, -s, 0, 0,
        s, c, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    };
    
    //5.设置旋转矩阵
    /*
     glUniformMatrix4fv (GLint location, GLsizei count, GLboolean transpose, const GLfloat* value)
     location : 对于shader 中的ID
     count : 个数
     transpose : 转置
     value : 指针
     */
    glUniformMatrix4fv(rotate, 1, GL_FALSE, zRotation);
    
}


//     从图片中加载纹理
- (GLuint)setupTexture: (NSString *)fileName {
//    1、将UIImage转换为CGImageRef & 判断图片是否获取成功
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    
    if (!spriteImage) {
        NSLog(@"Failed to lead image %@", fileName);
        exit(1);
    }
    
//    2、读取图片的大小、宽和高
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
//    3、获取图片字节数 宽*高*4（RGBA）
    GLubyte *spriteData = (GLubyte *)calloc(width*height*4, sizeof(GLubyte));
    
//    4、创建上下文
    /*
    参数1：data,指向要渲染的绘制图像的内存地址
    参数2：width,bitmap的宽度，单位为像素
    参数3：height,bitmap的高度，单位为像素
    参数4：bitPerComponent,内存中像素的每个组件的位数，比如32位RGBA，就设置为8
    参数5：bytesPerRow,bitmap的没一行的内存所占的比特数
    参数6：colorSpace,bitmap上使用的颜色空间  kCGImageAlphaPremultipliedLast：RGBA
    */
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    NSLog(@"kCGImageAlphaPremultipliedLast %d", kCGImageAlphaPremultipliedLast);
    
    
//    5、在CGContextRef上 --- 将图片绘制出来
    /*
    CGContextDrawImage 使用的是Core Graphics框架，坐标系与UIKit 不一样。UIKit框架的原点在屏幕的左上角，Core Graphics框架的原点在屏幕的左下角。
    CGContextDrawImage
    参数1：绘图上下文
    参数2：rect坐标
    参数3：绘制的图片
    */
    
    CGRect rect = CGRectMake(0, 0, width, height);
    
//    6、使用默认方式绘制
    CGContextDrawImage(spriteContext, rect, spriteImage);
    
//    7、画图完毕就释放上下文
    CGContextRelease(spriteContext);
    
//    8、绑定纹理到默认的纹理ID
    glBindTexture(GL_TEXTURE_2D, 0);
    
//    9、设置纹理属性
    /*
    参数1：纹理维度
    参数2：线性过滤、为s,t坐标设置模式
    参数3：wrapMode,环绕模式
    */
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    float fw = width, fh = height;
//    10、载入纹理2D数据
    /*
    参数1：纹理模式，GL_TEXTURE_1D、GL_TEXTURE_2D、GL_TEXTURE_3D
    参数2：加载的层次，一般设置为0
    参数3：纹理的颜色值GL_RGBA
    参数4：宽
    参数5：高
    参数6：border，边界宽度
    参数7：format
    参数8：type
    参数9：纹理数据
    */
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
//    11、释放spriteData
    free(spriteData);
    return 0;
}

+ (Class)layerClass{
    return [CAEAGLLayer class];
}

#pragma mark --shader
//加载shader
-(GLuint)loadShaders:(NSString *)vert Withfrag:(NSString *)frag
{
    //1.定义2个零时着色器对象
    GLuint verShader, fragShader;
    //创建program
    GLint program = glCreateProgram();

    //2.编译顶点着色程序、片元着色器程序
    //参数1：编译完存储的底层地址
    //参数2：编译的类型，GL_VERTEX_SHADER（顶点）、GL_FRAGMENT_SHADER(片元)
    //参数3：文件路径
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    NSLog(@"verShader %d, fragShader: %d", verShader, fragShader);

    //3.创建最终的程序
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);

    //4.释放不需要的shader
    glDeleteShader(verShader);
    glDeleteShader(fragShader);

    return program;
}

//编译shader
- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file{
    //1.读取文件路径字符串
    NSString* content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    const GLchar* source = (GLchar *)[content UTF8String];

    NSLog(@"content %@， source %s", content, source);
    //2.创建一个shader（根据type类型）
    *shader = glCreateShader(type);

    //3.将着色器源码附加到着色器对象上。
    //参数1：shader,要编译的着色器对象 *shader
    //参数2：numOfStrings,传递的源码字符串数量 1个
    //参数3：strings,着色器程序的源码（真正的着色器程序源码）
    //参数4：lenOfStrings,长度，具有每个字符串长度的数组，或NULL，这意味着字符串是NULL终止的
    glShaderSource(*shader, 1, &source,NULL);
    
    NSLog(@"shader %d", *shader);

    //4.把着色器源代码编译成目标代码
    glCompileShader(*shader);
}

@end





