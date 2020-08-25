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

@implementation CJLRenderer
{
//    渲染设备（GPU）
    id<MTLDevice> _device;
    
//    渲染管道：顶点着色器/片元着色器,存储于.metal shader文件中
    id<MTLRenderPipelineState> _pipelineState;
    
//    命令队列：从命令缓存区中获取
    id<MTLCommandQueue> _commandQueue;
    
//    ！！！顶点缓存区（大批量顶点数据的图形渲染时使用）
    id<MTLBuffer> _vertexBuffer;
    
//    当前视图大小,这样我们才可以在渲染通道使用这个视图
    vector_uint2 _viewportSize;
    
//    顶点个数
    NSInteger _numVertices;
}

//初始化
- (id)initWithMetalKitView: (MTKView *)mtkView{
    self = [super init];
    if (self) {
        NSLog(@"initWithMetalKitView");
        NSError *error = NULL;
        
//        都是准备工作
//        1、初始化GPU设备
        _device = mtkView.device;
//        2、加载metal文件
        [self loadMetal:mtkView];
        
    }
    return self;
}

- (void)loadMetal: (nonnull MTKView*)mtkView{
    
//    1、设置绘制纹理的像素格式
    mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
    
//    2、加载.metal文件 & 加载顶点和片元函数
    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
    id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
    id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];
    
//    3、创建渲染管道 / 配置用于创建管道状态的管道：命名 & 设置顶点和片元function & 设置颜色数据的组件格式 即颜色附着点
    MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDescriptor.vertexFunction = vertexFunction;
    pipelineDescriptor.fragmentFunction = fragmentFunction;
    pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
    
//    4、创建渲染管线对象/同步创建并返回渲染管线对象 & 判断是否创建成功
    NSError *error = NULL;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    if (!_pipelineState) {
        NSLog(@"Failed to created pipeline state, error %@", error);
    }
    
//    5、获取顶点数据
    NSData *vertexData = [CJLRenderer generateVertexData];
//    创建一个vertex buffer,可以由GPU来读取
    _vertexBuffer = [_device newBufferWithLength:vertexData.length options:MTLResourceStorageModeShared];
//    复制vertex data 到vertex buffer 通过缓存区的"content"内容属性访问指针
        /*
         memcpy(void *dst, const void *src, size_t n);
         dst:目的地 -- 读取到那里
         src:源内容 -- 源数据在哪里
         n: 长度 -- 读取长度
         */
    memcpy(_vertexBuffer.contents, vertexData.bytes, vertexData.length);
//    计算顶点个数 = 顶点数据长度 / 单个顶点大小
    _numVertices = vertexData.length / sizeof(CJLVertex);
    
//    6、通过device创建commandQueue，即命令队列
    _commandQueue = [_device newCommandQueue];
}

