//
//  LongLegView.m
//  001--CClhDemo
//
//  Created by CC老师 on 2020/6/22.
//  Copyright © 2020年 CC老师. All rights reserved.
//
#import "LongLegHelper.h"
#import "LongLegVertexAttribArrayBuffer.h"
#import "LongLegView.h"
// 初始纹理高度占控件高度的比例
static CGFloat const kDefaultOriginTextureHeight = 0.7f;
// 顶点数量
static NSInteger const kVerticesCount = 8;

//SenceVertex 结构体
typedef struct {
    GLKVector3 positionCoord; //顶点坐标;
    GLKVector2 textureCoord;  //纹理坐标;
} SenceVertex;

@interface LongLegView () <GLKViewDelegate>
//Effect
@property (nonatomic, strong) GLKBaseEffect *baseEffect;
//顶点;
@property (nonatomic, assign) SenceVertex *vertices;
//顶点数组缓存区;
@property (nonatomic, strong) LongLegVertexAttribArrayBuffer *vertexAttribArrayBuffer;
//当前图片Size;
@property (nonatomic, assign) CGSize currentImageSize;
//是否有发现修改;
@property (nonatomic, assign, readwrite) BOOL hasChange;
//当前纹理的width;
@property (nonatomic, assign) CGFloat currentTextureWidth;

//临时创建的帧缓存和纹理缓存
@property (nonatomic, assign) GLuint tmpFrameBuffer;
@property (nonatomic, assign) GLuint tmpTexture;

// 用于重新绘制纹理
//当前纹理Y的开始位置;
@property (nonatomic, assign) CGFloat currentTextureStartY;
//当前纹理Y的结束位置;
@property (nonatomic, assign) CGFloat currentTextureEndY;
//当前纹理新的高度;
@property (nonatomic, assign) CGFloat currentNewHeight;

@end

@implementation LongLegView

//销毁
- (void)dealloc {
    
    //销毁context
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    //销毁_vertices
    if (_vertices) {
        free(_vertices);
        _vertices = nil;
    }
    //销毁帧缓存区
    if (_tmpFrameBuffer) {
        glDeleteFramebuffers(1, &_tmpFrameBuffer);
        _tmpFrameBuffer = 0;
    }
    //销毁纹理
    if (_tmpTexture) {
        glDeleteTextures(1, &_tmpTexture);
        _tmpTexture = 0;
    }
}

//初始化
- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}
//初始化
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

#pragma mark - Public
/**
 将区域拉伸或压缩为某个高度
 @param startY 开始的纵坐标位置（相对于纹理）
 @param endY 结束的纵坐标位置（相对于纹理）
 @param newHeight 新的中间区域高度（相对于纹理）
 */
- (void)stretchingFromStartY:(CGFloat)startY
                      toEndY:(CGFloat)endY
               withNewHeight:(CGFloat)newHeight {
    self.hasChange = YES;
    
//    1、根据当前控件的尺寸和纹理尺寸，计算初始纹理坐标
    //新的顶点坐标 & 纹理坐标的变化
    [self calculateOriginTextureCoordWithTextureSize:self.currentImageSize startY:startY endY:endY newHeight:newHeight];
    
//    2、更新顶点数组缓存区的数据
    [self.vertexAttribArrayBuffer updateDataWithAttribStride:sizeof(SenceVertex) numberOfVertices:kVerticesCount data:self.vertices usage:GL_STATIC_DRAW];
    
//    3、显示
    [self display];
    
//    4、change改变完毕后，通知ViewController 的 SpringView拉伸区域修改
    if (self.springDelegate && [self.springDelegate respondsToSelector:@selector(springViewStretchAreaDidChanged:)]) {
        [self.springDelegate springViewStretchAreaDidChanged:self];
    }
}


//从帧缓存区中获取纹理图片文件; 获取当前的渲染结果
- (UIImage *)createResult {
    
//    1、根据屏幕显示的图片，重新获取顶点 & 纹理坐标
//    拉伸--显示：baseEffect、图片获取--存储：GLSL
//    滤镜链：顶点&纹理坐标--GLSL绘制图片--帧缓存区--纹理（即新的图片），当次处理的结果作为下一次处理的初始图片
    [self resetTextureWithOriginWidth:self.currentImageSize.width originHeight:self.currentImageSize.height topY:self.currentTextureStartY bottomY:self.currentTextureEndY newHeight:self.currentNewHeight];
    
//    2、绑定帧缓存区
    glBindBuffer(GL_FRAMEBUFFER, self.tmpFrameBuffer);
    
//    3、获取新的图片size
    CGSize imageSize = [self newImageSize];
    
//    4、从帧缓存区中获取拉伸后的图片
    UIImage *image = [self imageFromTextureWithWidth:imageSize.width height:imageSize.height];
    
//    5、将帧缓存区绑定0，清空
    glBindBuffer(GL_FRAMEBUFFER, 0);
    
//    6、返回拉伸后的图片
    return image;
}

