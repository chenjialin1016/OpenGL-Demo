//
//  ViewController.m
//  05_metal_VideoRender
//
//  Created by - on 2020/8/26.
//  Copyright © 2020 CJL. All rights reserved.
//

#import "ViewController.h"
#import "CJLShaderType.h"
#import "CJLAssetReader.h"

@import MetalKit;
@import GLKit;

@interface ViewController ()<MTKViewDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

//MTKView
@property (nonatomic, strong) MTKView *mtkView;

//CCAssetReader 读取MOV/mp4文件中视频数据
@property (nonatomic, strong) CJLAssetReader *reader;

//高速纹理读取缓存区.
@property (nonatomic, assign) CVMetalTextureCacheRef textureCache;

//viewportSize 视口大小
@property (nonatomic, assign) vector_uint2 viewPortSize;

//渲染管道
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;

//命令队列
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;

//纹理
@property (nonatomic, strong) id<MTLTexture> texture;

//顶点缓存区
@property (nonatomic, strong) id<MTLBuffer> vertices;

//YUV->RGB转换矩阵
@property (nonatomic, strong) id<MTLBuffer> convertMatrix;

//顶点个数
@property (nonatomic, assign) NSUInteger numVertices;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"viewDidLoad");
    
//    以下都是绘制前的准备工作
    
    //1.MTKView 设置
    [self setupMTKView];

    //2.CJLAssetReader设置
    [self setupCJLAsset];

    //3.渲染管道设置
    [self setupPipeline];

    //4.顶点数据设置
    [self setupVertex];

    //5.转换矩阵设置
    [self setupMatrix];
    
}

#pragma mark -- setup init

//1.MTKView 设置
- (void)setupMTKView
{
    //1.初始化mtkView
    self.mtkView = [[MTKView alloc] initWithFrame:self.view.bounds device:MTLCreateSystemDefaultDevice()];
    
    //设置self.view = self.mtkView;
    self.view = self.mtkView;
    
    //设置代理
    self.mtkView.delegate = self;
    
    //2、获取视口size
    self.viewPortSize = (vector_uint2){self.mtkView.drawableSize.width, self.mtkView.drawableSize.height};
    
}

//2.CCAssetReader设置
- (void)setupCJLAsset
{
    //注意CCAssetReader 支持MOV/MP4文件都可以
    //1.视频文件路径
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"sinan" withExtension:@"mp4"];
    
    //2.初始化CCAssetReader
    self.reader = [[CJLAssetReader alloc] initWithUrl:url];
    
    //3._textureCache的创建(通过CoreVideo提供给CPU/GPU高速缓存通道读取纹理数据)
    CVMetalTextureCacheCreate(NULL, NULL, self.mtkView.device, NULL, &_textureCache);
}

//3.渲染管道设置
- (void)setupPipeline
{
    //1 获取.metal
    /*
     newDefaultLibrary: 默认一个metal 文件时,推荐使用
     newLibraryWithFile:error: 从Library 指定读取metal 文件
     newLibraryWithData:error: 从Data 中获取metal 文件
     */
    id<MTLLibrary> defaultLibrary = [self.mtkView.device newDefaultLibrary];
    // 顶点shader，vertexShader是函数名
    id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
    // 片元shader，samplingShader是函数名
    id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"samplingShader"];
    
    //2.渲染管道描述信息类 - 渲染管道描述符
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    //设置vertexFunction
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    //设置fragmentFunction
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    // 设置颜色格式
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.mtkView.colorPixelFormat;
    
    //3.初始化渲染管道根据渲染管道描述信息
    // 创建图形渲染管道，耗性能操作不宜频繁调用
    self.pipelineState = [self.mtkView.device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:NULL];
    
    //4.CommandQueue是渲染指令队列，保证渲染指令有序地提交到GPU
    self.commandQueue = [self.mtkView.device newCommandQueue];
}

