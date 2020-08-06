//
//  CCPointParticleEffect.m
//  01 粒子系统
//
//  Created by — on 2018/2/25.
//  Copyright © 2018年 —. All rights reserved.
//

#import "CCPointParticleEffect.h"
#import "CCVertexAttribArrayBuffer.h"
//用于定义粒子属性的类型
typedef struct
{
    GLKVector3 emissionPosition;//发射位置
    GLKVector3 emissionVelocity;//发射速度
    GLKVector3 emissionForce;//发射重力
    GLKVector2 size;//发射大小
    GLKVector2 emissionTimeAndLife;//发射时间和寿命[出生时间,死亡时间]
}CCParticleAttributes;

//GLSL程序Uniform 参数
enum
{
    CCMVPMatrix,//MVP矩阵
    CCSamplers2D,//Samplers2D纹理
    CCElapsedSeconds,//耗时
    CCGravity,//重力
    CCNumUniforms//Uniforms个数
};

//属性标识符
typedef enum {
    CCParticleEmissionPosition = 0,//粒子发射位置
    CCParticleEmissionVelocity,//粒子发射速度
    CCParticleEmissionForce,//粒子发射重力
    CCParticleSize,//粒子发射大小
    CCParticleEmissionTimeAndLife,//粒子发射时间和寿命
} CCParticleAttrib;

@interface CCPointParticleEffect()
{
    GLfloat elapsedSeconds;//耗时
    GLuint program;//程序
    GLint uniforms[CCNumUniforms];//Uniforms数组
}

//顶点属性数组缓冲区
@property (strong, nonatomic, readwrite)CCVertexAttribArrayBuffer  * particleAttributeBuffer;

//粒子个数
@property (nonatomic, assign, readonly) NSUInteger numberOfParticles;

//粒子属性数据
@property (nonatomic, strong, readonly) NSMutableData *particleAttributesData;

//是否更新粒子数据
@property (nonatomic, assign, readwrite) BOOL particleDataWasUpdated;

//加载shaders
- (BOOL)loadShaders;

//编译shaders
- (BOOL)compileShader:(GLuint *)shader
                 type:(GLenum)type
                 file:(NSString *)file;
//链接Program
- (BOOL)linkProgram:(GLuint)prog;

//验证Program
- (BOOL)validateProgram:(GLuint)prog;

@end

@implementation CCPointParticleEffect

@synthesize gravity;
@synthesize elapsedSeconds;
@synthesize texture2d0;
@synthesize transform;
@synthesize particleAttributeBuffer;
@synthesize particleAttributesData;
@synthesize particleDataWasUpdated;

//初始化
-(id)init
{
    self = [super init];
    if (self != nil) {
        
        //1.初始化纹理属性
        //初始化
        texture2d0 = [[GLKEffectPropertyTexture alloc] init];
        //是否可用
        texture2d0.enabled = YES;
        //命名纹理对象
        /*
         等价于:
         void glGenTextures (GLsizei n, GLuint *textures);
         //在数组textures中返回n个当期未使用的值，表示纹理对象的名称
         //零作为一个保留的纹理对象名，它不会被此函数当做纹理对象名称而返回
         */
        texture2d0.name = 0;
        
        //纹理类型 默认值是glktexturetarget2d
        texture2d0.target = GLKTextureTarget2D;
        //纹理用于计算其输出片段颜色的模式。看到GLKTextureEnvMode。
        /*
         GLKTextureEnvModeReplace,输出颜色设置为从纹理获取的颜色。忽略输入颜色
         GLKTextureEnvModeModulate, 默认!输出颜色是通过将纹理的颜色乘以输入颜色来计算的
         GLKTextureEnvModeDecal,输出颜色是通过使用纹理的alpha组件来混合纹理颜色和输入颜色来计算的。
         */
        texture2d0.envMode = GLKTextureEnvModeReplace;
        
        //坐标变换的信息用于GLKit渲染效果。GLKEffectPropertyTransform类定义的属性进行渲染时的效果提供的坐标变换。
        transform = [[GLKEffectPropertyTransform alloc] init];
        
        //重力.默认地球重力
        gravity = CCDefaultGravity;
        
        //耗时
        elapsedSeconds = 0.0f;
        
        //粒子属性数据
        particleAttributesData = [NSMutableData data];

    }
    
    return self;
}