// 根据当前的拉伸结果来重新生成纹理
- (void)updateTexture {
    
    //1.设置新的纹理
    if (self.baseEffect.texture2d0.name != 0) {
        //获取原始的纹理ID
        GLuint textureName = self.baseEffect.texture2d0.name;
        //删除纹理
        glDeleteTextures(1, &textureName);
    }
    
    //2.重新设置新的纹理ID;
    self.baseEffect.texture2d0.name = self.tmpTexture;
    
    //3. 重置图片的尺寸
    self.currentImageSize = [self newImageSize];
    
    self.hasChange = NO;
    
    //4. 更新纹理的顶点/纹理坐标信息;
    [self calculateOriginTextureCoordWithTextureSize:self.currentImageSize
                                              startY:0
                                                endY:0
                                           newHeight:0];
    //5. 更新顶点数组缓存里的顶点/纹理坐标数据;
    [self.vertexAttribArrayBuffer updateDataWithAttribStride:sizeof(SenceVertex)
                                            numberOfVertices:kVerticesCount
                                                        data:self.vertices
                                                       usage:GL_STATIC_DRAW];
    //6. 显示;
    [self display];
  
}

// 更新图片
- (void)updateImage:(UIImage *)image {
    
    //记录SpringView是否发生拉伸动作
    self.hasChange = NO;
    
    //1.GLKTextureInfo 设置纹理参数
    NSDictionary *options = @{GLKTextureLoaderOriginBottomLeft : @(YES)};
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:[image CGImage]
                                                               options:options
                                                                 error:NULL];
    //2.创建GLKBaseEffect 方法.
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.texture2d0.name = textureInfo.name;
    
    //3.记录当前图片的size = 图片本身的size;
    self.currentImageSize = image.size;
    
    //4.计算出图片的宽高比例
    CGFloat ratio = (self.currentImageSize.height / self.currentImageSize.width) *
    (self.bounds.size.width / self.bounds.size.height);
    
    NSLog(@"图片的宽高比例: %f - %f、%f- %f、%f", self.currentImageSize.width, self.currentImageSize.height, self.bounds.size.width, self.bounds.size.height, ratio);
    
    //5. 获取纹理的高度;
    CGFloat textureHeight = MIN(ratio, kDefaultOriginTextureHeight);
    //6. 根据纹理的高度以及宽度, 计算出图片合理的宽度;
    self.currentTextureWidth = textureHeight / ratio;
    
    //7.根据当前控件的尺寸以及纹理的尺寸,计算纹理坐标以及顶点坐标;
    [self calculateOriginTextureCoordWithTextureSize:self.currentImageSize
                                              startY:0
                                                endY:0
                                           newHeight:0];
    //8. 更新顶点数组缓存区;
    [self.vertexAttribArrayBuffer updateDataWithAttribStride:sizeof(SenceVertex)
                                            numberOfVertices:kVerticesCount
                                                        data:self.vertices
                                                       usage:GL_STATIC_DRAW];
    //9. 显示(绘制)
    [self display];
}

#pragma mark - Private

//初始化
- (void)commonInit {
    
    //1.初始化vertices,context
    self.vertices = malloc(sizeof(SenceVertex) * kVerticesCount);
    self.backgroundColor = [UIColor clearColor];
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    self.delegate = self;
    [EAGLContext setCurrentContext:self.context];
    glClearColor(0, 0, 0, 0);
    
    //2.初始化vertexAttribArrayBuffer
    self.vertexAttribArrayBuffer = [[LongLegVertexAttribArrayBuffer alloc] initWithAttribStride:sizeof(SenceVertex) numberOfVertices:kVerticesCount data:self.vertices usage:GL_STATIC_DRAW];
}

/**
 根据当前控件的尺寸和纹理的尺寸，计算初始纹理坐标
 
 @param size 原始纹理尺寸
 @param startY 中间区域的开始纵坐标位置 0~1
 @param endY 中间区域的结束纵坐标位置 0~1
 @param newHeight 新的中间区域的高度
 */
