//
//  -Renderer.m
//  01_Metal_Hello
//
//  Created by - on 2020/8/19.
//  Copyright © 2020 -. All rights reserved.
//

//CJLRenderer是服务于MTKView的

#import "CJLRenderer.h"

//头 在C代码之间共享，这里执行Metal API命令，和.metal文件，这些文件使用这些类型作为着色器的输入。
#import "CJLShaderTypes.h"

#import "CJLImage.h"

@import simd;
@import MetalKit;

@implementation CJLRenderer
{
//    渲染设备（GPU）
    id<MTLDevice> _device;
    
//    渲染管道：顶点着色器/片元着色器,存储于.metal shader文件中
    id<MTLRenderPipelineState> _pipelineState;
    
//    命令队列：从命令缓存区中获取
    id<MTLCommandQueue> _commandQueue;
    
//   (！！！) Metal纹理对象
    id<MTLTexture> _texture;
    
//   存储在 Metal buffer 顶点数据
    id<MTLBuffer> _vertexBuffer;
    
//    当前视图大小,这样我们才可以在渲染通道使用这个视图
    vector_uint2 _viewportSize;
    
//    顶点个数
    NSInteger _numVertices;
    
//    MTKView
    MTKView *cjlMTKView;
}

//初始化
- (id)initWithMetalKitView: (MTKView *)mtkView{
    self = [super init];
    if (self) {
        NSLog(@"initWithMetalKitView");
        NSError *error = NULL;
        
//        都是准备工作
//        1、获取GPU设备 & 获取view
        _device = mtkView.device;
        cjlMTKView = mtkView;
        
//        2、设置顶点相关操作
        [self setupVertex];
        
//        3、设置渲染管道相关操作
        [self setupPipeLine];
        
//        4、加载纹理TGA文件
        [self setupTexture];
        
    }
    return self;
}

#pragma mark -- init setUp
//设置顶点相关操作
- (void) setupVertex{
    
//    1、根据顶点/纹理坐标建立一个MTLBuffer
    static const CJLVertex quadVertices[] = {
//       不是-1~1的都是物体坐标系
        //像素坐标,纹理坐标
        { {  250,  -250 },  { 1.f, 0.f } },
        { { -250,  -250 },  { 0.f, 0.f } },
        { { -250,   250 },  { 0.f, 1.f } },
        
        { {  250,  -250 },  { 1.f, 0.f } },
        { { -250,   250 },  { 0.f, 1.f } },
        { {  250,   250 },  { 1.f, 1.f } },
    };
    
//    2、创建我们的顶点缓冲区，并用我们的Qualsits数组初始化它
    _vertexBuffer = [_device newBufferWithBytes:quadVertices length:sizeof(quadVertices) options:MTLResourceStorageModeShared];
    
//    3、通过将字节长度除以每个顶点的大小来计算顶点的数目
    _numVertices = sizeof(quadVertices) / sizeof(CJLVertex);
    
}

//设置渲染管道相关操作
- (void)setupPipeLine{
    
//    1、创建渲染管道
    //从项目中加载.metal文件,创建一个library
    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
    //从库中加载顶点函数
    id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
     //从库中加载片元函数
    id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];
    
//    2、配置用于创建渲染管道状态的管道
    MTLRenderPipelineDescriptor *renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    //管道名称
    renderPipelineDescriptor.label = @"Texturing Pipeline";
    //可编程函数,用于处理渲染过程中的各个顶点
    renderPipelineDescriptor.vertexFunction = vertexFunction;
    //可编程函数,用于处理渲染过程总的各个片段/片元
    renderPipelineDescriptor.fragmentFunction = fragmentFunction;
    //设置管道中存储颜色数据的组件格式
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = cjlMTKView.colorPixelFormat;
    
//    3、创建并返回渲染管线对象 & 判断是否创建成功
    NSError *error;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor error:&error];
    if (!_pipelineState) {
       NSLog(@"Failed to created pipeline state, error %@", error);
    }
    
//    4、使用device创建commandQueue
    _commandQueue = [_device newCommandQueue];
}