//顶点数据 -- 制造出非常多的顶点数据
+ (nonnull NSData*)generateVertexData{
//    1、正方形 = 三角形+三角形
    const CJLVertex quadVertices[] =
    {
//        顶点坐标位于物体坐标系，需要在顶点着色函数中作归一化处理，即物体坐标系 -- NDC
        // Pixel 位置, RGBA 颜色
        { { -20,   20 },    { 1, 0, 0, 1 } },
        { {  20,   20 },    { 1, 0, 0, 1 } },
        { { -20,  -20 },    { 1, 0, 0, 1 } },
        
        { {  20,  -20 },    { 0, 0, 1, 1 } },
        { { -20,  -20 },    { 0, 0, 1, 1 } },
        { {  20,   20 },    { 0, 0, 1, 1 } },
    };
    
    //行/列 数量
    const NSUInteger NUM_COLUMNS = 25;
    const NSUInteger NUM_ROWS = 15;
    //顶点个数
    const NSUInteger NUM_VERTICES_PER_QUAD = sizeof(quadVertices) / sizeof(CJLVertex);
    //四边形间距
    const float QUAD_SPACING = 50.0;
    //数据大小 = 单个四边形大小 * 行 * 列
    NSInteger dataStr = sizeof(quadVertices) * NUM_COLUMNS * NUM_ROWS;
    
//    2、开辟空间
    NSMutableData *vertexData = [[NSMutableData alloc] initWithLength:dataStr];
    //当前四边形
    CJLVertex *currentQuad = vertexData.mutableBytes;
    
//    3、获取顶点坐标（循环计算）??? 需要研究
    //行
    for (NSUInteger row = 0; row < NUM_ROWS; row++) {
        //列
        for (NSUInteger column = 0; column < NUM_COLUMNS; column++) {
            //A.左上角的位置
            vector_float2 upperLeftPosition;
            //B.计算X,Y 位置.注意坐标系基于2D笛卡尔坐标系,中心点(0,0),所以会出现负数位置
            upperLeftPosition.x = ((-((float)NUM_COLUMNS) / 2.0) + column) * QUAD_SPACING + QUAD_SPACING/2.0;
            
            upperLeftPosition.y = ((-((float)NUM_ROWS) / 2.0) + row) * QUAD_SPACING + QUAD_SPACING/2.0;
            //C.将quadVertices数据复制到currentQuad
            memcpy(currentQuad, &quadVertices, sizeof(quadVertices));
            //D.遍历currentQuad中的数据
            for (NSUInteger vertexInQuad = 0; vertexInQuad < NUM_VERTICES_PER_QUAD; vertexInQuad++) {
                //修改vertexInQuad中的position
                currentQuad[vertexInQuad].position += upperLeftPosition;
            }
            //E.更新索引
            currentQuad += 6;
        }
    }
    return vertexData;
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
    
//    1、为当前渲染的每个渲染传递创建一个新的命令缓冲区 & 指定缓存区名称
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";
    
//    2、通过view创建渲染描述
//     MTLRenderPassDescriptor:一组渲染目标，用作渲染通道生成的像素的输出目标。
    //currentRenderPassDescriptor 从currentDrawable's texture,view's depth, stencil, and sample buffers and clear values.
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    //判断渲染目标是否为空
    if (renderPassDescriptor != nil) {
//        3、创建渲染命令编码器,这样我们才可以渲染到something & 设置渲染器名称
        id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        commandEncoder.label = @"MyRenderEncoder";
        
//        4、设置视口/设置我们绘制的可绘制区域
        [commandEncoder setViewport: (MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0}];
        
//        5、设置渲染管道状态
        [commandEncoder setRenderPipelineState:_pipelineState];
        
//        6、传递数据
        //我们调用-[MTLRenderCommandEncoder setVertexBuffer:offset:atIndex:] 为了从我们的OC代码找发送数据预加载的MTLBuffer 到我们的Metal 顶点着色函数中
        /* 这个调用有3个参数
            1) buffer - 包含需要传递数据的缓冲对象
            2) offset - 它们从缓冲器的开头字节偏移，指示“顶点指针”指向什么。在这种情况下，我们通过0，所以数据一开始就被传递下来.偏移量
            3) index - 一个整数索引，对应于我们的“vertexShader”函数中的缓冲区属性限定符的索引。注意，此参数与 -[MTLRenderCommandEncoder setVertexBytes:length:atIndex:] “索引”参数相同。
         */
        
        //将_vertexBuffer 设置到顶点缓存区中，顶点数据很多时，存储到buffer
        [commandEncoder setVertexBuffer:_vertexBuffer offset:0 atIndex:CJLVertexInputIndexVertices];
        
        //可以buffer 和 bytes传递混合使用
        //将 _viewportSize 设置到顶点缓存区绑定点设置数据
        [commandEncoder setVertexBytes:&_viewportSize length:sizeof(_viewportSize) atIndex:CJLVertexInputIndexViewportSize];
        
//        7、绘制
        // @method drawPrimitives:vertexStart:vertexCount:
        //@brief 在不使用索引列表的情况下,绘制图元
        //@param 绘制图形组装的基元类型
        //@param 从哪个位置数据开始绘制,一般为0
        //@param 每个图元的顶点个数,绘制的图型顶点数量
        /*
         MTLPrimitiveTypePoint = 0, 点
         MTLPrimitiveTypeLine = 1, 线段
         MTLPrimitiveTypeLineStrip = 2, 线环
         MTLPrimitiveTypeTriangle = 3,  三角形
         MTLPrimitiveTypeTriangleStrip = 4, 三角型扇
         */
        [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_numVertices];
        
//        8、表示已该编码器生成的命令都已完成,并且从NTLCommandBuffer中分离
        [commandEncoder endEncoding];
        
//        9、一旦框架缓冲区完成，使用当前可绘制的进度表
        [commandBuffer presentDrawable:view.currentDrawable];
        
    }
    
//    10、最后,在这里完成渲染并将命令缓冲区推送到GPU
    [commandBuffer commit];
}

@end