- (void)calculateOriginTextureCoordWithTextureSize:(CGSize)size
                                            startY:(CGFloat)startY
                                              endY:(CGFloat)endY
                                         newHeight:(CGFloat)newHeight {
    NSLog(@"%f,%f",size.height,size.width);
    
    //1. 计算拉伸后的宽高比;
    CGFloat ratio = (size.height / size.width) *
    (self.bounds.size.width / self.bounds.size.height);
    //2. 宽度=纹理本身宽度 （初始化时 = 0.8）
    CGFloat textureWidth = self.currentTextureWidth;
    //3. 高度=纹理宽度*radio(宽高比) （初始化时 = 0.7）
    CGFloat textureHeight = textureWidth * ratio;
    
    NSLog(@"%f,%f,%f,%f",newHeight,endY,startY,textureHeight);
    //4. 拉伸量 (newHeight - (endY-startY)) * 纹理高度;即换算成纹理的拉伸量
    CGFloat delta = (newHeight - (endY -  startY)) * textureHeight;
    
    //5. 判断纹理高度+拉伸量是否超出最大值1
    if (textureHeight + delta >= 1) {
        delta = 1 - textureHeight;
        newHeight = delta / textureHeight + (endY -  startY);
    }
    
    //6. 纹理4个角的顶点
    // 左上角
    GLKVector3 pointLT = {-textureWidth, textureHeight + delta, 0};
    // 右上角
    GLKVector3 pointRT = {textureWidth, textureHeight + delta, 0};
    // 左下角
    GLKVector3 pointLB = {-textureWidth, -textureHeight - delta, 0};
    // 右下角
    GLKVector3 pointRB = {textureWidth, -textureHeight - delta, 0};
    
    // 中间矩形区域的顶点
    //0.7 - 2 * 0.7 * 0.25
    CGFloat tempStartYCoord = textureHeight - 2 * textureHeight * startY;
    CGFloat tempEndYCoord = textureHeight - 2 * textureHeight * endY;
    
    CGFloat startYCoord = MIN(tempStartYCoord, textureHeight);
    CGFloat endYCoord = MAX(tempEndYCoord, -textureHeight);
   
    // 中间部分左上角
    GLKVector3 centerPointLT = {-textureWidth, startYCoord + delta, 0};
    // 中间部分右上角
    GLKVector3 centerPointRT = {textureWidth, startYCoord + delta, 0};
    // 中间部分左下角
    GLKVector3 centerPointLB = {-textureWidth, endYCoord - delta, 0};
    // 中间部分右下角
    GLKVector3 centerPointRB = {textureWidth, endYCoord - delta, 0};
    
    //--纹理的上面两个顶点
    //顶点V0的顶点坐标以及纹理坐标;
    self.vertices[0].positionCoord = pointRT;
    self.vertices[0].textureCoord = GLKVector2Make(1, 1);
    
    //顶点V1的顶点坐标以及纹理坐标;
    self.vertices[1].positionCoord = pointLT;
    self.vertices[1].textureCoord = GLKVector2Make(0, 1);
    
    //--中间区域的4个顶点
    //顶点V2的顶点坐标以及纹理坐标;
    self.vertices[2].positionCoord = centerPointRT;
    self.vertices[2].textureCoord = GLKVector2Make(1, 1 - startY);
    
    //顶点V3的顶点坐标以及纹理坐标;
    self.vertices[3].positionCoord = centerPointLT;
    self.vertices[3].textureCoord = GLKVector2Make(0, 1 - startY);
    
    //顶点V4的顶点坐标以及纹理坐标;
    self.vertices[4].positionCoord = centerPointRB;
    self.vertices[4].textureCoord = GLKVector2Make(1, 1 - endY);
    
    //顶点V5的顶点坐标以及纹理坐标;
    self.vertices[5].positionCoord = centerPointLB;
    self.vertices[5].textureCoord = GLKVector2Make(0, 1 - endY);
    
    // 纹理的下面两个顶点
    //顶点V6的顶点坐标以及纹理坐标;
    self.vertices[6].positionCoord = pointRB;
    self.vertices[6].textureCoord = GLKVector2Make(1, 0);
    
    //顶点V7的顶点坐标以及纹理坐标;
    self.vertices[7].positionCoord = pointLB;
    self.vertices[7].textureCoord = GLKVector2Make(0, 0);
    
    // 保存临时值
    self.currentTextureStartY = startY;
    self.currentTextureEndY = endY;
    self.currentNewHeight = newHeight;
}


