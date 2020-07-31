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

    self.myEagLayer = (CAEAGLLayer*)self.layer;
    
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:@false, kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}

//2、创建上下文
- (void)setupContext{
    
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!context) {
        NSLog(@"create context failed");
        return;
    }
    
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"setCurrentContext failed");
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
    
    glClearColor(0.3, 0.4, 0.5, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    
    NSString *vertFile = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"vsh"];
    NSString *fragFile = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"fsh"];
    
    NSLog(@"vertFile:%@",vertFile);
    NSLog(@"fragFile:%@",fragFile);
    
    self.myPrograme = [self loadShaders:vertFile Withfrag:fragFile];
    
    GLfloat attrArr[] = {
        0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
        -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
        -0.5f, -0.5f, -1.0f,    0.0f, 0.0f,
       
        0.5f, 0.5f, -1.0f,      1.0f, 1.0f,
        -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
        0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
    };
    
    GLuint attrBuffer;
    glGenBuffers(1, &attrBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    GLuint position = glGetAttribLocation(self.myPrograme, "position");
    glEnableVertexAttribArray(position);
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, NULL);
    
    GLuint textColor = glGetAttribLocation(self.myPrograme, "textCoordinate");
    glEnableVertexAttribArray(textColor);
//    直接写null+3图片显示有问题，需要改为 (float *)NULL+3
    glVertexAttribPointer(textColor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, (float *)NULL+3);
    
    
    [self setupTexture:@"mouse"];
    
     glUniform1i(glGetUniformLocation(self.myPrograme, "colorMap"), 0);
    
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
    
}


//     从图片中加载纹理
- (GLuint)setupTexture: (NSString *)fileName {
    
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"get Image failed");
        exit(1);
    }
    
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte *spriteData = (GLubyte *)calloc(width*height*4, sizeof(GLubyte));

    CGContextRef context = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    CGRect rect = CGRectMake(0, 0, width, height);
    CGContextDrawImage(context, rect, spriteImage);
    
    CGContextRelease(context);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    float fw = width, fh = height;
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
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
    GLuint verShader, fragShader;
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
        NSLog(@"program link failed : %@", messageString);
        return 0;
    }
    NSLog(@"program link success!");
    glUseProgram(program);
    
    return program;
}

//编译shader
- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file{
    
    NSString *content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:NULL];
    const GLchar *source = (GLchar *)[content UTF8String];
    
    *shader = glCreateShader(type);
    
    glShaderSource(*shader, 1, &source, NULL);
    
    glCompileShader(*shader);
}

@end