//4.顶点数据设置
- (void)setupVertex
{
    //1.顶点坐标(x,y,z,w);纹理坐标(x,y)
       //注意: 为了让视频全屏铺满,所以顶点大小均设置[-1,1]
    static const CJLVertex quadVertices[] =
    {   // 顶点坐标，分别是x、y、z、w；    纹理坐标，x、y；
        { {  1.0, -1.0, 0.0, 1.0 },  { 1.f, 1.f } },
        { { -1.0, -1.0, 0.0, 1.0 },  { 0.f, 1.f } },
        { { -1.0,  1.0, 0.0, 1.0 },  { 0.f, 0.f } },
        
        { {  1.0, -1.0, 0.0, 1.0 },  { 1.f, 1.f } },
        { { -1.0,  1.0, 0.0, 1.0 },  { 0.f, 0.f } },
        { {  1.0,  1.0, 0.0, 1.0 },  { 1.f, 0.f } },
    };
    
    //2.创建顶点缓存区
    self.vertices = [self.mtkView.device newBufferWithBytes:quadVertices length:sizeof(quadVertices) options:MTLResourceStorageModeShared];
    
    //3.计算顶点个数
    self.numVertices = sizeof(quadVertices) / sizeof(CJLVertex);
}

// 设置YUV->RGB转换的矩阵
- (void)setupMatrix
{
    //1.转化矩阵
     // BT.601, which is the standard for SDTV.
     matrix_float3x3 kColorConversion601DefaultMatrix = (matrix_float3x3){
         (simd_float3){1.164,  1.164, 1.164},
         (simd_float3){0.0, -0.392, 2.017},
         (simd_float3){1.596, -0.813,   0.0},
     };
     
     // BT.601 full range
     matrix_float3x3 kColorConversion601FullRangeMatrix = (matrix_float3x3){
         (simd_float3){1.0,    1.0,    1.0},
         (simd_float3){0.0,    -0.343, 1.765},
         (simd_float3){1.4,    -0.711, 0.0},
     };
    
     // BT.709, which is the standard for HDTV.
     matrix_float3x3 kColorConversion709DefaultMatrix[] = {
         (simd_float3){1.164,  1.164, 1.164},
         (simd_float3){0.0, -0.213, 2.112},
         (simd_float3){1.793, -0.533,   0.0},
     };
    
    //2.偏移量
    vector_float3 kColorConversion601FullRangeOffset = (vector_float3){ -(16.0/255.0), -0.5, -0.5};
    
    //3.创建转化矩阵结构体.
    CJLConvertMatrix matrix;
    //设置转化矩阵
    /*
     kColorConversion601DefaultMatrix；
     kColorConversion601FullRangeMatrix；
     kColorConversion709DefaultMatrix；
     */
    matrix.matrix = kColorConversion601FullRangeMatrix;
    //设置offset偏移量
    matrix.offset = kColorConversion601FullRangeOffset;
    
    //4.创建转换矩阵缓存区.
    self.convertMatrix = [self.mtkView.device newBufferWithBytes:&matrix length:sizeof(CJLConvertMatrix) options:MTLResourceStorageModeShared];
}