/**
 根据当前屏幕上的显示，来重新创建纹理
 
 @param originWidth 纹理的原始实际宽度
 @param originHeight 纹理的原始实际高度
 @param topY 0 ~ 1，拉伸区域的顶边的纵坐标
 @param bottomY 0 ~ 1，拉伸区域的底边的纵坐标
 @param newHeight 0 ~ 1，拉伸区域的新高度
 */
- (void)resetTextureWithOriginWidth:(CGFloat)originWidth
                       originHeight:(CGFloat)originHeight
                               topY:(CGFloat)topY
                            bottomY:(CGFloat)bottomY
                          newHeight:(CGFloat)newHeight {
   //1.新的纹理尺寸(新纹理图片的宽高)
   GLsizei newTextureWidth = originWidth;
   GLsizei newTextureHeight = originHeight * (newHeight - (bottomY - topY)) + originHeight;
   
   //2.高度变化百分比
   CGFloat heightScale = newTextureHeight / originHeight;
   
   //3.在新的纹理坐标下，重新计算topY、bottomY
   CGFloat newTopY = topY / heightScale;
   CGFloat newBottomY = (topY + newHeight) / heightScale;
   
   //4.创建顶点数组与纹理数组(逻辑与calculateOriginTextureCoordWithTextureSize 中关于纹理坐标以及顶点坐标逻辑是一模一样的)
   SenceVertex *tmpVertices = malloc(sizeof(SenceVertex) * kVerticesCount);
   tmpVertices[0] = (SenceVertex){{-1, 1, 0}, {0, 1}};
   tmpVertices[1] = (SenceVertex){{1, 1, 0}, {1, 1}};
   tmpVertices[2] = (SenceVertex){{-1, -2 * newTopY + 1, 0}, {0, 1 - topY}};
   tmpVertices[3] = (SenceVertex){{1, -2 * newTopY + 1, 0}, {1, 1 - topY}};
   tmpVertices[4] = (SenceVertex){{-1, -2 * newBottomY + 1, 0}, {0, 1 - bottomY}};
   tmpVertices[5] = (SenceVertex){{1, -2 * newBottomY + 1, 0}, {1, 1 - bottomY}};
   tmpVertices[6] = (SenceVertex){{-1, -1, 0}, {0, 0}};
   tmpVertices[7] = (SenceVertex){{1, -1, 0}, {1, 0}};
   
   
   ///下面开始渲染到纹理的流程（将结果渲染成一张新的纹理图片）
   
   //1. 生成帧缓存区;
   GLuint frameBuffer;
   GLuint texture;
   //glGenFramebuffers 生成帧缓存区对象名称;
   glGenFramebuffers(1, &frameBuffer);
   //glBindFramebuffer 绑定一个帧缓存区对象;
   glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
   
   //2. 生成纹理ID,绑定纹理;
   //glGenTextures 生成纹理ID
   glGenTextures(1, &texture);
   //glBindTexture 将一个纹理绑定到纹理目标上;
   glBindTexture(GL_TEXTURE_2D, texture);
   //glTexImage2D 指定一个二维纹理图像;
   glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, newTextureWidth, newTextureHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
   
   //3. 设置纹理相关参数
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
   
   //4. 将纹理图像加载到帧缓存区对象上;
//    帧缓存区 可以附着 渲染缓存区，还可以加载纹理对象
   /*
    glFramebufferTexture2D (GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level)
    target: 指定帧缓冲目标,符合常量必须是GL_FRAMEBUFFER;
    attachment: 指定附着纹理对象的附着点GL_COLOR_ATTACHMENT0
    textarget: 指定纹理目标, 符合常量:GL_TEXTURE_2D
    teture: 指定要附加图像的纹理对象;
    level: 指定要附加的纹理图像的mipmap级别，该级别必须为0。
    */
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
   
   //5. 设置视口尺寸
   glViewport(0, 0, newTextureWidth, newTextureHeight);
   
   //6. 获取着色器程序
   GLuint program = [LongLegHelper programWithShaderName:@"spring"];
   glUseProgram(program);
   
   //7. 获取传递数据的入口
   GLuint positionSlot = glGetAttribLocation(program, "Position");
   GLuint textureSlot = glGetUniformLocation(program, "Texture");
   GLuint textureCoordsSlot = glGetAttribLocation(program, "TextureCoords");
   
   //8. 传值，即传递纹理ID
   glActiveTexture(GL_TEXTURE0);
   glBindTexture(GL_TEXTURE_2D, self.baseEffect.texture2d0.name);
   glUniform1i(textureSlot, 0);
   
   //9.初始化缓存区，即创建VBO
   LongLegVertexAttribArrayBuffer *vbo = [[LongLegVertexAttribArrayBuffer alloc] initWithAttribStride:sizeof(SenceVertex) numberOfVertices:kVerticesCount data:tmpVertices usage:GL_STATIC_DRAW];
   
   //10.准备绘制,将纹理/顶点坐标传递进去;
//    顶点 & 纹理坐标 -- 准备绘制
   [vbo prepareToDrawWithAttrib:positionSlot numberOfCoordinates:3 attribOffset:offsetof(SenceVertex, positionCoord) shouldEnable:YES];
   [vbo prepareToDrawWithAttrib:textureCoordsSlot numberOfCoordinates:2 attribOffset:offsetof(SenceVertex, textureCoord) shouldEnable:YES];
   
   //11. 绘制
   [vbo drawArrayWithMode:GL_TRIANGLE_STRIP startVertexIndex:0 numberOfVertices:kVerticesCount];
   
   //12.解绑缓存
   glBindFramebuffer(GL_FRAMEBUFFER, 0);
   //13.释放顶点数组
   free(tmpVertices);
   
   //14.保存临时的纹理对象/帧缓存区对象;
   self.tmpTexture = texture;
   self.tmpFrameBuffer = frameBuffer;
}