//获取粒子的属性值
- (CCParticleAttributes)particleAtIndex:(NSUInteger)anIndex
{
    
    //bytes:指向接收者内容的指针
    //获取粒子属性结构体内容
    const CCParticleAttributes *particlesPtr = (const CCParticleAttributes *)[self.particleAttributesData bytes];
    
    //获取属性结构体中的某一个指标
    return particlesPtr[anIndex];
}


//设置粒子的属性
- (void)setParticle:(CCParticleAttributes)aParticle
            atIndex:(NSUInteger)anIndex
{
    //mutableBytes:指向可变数据对象所包含数据的指针
    //获取粒子属性结构体内容
    CCParticleAttributes *particlesPtr = (CCParticleAttributes *)[self.particleAttributesData mutableBytes];
    
    //将粒子结构体对应的属性修改为新值
    particlesPtr[anIndex] = aParticle;
    
    //更改粒子状态! 是否更新
    self.particleDataWasUpdated = YES;
}

//添加一个粒子
- (void)addParticleAtPosition:(GLKVector3)aPosition
                     velocity:(GLKVector3)aVelocity
                        force:(GLKVector3)aForce
                         size:(float)aSize
              lifeSpanSeconds:(NSTimeInterval)aSpan
          fadeDurationSeconds:(NSTimeInterval)aDuration;
{
    //创建新的例子
    CCParticleAttributes newParticle;
    //设置相关参数(位置\速度\抛物线\大小\耗时)
    newParticle.emissionPosition = aPosition;
    newParticle.emissionVelocity = aVelocity;
    newParticle.emissionForce = aForce;
    newParticle.size = GLKVector2Make(aSize, aDuration);
    //向量(耗时,发射时长)
    newParticle.emissionTimeAndLife = GLKVector2Make(elapsedSeconds, elapsedSeconds + aSpan);
    
    BOOL foundSlot = NO;
    
    //粒子个数
    const long count = self.numberOfParticles;
    
    //循环设置粒子到数组中
    for(int i = 0; i < count && !foundSlot; i++)
    {
        
        //获取当前旧的例子
        CCParticleAttributes oldParticle = [self particleAtIndex:i];
        
        //如果旧的例子的死亡时间 小于 当前时间
        //emissionTimeAndLife.y = elapsedSeconds + aspan
        if(oldParticle.emissionTimeAndLife.y < self.elapsedSeconds)
        {
            //更新例子的属性
            [self setParticle:newParticle atIndex:i];
            
            //是否替换
            foundSlot = YES;
        }
    }
    
    //如果不替换
    if(!foundSlot)
    {
        //在particleAttributesData 拼接新的数据
        [self.particleAttributesData appendBytes:&newParticle
                                          length:sizeof(newParticle)];
        
        //粒子数据是否更新
        self.particleDataWasUpdated = YES;
    }
}

//获取粒子个数
- (NSUInteger)numberOfParticles;
{
    static long last;
    //总数据/粒子结构体大小
    long ret = [self.particleAttributesData length] / sizeof(CCParticleAttributes);
    
    //如果last != ret 表示粒子个数更新了
    if (last != ret) {
        //则修改last数量
        last = ret;
        NSLog(@"count %ld", ret);
    }
    
    return ret;
}


