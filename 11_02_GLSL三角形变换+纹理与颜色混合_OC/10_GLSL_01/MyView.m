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
    self.myEagLayer = (CAEAGLLayer *)self.layer;
    
    [self setContentScaleFactor: [[UIScreen mainScreen] scale]];
    
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:@false, kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat, nil];
}

//2、创建上下文
- (void)setupContext{
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!context) {
        NSLog(@"create context failed");
        return;
    }
    
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"set current context failed");
        return;
    }
    
    self.myContext = context;
}

//3、清空缓存区
- (void)deleteRenderAndFrameBuffer{

    glDeleteBuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
    
    glDeleteBuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;

}
//4、设置RenderBuffer
- (void)setupRenderBuffer{
    
    glGenRenderbuffers(1, &_myColorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
    
}

//5、设置FrameBuffer
- (void)setupFrameBuffer{

    glGenBuffers(1, &_myColorFrameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorRenderBuffer);
    
}

//6、开始绘制
- (void)renderLayer{
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    float scale = [[UIScreen mainScreen] scale];
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    
    NSString *vertFile = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"glsl"];
    NSString *fragFile = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"glsl"];
    
    NSLog(@"vertFile %@", vertFile);
    NSLog(@"fragFile %@", fragFile);
    
    if (self.myPrograme) {
        glDeleteProgram(self.myPrograme);
        self.myPrograme = 0;
        
    }
    
    self.myPrograme = [self loadShaders:vertFile Withfrag:fragFile];
    
    if (self.myPrograme == 0) {
        return;
    }
    
    //前3个元素，是顶点数据；中间3个元素，是顶点颜色值，最后2个是纹理坐标
    GLfloat attrArr[] =
    {
        -0.5f, 0.5f, 0.0f,      1.0f, 0.0f, 1.0f,       0.0f, 1.0f,//左上
        0.5f, 0.5f, 0.0f,       1.0f, 0.0f, 1.0f,       1.0f, 1.0f,//右上
        -0.5f, -0.5f, 0.0f,     1.0f, 1.0f, 1.0f,       0.0f, 0.0f,//左下
        
        0.5f, -0.5f, 0.0f,      1.0f, 1.0f, 1.0f,       1.0f, 0.0f,//右下
        0.0f, 0.0f, 1.0f,       0.0f, 1.0f, 0.0f,       0.5f, 0.5f,//顶点
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
    
    if (self.myVertices == 0) {
        glGenBuffers(1, &_myVertices);
    }
    glBindBuffer(GL_ARRAY_BUFFER, _myVertices);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    GLuint position = glGetAttribLocation(self.myPrograme, "position");
    glEnableVertexAttribArray(position);
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*8, NULL);
    
    GLuint positionColor = glGetAttribLocation(self.myPrograme, "positionColor");
    glEnableVertexAttribArray(positionColor);
    glVertexAttribPointer(positionColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*8, (float*)NULL+3);
    
//    ---------处理纹理数据
    GLuint textCoord = glGetAttribLocation(self.myPrograme, "textCoordinate");
    glEnableVertexAttribArray(textCoord);
    glVertexAttribPointer(textCoord, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*8, (float*)NULL+6);
    
        
    //    ------加载纹理
    [self setupTexture:@"mouse"];
        
    //    ------设置纹理采样器
    glUniform1i(glGetUniformLocation(self.myPrograme, "colorMap"), 0);
    
//    构建矩阵
    GLuint projectionMatrixSlot = glGetUniformLocation(self.myPrograme, "projectionMatrix");
    GLuint modelViewMatrixSlot = glGetUniformLocation(self.myPrograme, "modelViewMatrix");
    
    float width = self.frame.size.width;
    float height = self.frame.size.height;
    float aspect = fabs(width / height);
    
    KSMatrix4 _projectionMatrix;
    ksMatrixLoadIdentity(&_projectionMatrix);
    ksPerspective(&_projectionMatrix, 30.0f, aspect, 5.0f, 20.0f);
    
    glUniformMatrix4fv(projectionMatrixSlot, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
    
    KSMatrix4 _modelViewMatrix;
    ksMatrixLoadIdentity(&_modelViewMatrix);
    ksTranslate(&_modelViewMatrix, 0, 0, -10.0f);
    
    KSMatrix4 _rotationMatrix;
    ksMatrixLoadIdentity(&_rotationMatrix);
    ksRotate(&_rotationMatrix, xDegree, 1, 0, 0);
    ksRotate(&_rotationMatrix, yDegree, 0, 1, 0);
    ksRotate(&_rotationMatrix, zDegree, 0, 0, 1);
    
    ksMatrixMultiply(&_modelViewMatrix, &_rotationMatrix, &_modelViewMatrix);
    glUniformMatrix4fv(modelViewMatrixSlot, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
    
    glEnable(GL_CULL_FACE);
    glEnable(GL_DEPTH_TEST);
    
    
    glDrawElements(GL_TRIANGLES, sizeof(indices) / sizeof(indices[0]), GL_UNSIGNED_INT, indices);
    
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
    
    
}

// -------加载纹理
- (GLuint)setupTexture: (NSString *)fileName{
    CGImageRef image = [UIImage imageNamed:fileName].CGImage;
    
    if (!image) {
        NSLog(@"failed to load image %@", fileName);
        exit(1);
    }
    
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    
    GLubyte *imageData = (GLubyte *)calloc(width*height*4, sizeof(GLubyte));
    
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, width*4, CGImageGetColorSpace(image), kCGImageAlphaPremultipliedLast);
    
    CGRect rect = CGRectMake(0, 0, width, height);
    CGContextDrawImage(context, rect, image);
    CGContextRelease(context);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    float fw = width, fh = height;
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    
    return 0;
}

#pragma mark --xyzClick
- (IBAction)xRotationClick:(id)sender {
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
    xDegree += bX * 5;
    yDegree += bY * 5;
    zDegree += bZ * 5;
    
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
    
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    glLinkProgram(program);
    GLint linkStatus;
    glGetProgramiv(program, GL_LINK_STATUS, &linkStatus);
    if (linkStatus == GL_FALSE) {
        GLchar message[512];
        glGetProgramInfoLog(program, sizeof(message), 0, &message[0]);
        NSString *messageString = [NSString stringWithUTF8String:message];
        NSLog(@"link program failed error %@", messageString);
        return 0;
    }
    NSLog(@"link program success");
    glUseProgram(program);
    
    return program;
}

//编译shader
- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file{
    NSString *content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    const GLchar *source = (GLchar *)[content UTF8String];
    
    *shader = glCreateShader(type);
    
    glShaderSource(*shader, 1, &source, nil);
    
    glCompileShader(*shader);
    
}

@end