// 返回某个纹理对应的 UIImage，调用前先绑定对应的帧缓存
- (UIImage *)imageFromTextureWithWidth:(int)width height:(int)height {
    
//    1、绑定帧缓存区
    glBindFramebuffer(GL_FRAMEBUFFER, self.tmpFrameBuffer);
    
//    2、将帧缓存区内的图片纹理绘制到图片上
    //计算图片的字节数
    int size = width * height * 4;
    GLubyte *buffer = malloc(size);
    /*
    
    glReadPixels (GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type, GLvoid* pixels);
    @功能: 读取像素(理解为将已经绘制好的像素,从显存中读取到内存中;)
    @参数解读:
    参数x,y,width,height: xy坐标以及读取的宽高;
    参数format: 颜色格式; GL_RGBA;
    参数type: 读取到的内容保存到内存所用的格式;GL_UNSIGNED_BYTE 会把数据保存为GLubyte类型;
    参数pixels: 指针,像素数据读取后, 将会保存到该指针指向的地址内存中;
    
    注意: pixels指针,必须保证该地址有足够的可以使用的空间, 以容纳读取的像素数据; 例如一副256 * 256的图像,如果读取RGBA 数据, 且每个数据保存在GLUbyte. 总大小就是 256 * 256 * 4 = 262144字节, 即256M;
    int size = width * height * 4;
    GLubyte *buffer = malloc(size);
    */
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
    
    //使用data和size 数组来访问buffer数据;
    /*
     CGDataProviderRef CGDataProviderCreateWithData(void *info, const void *data, size_t size, CGDataProviderReleaseDataCallback releaseData);
     @功能: 新的数据类型, 方便访问二进制数据;
     @参数:
     参数info: 指向任何类型数据的指针, 或者为Null;
     参数data: 数据存储的地址,buffer
     参数size: buffer的数据大小;
     参数releaseData: 释放的回调,默认为空;
     
     */
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, size, NULL);
    //每个组件的位数;
    int bitsPerComponent = 8;
    //像素占用的比特数4 * 8 = 32;
    int bitsPerPixel = 32;
    //每一行的字节数
    int bytesPerRow = 4 * width;
    //颜色空间格式;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    //位图图形的组件信息 - 默认的
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    //颜色映射
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;

    
//    3、将帧缓存区里的像素点绘制到一张图片上：读取的数据 -- 图片
    /*
    CGImageCreate(size_t width, size_t height,size_t bitsPerComponent, size_t bitsPerPixel, size_t bytesPerRow,CGColorSpaceRef space, CGBitmapInfo bitmapInfo, CGDataProviderRef provider,const CGFloat decode[], bool shouldInterpolate,CGColorRenderingIntent intent);
    @功能:根据你提供的数据创建一张位图;
    注意:size_t 定义的是一个可移植的单位,在64位机器上为8字节,在32位机器上是4字节;
    参数width: 图片的宽度像素;
    参数height: 图片的高度像素;
    参数bitsPerComponent: 每个颜色组件所占用的位数, 比如R占用8位;
    参数bitsPerPixel: 每个颜色的比特数, 如果是RGBA则是32位, 4 * 8 = 32位;
    参数bytesPerRow :每一行占用的字节数;
    参数space:颜色空间模式,CGColorSpaceCreateDeviceRGB
    参数bitmapInfo:kCGBitmapByteOrderDefault 位图像素布局;
    参数provider: 图片数据源提供者, 在CGDataProviderCreateWithData ,将buffer 转为 provider 对象;
    参数decode: 解码渲染数组, 默认NULL
    参数shouldInterpolate: 是否抗锯齿;
    参数intent: 图片相关参数;kCGRenderingIntentDefault
    
    */
    CGImageRef imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    