//加载纹理TGA文件
- (void)setupTexture{
    
//    1、获取TGA文件路径 --- TGA文件解压
    NSURL *imageFileLocation = [[NSBundle mainBundle] URLForResource:@"circle" withExtension:@"tga"];
    //将tag文件->CJLImage对象
    CJLImage *image = [[CJLImage alloc] initWithTGAFileAtLocation:imageFileLocation];
    //判断图片是否转换成功
    if (!image) {
        NSLog(@"Failed to create the image from:%@",imageFileLocation.absoluteString);
        return;
    }
    
//    2、创建纹理描述对象 & 设置属性 --- CJLImage --> 纹理（即位图变成纹理对象）
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    //表示每个像素有蓝色,绿色,红色和alpha通道.其中每个通道都是8位无符号归一化的值.(即0映射成0,255映射成1);
    //位图信息
    textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
    //设置纹理的像素尺寸，即纹理的分辨率
    textureDescriptor.width = image.width;
    textureDescriptor.height = image.height;
    
//    3、创建纹理对象：使用描述符从设备中创建纹理
    _texture = [_device newTextureWithDescriptor:textureDescriptor];
    //计算图像每行的字节数
    NSUInteger bytesPerRow = 4 * image.width;
    
//    4、创建MTLRegion结构体
    /*
     typedef struct
     {
     MTLOrigin origin; //开始位置x,y,z
     MTLSize   size; //尺寸width,height,depth
     } MTLRegion;
     */
    //MLRegion结构用于标识纹理的特定区域。 demo使用图像数据填充整个纹理；因此，覆盖整个纹理的像素区域等于纹理的尺寸。
    MTLRegion region = {
        {0,0,0},
        {image.width, image.height, 1},
    };
    
//    5、复制图片数据到texture
    /*
     将图片复制到纹理0中（即用纹理替换region表示的区域）
     - (void)replaceRegion:(MTLRegion)region mipmapLevel:(NSUInteger)level withBytes:(const void *)pixelBytes bytesPerRow:(NSUInteger)bytesPerRow;
     参数1-region：像素区域在纹理中的位置
     参数2-level：从零开始的值，指定哪个mipmap级别是目标。如果纹理没有mipmap，请使用0。
     参数3-pixelBytes：指向要复制图片的字节数
     参数4-bytesPerRow：对于普通或压缩像素格式，源数据行之间的跨度（以字节为单位）。对于压缩像素格式，跨度是从一排块的开头到下一行的开始的字节数。
     */
   [_texture replaceRegion:region mipmapLevel:0 withBytes:image.data.bytes bytesPerRow:bytesPerRow];
    
}



#pragma -- MTKViewDelegate
//当MTKView视图发生大小改变时调用
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size{
    NSLog(@"drawableSizeWillChange");
    
    // 保存可绘制的大小，因为当我们绘制时，我们将把这些值传递给顶点着色器
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
    
}

//每当视图需要渲染时调用
- (void)drawInMTKView:(MTKView *)view{
    NSLog(@"drawInMTKView");

//    1、创建commandBuffer命令缓冲区
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    //指定缓存区名称
    commandBuffer.label = @"MyCommand";
    
//    2、创建渲染描述符
    //.currentRenderPassDescriptor描述符包含currentDrawable's的纹理、视图的深度、模板和sample缓冲区和清晰的值。
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    if (renderPassDescriptor != nil) {
//        3、创建渲染命令编码器,这样我们才可以渲染到something
        id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        //渲染器名称
        commandEncoder.label = @"MyRenderEncoder";
        
//        4、设置视口
        /*
        typedef struct {
        double originX, originY, width, height, znear, zfar;
        } MTLViewport;
        */
        [commandEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0}];
        
//        5、设置渲染管道状态
        [commandEncoder setRenderPipelineState:_pipelineState];
        
//        6、（！！！！）传递数据
        /*
         需要传递的数据有以下三种：
         1）顶点数据、纹理坐标，
         2）viewportSize视图大小
         3）纹理图片
         */
        //将数据加载到MTLBuffer （即metal文件中的顶点着色函数）--> 顶点函数
        [commandEncoder setVertexBuffer:_vertexBuffer offset:0 atIndex:CJLVertexInputIndexVertices];
        //将数据加载到GPU（即metal文件中的顶点着色函数） --> 视图大小
        [commandEncoder setVertexBytes:&_viewportSize length:sizeof(_viewportSize) atIndex:CJLVertexInputIndexViewportSize];
        
        //将纹理对象传递到片元着色器（即metal中的片元着色函数） -- 纹理图片
        [commandEncoder setFragmentTexture:_texture atIndex:CJLTextureIndexBaseColor];
        
//        7、绘制
        [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_numVertices];
        
//        8、结束commandEncoder工作
        [commandEncoder endEncoding];
        
//        9、渲染到屏幕上
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    
//    10、将coammandBuffer提交至GPU
    [commandBuffer commit];

}

@end