- (void)prepareToDraw
{
    //program =0 ,则加载shaders
    if(program == 0)
    {
        //加载shaders(顶点\片元)
        [self loadShaders];
    }
    
    if(program != 0)
    {
        //使用program
        glUseProgram(program);
        
        // 计算MVP矩阵变化
        //投影矩阵 与 模式视图矩阵 相乘结果
        GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4Multiply(self.transform.projectionMatrix,self.transform.modelviewMatrix);
        //将结果矩阵,通过unifrom传递
        /*
         glUniformMatrix4fv (GLint location, GLsizei count, GLboolean transpose, const GLfloat* value)
        参数1:location,要更改的uniforms变量的位置
        参数2:cout ,更改矩阵的个数
        参数3:transpose,指是否要转置矩阵,并将它作为uniform变量的值,必须为GL_FALSE
        参数4:value ,指向count个数的元素指针.用来更新uniform变量的值.
        */
//      m 结构体中的首地址
        glUniformMatrix4fv(uniforms[CCMVPMatrix], 1, 0,modelViewProjectionMatrix.m);
        
        // 一个纹理采样均匀变量
        /*
          glUniform1f(GLint location,  GLfloat v0); 
         
         location:指明要更改的uniform变量的位置
         v0:指明在指定的uniform变量中要使用的新值
         */
        glUniform1i(uniforms[CCSamplers2D], 0);
        
        //粒子物理值
        //重力
        /*
         void glUniform3fv(GLint location,  GLsizei count,  const GLfloat *value); 
         参数列表：
         location:指明要更改的uniform变量的位置
         count:指明要更改的向量个数
         value:指明一个指向count个元素的指针，用来更新指定的uniform变量。
         
         */
//        v 首地址
        glUniform3fv(uniforms[CCGravity], 1, self.gravity.v);
        
        //耗时
        glUniform1fv(uniforms[CCElapsedSeconds], 1, &elapsedSeconds);
        
        //粒子数据更新
        if(self.particleDataWasUpdated)
        {
            //缓存区为空,且粒子数据大小>0
            if(self.particleAttributeBuffer == nil && [self.particleAttributesData length] > 0)
                
            {  // 顶点属性没有送到GPU
                //初始化缓存区
                /*
                  1.数据大小  sizeof(CCParticleAttributes)
                  2.数据个数 (int)[self.particleAttributesData length] /
                 sizeof(CCParticleAttributes)
                  3.数据源  [self.particleAttributesData bytes]
                  4.用途 GL_DYNAMIC_DRAW
                 */
                
                //数据大小
                GLsizeiptr size = sizeof(CCParticleAttributes);
                //个数
                int count = (int)[self.particleAttributesData length] /
                sizeof(CCParticleAttributes);
                
                self.particleAttributeBuffer =
                [[CCVertexAttribArrayBuffer alloc]
                 initWithAttribStride:size
                 numberOfVertices:count
                 bytes:[self.particleAttributesData bytes]
                 usage:GL_DYNAMIC_DRAW];
            }
            else
            {
                //如果已经开辟空间,则接收新的数据
                /*
                 1.数据大小 sizeof(CCParticleAttributes)
                 2.数据个数  (int)[self.particleAttributesData length] /
                 sizeof(CCParticleAttributes)
                 3.数据源 [self.particleAttributesData bytes]
                 */
                
                //数据大小
                GLsizeiptr size = sizeof(CCParticleAttributes);
                //个数
                int count = (int)[self.particleAttributesData length] /
                sizeof(CCParticleAttributes);
                
                [self.particleAttributeBuffer
                 reinitWithAttribStride:size
                 numberOfVertices:count
                 bytes:[self.particleAttributesData bytes]];
            }
            
            //恢复更新状态为NO
            self.particleDataWasUpdated = NO;
        }
        
        //准备顶点数据
        [self.particleAttributeBuffer
         prepareToDrawWithAttrib:CCParticleEmissionPosition
         numberOfCoordinates:3
         attribOffset:
         offsetof(CCParticleAttributes, emissionPosition)
         shouldEnable:YES];
        
        //准备粒子发射速度数据
        [self.particleAttributeBuffer
         prepareToDrawWithAttrib:CCParticleEmissionVelocity
         numberOfCoordinates:3
         attribOffset:
         offsetof(CCParticleAttributes, emissionVelocity)
         shouldEnable:YES];
        
        //准备重力数据
        [self.particleAttributeBuffer
         prepareToDrawWithAttrib:CCParticleEmissionForce
         numberOfCoordinates:3
         attribOffset:
         offsetof(CCParticleAttributes, emissionForce)
         shouldEnable:YES];
        
        //准备粒子size数据
        [self.particleAttributeBuffer
         prepareToDrawWithAttrib:CCParticleSize
         numberOfCoordinates:2
         attribOffset:
         offsetof(CCParticleAttributes, size)
         shouldEnable:YES];
        
        //准备粒子的持续时间和渐隐时间数据
        [self.particleAttributeBuffer
         prepareToDrawWithAttrib:CCParticleEmissionTimeAndLife
         numberOfCoordinates:2
         attribOffset:
         offsetof(CCParticleAttributes, emissionTimeAndLife)
         shouldEnable:YES];
        
        //将所有纹理绑定到各自的单位
        /*
         void glActiveTexture(GLenum texUnit);
         
         该函数选择一个纹理单元，线面的纹理函数将作用于该纹理单元上，参数为符号常量GL_TEXTUREi ，i的取值范围为0~K-1，K是OpenGL实现支持的最大纹理单元数，可以使用GL_MAX_TEXTURE_UNITS来调用函数glGetIntegerv()获取该值
         
         可以这样简单的理解为：显卡中有N个纹理单元（具体数目依赖你的显卡能力），每个纹理单元（GL_TEXTURE0、GL_TEXTURE1等）都有GL_TEXTURE_1D、GL_TEXTURE_2D等
         */
        glActiveTexture(GL_TEXTURE0);
        
        //判断纹理标记是否为空,以及纹理是否可用
        if(0 != self.texture2d0.name && self.texture2d0.enabled)
        {
            //绑定纹理到纹理标记上
            //参数1:纹理类型
            //参数2:纹理名称
            glBindTexture(GL_TEXTURE_2D, self.texture2d0.name);
        }
        else
        {
            //绑定一个空的
            glBindTexture(GL_TEXTURE_2D, 0);
        }
    }
}