//    4、此时的 imageRef 是上下颠倒的，调用 CG 的方法重新绘制一遍，刚好翻转过来
    //创建一个图片context
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    CGContextRef context = UIGraphicsGetCurrentContext();
    //将图片绘制上去
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    //从context中获取图片
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    //结束图片context处理
    UIGraphicsEndImageContext();
    
    //释放buffer
    free(buffer);
    //返回图片
    return image;
}

#pragma mark - Custom Accessor
- (void)setTmpFrameBuffer:(GLuint)tmpFrameBuffer {
    if (_tmpFrameBuffer) {
        glDeleteFramebuffers(1, &_tmpFrameBuffer);
    }
    _tmpFrameBuffer = tmpFrameBuffer;
}

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    //1.准备绘制GLBaseEffect
    [self.baseEffect prepareToDraw];
    
    //2.清空缓存区;
    glClear(GL_COLOR_BUFFER_BIT);
    
    //3. 准备绘制数据-顶点数据
    [self.vertexAttribArrayBuffer prepareToDrawWithAttrib:GLKVertexAttribPosition
                                      numberOfCoordinates:3
                                             attribOffset:offsetof(SenceVertex, positionCoord)
                                             shouldEnable:YES];
    //4. 准备绘制数据-纹理坐标数据
    [self.vertexAttribArrayBuffer prepareToDrawWithAttrib:GLKVertexAttribTexCoord0
                                      numberOfCoordinates:2
                                             attribOffset:offsetof(SenceVertex, textureCoord)
                                             shouldEnable:YES];
    //5. 开始绘制;
    [self.vertexAttribArrayBuffer drawArrayWithMode:GL_TRIANGLE_STRIP
                                   startVertexIndex:0
                                   numberOfVertices:kVerticesCount];
}


#pragma mark-set/get方法
// 纹理顶部的纵坐标 0～1
- (CGFloat)textureTopY {
    //(1-vertices[0].顶点坐标的Y值)/2
    CGFloat textureTopYValue = (1 - self.vertices[0].positionCoord.y) / 2;
    return textureTopYValue;
}

// 纹理底部的纵坐标 0～1
- (CGFloat)textureBottomY {
    //(1-vertices[7].顶点坐标的Y值)/2
    CGFloat textureBottomYValue = (1 - self.vertices[7].positionCoord.y) / 2;
    return textureBottomYValue;
}

// 可伸缩区域顶部的纵坐标 0～1
- (CGFloat)stretchAreaTopY {
    CGFloat stretchAreaTopYValue = (1 - self.vertices[2].positionCoord.y) / 2;
    return stretchAreaTopYValue;
}
// 可伸缩区域底部的纵坐标 0～1
- (CGFloat)stretchAreaBottomY {
    CGFloat stretchAreaBottomYValue = (1 - self.vertices[5].positionCoord.y) / 2;
    return stretchAreaBottomYValue;
}
// 纹理高度 0～1
- (CGFloat)textureHeight {
    CGFloat textureHeightValue = self.textureBottomY - self.textureTopY;
    return textureHeightValue;
}
// 根据当前屏幕的尺寸，返回新的图片尺寸
- (CGSize)newImageSize {
    //新图片的尺寸 = 当前图片的高 * (当前图片高度 - (当前纹理EndY - 当前纹理Star))+1;
    CGFloat newImageHeight = self.currentImageSize.height * ((self.currentNewHeight - (self.currentTextureEndY - self.currentTextureStartY)) + 1);
    
    return CGSizeMake(self.currentImageSize.width, newImageHeight);
}
@end