// 设置纹理
- (void)setupTextureWithEncoder:(id<MTLRenderCommandEncoder>)encoder buffer:(CMSampleBufferRef)CMSampleBufferRef
{
    //1.从CMSampleBuffer读取CVPixelBuffer，
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(CMSampleBufferRef);
    
    id<MTLTexture> textureY = NULL;
    id<MTLTexture> textureUV = NULL;
    
    //textureY 设置
    {
        //2.获取纹理的宽高
        size_t width = CVPixelBufferGetWidth(pixelBuffer);
        size_t height = CVPixelBufferGetHeight(pixelBuffer);
        
        //3.像素格式:普通格式，包含一个8位规范化的无符号整数组件。
        MTLPixelFormat pixelFormat = MTLPixelFormatR8Unorm;
        
        //4.创建CoreVideo的Metal纹理
        CVMetalTextureRef texture = NULL;
        
        /*5. 根据视频像素缓存区 创建 Metal 纹理缓存区
        CVReturn CVMetalTextureCacheCreateTextureFromImage(CFAllocatorRef allocator,
        CVMetalTextureCacheRef textureCache,
        CVImageBufferRef sourceImage,
        CFDictionaryRef textureAttributes,
        MTLPixelFormat pixelFormat,
        size_t width,
        size_t height,
        size_t planeIndex,
        CVMetalTextureRef  *textureOut);
        
        功能: 从现有图像缓冲区创建核心视频Metal纹理缓冲区。
        参数1: allocator 内存分配器,默认kCFAllocatorDefault
        参数2: textureCache 纹理缓存区对象
        参数3: sourceImage 视频图像缓冲区
        参数4: textureAttributes 纹理参数字典.默认为NULL
        参数5: pixelFormat 图像缓存区数据的Metal 像素格式常量.注意如果MTLPixelFormatBGRA8Unorm和摄像头采集时设置的颜色格式不一致，则会出现图像异常的情况；
        参数6: width,纹理图像的宽度（像素）
        参数7: height,纹理图像的高度（像素）
        参数8: planeIndex.如果图像缓冲区是平面的，则为映射纹理数据的平面索引。对于非平面图像缓冲区忽略。
        参数9: textureOut,返回时，返回创建的Metal纹理缓冲区。
        */
        CVReturn status = CVMetalTextureCacheCreateTextureFromImage(NULL, self.textureCache, pixelBuffer, NULL, pixelFormat, width, height, 0, &texture);
        
        //6.判断textureCache 是否创建成功
        if (status == kCVReturnSuccess)
        {
            //7.转成Metal用的纹理
            textureY = CVMetalTextureGetTexture(texture);
            
            //8.使用完毕释放
            CFRelease(texture);
        }
    }
    
    //9.textureUV 设置(同理,参考于textureY 设置)
    {
        size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1);
        size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
        MTLPixelFormat pixelFormat = MTLPixelFormatRG8Unorm;
        CVMetalTextureRef texture = NULL;
        CVReturn status = CVMetalTextureCacheCreateTextureFromImage(NULL, self.textureCache, pixelBuffer, NULL, pixelFormat, width, height, 1, &texture);
        if(status == kCVReturnSuccess)
        {
            textureUV = CVMetalTextureGetTexture(texture);
            CFRelease(texture);
        }
    }
    
    //10.判断textureY 和 textureUV 是否读取成功
    if (textureY != nil && textureUV != nil)
    {
        //11.向片元函数设置textureY 纹理
        [encoder setFragmentTexture:textureY atIndex:CJLFragmentTextureIndexTextureY];
        
        //12.向片元函数设置textureUV 纹理
        [encoder setFragmentTexture:textureUV atIndex:CJLFragmentTextureIndexTextureUV];
    }
    
    //13.使用完毕,则将sampleBuffer 及时释放
    CFRelease(CMSampleBufferRef);
}


#pragma mark - MTKView Delegate

//视图大小发生改变时.会调用此方法
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size{
    self.viewPortSize = (vector_uint2){size.width, size.height};
}

//视图渲染则会调用此方法，相当于OpenGL中的RenderScene
- (void)drawInMTKView:(MTKView *)view{
    NSLog(@"drawInMTKView");
    
    //1.每次渲染都要单独创建一个CommandBuffer
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    //获取渲染描述信息
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    
    //2. 从CCAssetReader中读取图像数据
    CMSampleBufferRef sampleBuffer = [self.reader readBuffer];
    
    //3.判断renderPassDescriptor 和 sampleBuffer 是否已经获取到了?
    if (renderPassDescriptor && sampleBuffer)
    {
        //4.设置renderPassDescriptor中颜色附着(默认背景色)
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.5, 0.5, 1.0f);
        
        //5.根据渲染描述信息创建渲染命令编码器
        id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        
        //6.设置视口大小(显示区域)
        [commandEncoder setViewport:(MTLViewport){0.0, 0.0, self.viewPortSize.x, self.viewPortSize.y, -1.0, 1.0 }];
        
        //7.为渲染编码器设置渲染管道
        [commandEncoder setRenderPipelineState:self.pipelineState];
        
        //8.设置顶点缓存区
        [commandEncoder setVertexBuffer:self.vertices offset:0 atIndex:CJLVertexInputIndexVertices];
        
        //9.设置纹理(将sampleBuffer数据 设置到renderEncoder 中)
        [self setupTextureWithEncoder:commandEncoder buffer:sampleBuffer];
        
        //10.设置片元函数转化矩阵
        [commandEncoder setFragmentBuffer:self.convertMatrix offset:0 atIndex:CJLFragmentInputIndexMatrix];
        
        //11.开始绘制
        [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:self.numVertices];
        
        //12.结束编码
        [commandEncoder endEncoding];
        
        //13.显示
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    
    //14.提交命令
    [commandBuffer commit];
}


@end