//绘制
- (void)draw;
{
    //禁用深度缓冲区写入：如果开启了，则无法实现粒子效果，因为有粒子重叠
    glDepthMask(GL_FALSE);
    
    //绘制
    /*
     1.模式
     2.开始的位置
     3.粒子个数
     */
    [self.particleAttributeBuffer drawArrayWithMode:GL_POINTS startVertexIndex:0 numberOfVertices:(int)self.numberOfParticles];
    
    //启用深度缓冲区写入
    glDepthMask(GL_TRUE);
}

#pragma mark -  OpenGL ES shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    //创建program
    program = glCreateProgram();
    
    //创建并编译 vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:
                          @"CCPointParticleShader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER
                        file:vertShaderPathname])
    {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // 创建并编译 fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:
                          @"CCPointParticleShader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER
                        file:fragShaderPathname])
    {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    //将vertex shader 附加到程序.
    glAttachShader(program, vertShader);
    
    //将fragment shader 附加到程序.
    glAttachShader(program, fragShader);
    
    //绑定属性位置
    //这需要在链接之前完成.
    /*
     应用程序通过glBindAttribLocation把“顶点属性索引”绑定到“顶点属性名”，glBindAttribLocation在program被link之前执行。
     void glBindAttribLocation(GLuint program, GLuint index,const GLchar *name)  
     program:对应的程序
     index:顶点属性索引
     name:属性名称
     */
    
    //位置
    glBindAttribLocation(program, CCParticleEmissionPosition,
                         "a_emissionPosition");
    //速度
    glBindAttribLocation(program, CCParticleEmissionVelocity,
                         "a_emissionVelocity");
    //重力
    glBindAttribLocation(program, CCParticleEmissionForce,
                         "a_emissionForce");
    //大小
    glBindAttribLocation(program, CCParticleSize,
                         "a_size");
    //持续时间、渐隐时间
    glBindAttribLocation(program, CCParticleEmissionTimeAndLife,
                         "a_emissionAndDeathTimes");
    
    // Link program 失败
    if (![self linkProgram:program])
    {
        NSLog(@"Failed to link program: %d", program);
        
        //link识别,删除vertex shader\fragment shader\program
        if (vertShader)
        {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader)
        {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (program)
        {
            glDeleteProgram(program);
            program = 0;
        }
        
        return NO;
    }
    
    // 获取uniform变量的位置.
    //MVP变换矩阵
    uniforms[CCMVPMatrix] = glGetUniformLocation(program,"u_mvpMatrix");
    //纹理
    uniforms[CCSamplers2D] = glGetUniformLocation(program,"u_samplers2D");
    //重力
    uniforms[CCGravity] = glGetUniformLocation(program,"u_gravity");
    //持续时间、渐隐时间
    uniforms[CCElapsedSeconds] = glGetUniformLocation(program,"u_elapsedSeconds");
    
    //使用完
    // 删除 vertex and fragment shaders.
    if (vertShader)
    {
        glDetachShader(program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader)
    {
        glDetachShader(program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}


//编译shader
- (BOOL)compileShader:(GLuint *)shader
                 type:(GLenum)type
                 file:(NSString *)file
{
    //状态
    //GLint status;
    //路径-C语言
    const GLchar *source;
    
    //从OC字符串中获取C语言字符串
    //获取路径
    source = (GLchar *)[[NSString stringWithContentsOfFile:file
                                                  encoding:NSUTF8StringEncoding error:nil] UTF8String];
    //判断路径
    if (!source)
    {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    //创建shader-顶点\片元
    *shader = glCreateShader(type);
    
    //绑定shader
    glShaderSource(*shader, 1, &source, NULL);
   
    //编译Shader
    glCompileShader(*shader);
    
    //获取加载Shader的日志信息
    //日志信息长度
    GLint logLength;
    /*
     在OpenGL中有方法能够获取到 shader错误
     参数1:对象,从哪个Shader
     参数2:获取信息类别,
     GL_COMPILE_STATUS       //编译状态
     GL_INFO_LOG_LENGTH      //日志长度
     GL_SHADER_SOURCE_LENGTH //着色器源文件长度
     GL_SHADER_COMPILER  //着色器编译器
     参数3:获取长度
     */
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    
    //判断日志长度 > 0
    if (logLength > 0)
    {
        //创建日志字符串
        GLchar *log = (GLchar *)malloc(logLength);
       
        /*
         获取日志信息
         参数1:着色器
         参数2:日志信息长度
         参数3:日志信息长度地址
         参数4:日志存储的位置
         */
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
       
        //打印日志信息
        NSLog(@"Shader compile log:\n%s", log);
      
        //释放日志字符串
        free(log);
        return NO;
    }

    
    return YES;
}

//链接program
- (BOOL)linkProgram:(GLuint)prog
{
    //状态
    //GLint status;
    //链接Programe
    glLinkProgram(prog);
    //打印链接program的日志信息
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
        
        return NO;
    }
    
    return YES;
}

//验证Program
- (BOOL)validateProgram:(GLuint)prog
{
    //日志长度,验证状态
    GLint logLength, status;
    
    //验证prgogram
    //http://www.dreamingwish.com/frontui/article/default/glvalidateprogram.html
    /*
     glValidateProgram 检测program中包含的执行段在给定的当前OpenGL状态下是否可执行。验证过程产生的信息会被存储在program日志中。验证信息可能由一个空字符串组成，或者可能是一个包含当前程序对象如何与余下的OpenGL当前状态交互的信息的字符串。这为OpenGL实现提供了一个方法来调查更多关于程序效率低下、低优化、执行失败等的信息。
     验证操作的结果状态值会被存储为程序对象状态的一部分。如果验证成功，这个值会被置为GL_TURE，反之置为GL_FALSE。调用函数 glGetProgramiv 传入参数 program和GL_VALIDATE_STATUS可以查询这个值。在给定当前状态下，如果验证成功，那么 program保证可以执行，反之保证不会执行
     
     GL_INVALID_VALUE 错误：如果 program 不是由 OpenGL生成的值.
     GL_INVALID_OPERATION 错误：如果 program 不是一个程序对象.
     */
    glValidateProgram(prog);
    
    //获取验证的日志信息
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    //获取验证的状态--验证结果
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    //根据验证结果返回NO or YES
    if (status == 0)
    {
        return NO;
    }
    
    return YES;
}

//默认重力加速度向量与地球的匹配
//{ 0，（-9.80665米/秒/秒），0 }假设+ Y坐标系的建立
//默认重力
const GLKVector3 CCDefaultGravity = {0.0f, -9.80665f, 0.0f};

@end
