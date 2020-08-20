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
//    metal设备，即执行命令的GPU
    id<MTLDevice> _device;
    
//    渲染管道有顶点着色器和片元着色器，它们存储在.metal shader 文件中
    id<MTLRenderPipelineState> _pipelineState;
    
//    命令队列：将编译好的队列输入进去，驱动GPU干活
    id<MTLCommandQueue> _commandQueue;
    
//    //当前视图大小,这样我们才可以在渲染通道使用这个视图
    vector_uint2 _viewportSize;
}

//初始化
- (id)initWithMetalKitView: (MTKView *)mtkView{
    self = [super init];
    if (self) {
        
        NSError *error = NULL;
        
//        都是准备工作
        
        //1、获取GPU设备
        _device = mtkView.device;
        
        //2.在项目中加载所有的(.metal)着色器文件
        // 从bundle中获取.metal文件
        id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
        //从库中加载顶点函数
        id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
        //从库中加载片元函数
        id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];
        
        //3.配置用于创建管道状态的管道，即渲染管道
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        //管道名称
        pipelineStateDescriptor.label = @"Simple Pipeline";
        //可编程函数,用于处理渲染过程中的各个顶点
        pipelineStateDescriptor.vertexFunction = vertexFunction;
        //可编程函数,用于处理渲染过程中各个片段/片元
        pipelineStateDescriptor.fragmentFunction = fragmentFunction;
        //一组存储颜色数据的组件
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
        
        //4.同步创建并返回渲染管线状态对象
        _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        //判断是否返回了管线状态对象
        if (!_pipelineState) {
            //如果我们没有正确设置管道描述符，则管道状态创建可能失败
            NSLog(@"Failed to created pipeline state, error %@", error);
            return nil;
        }
        
        //5.创建命令队列
        //所有应用程序需要与GPU交互的第一个对象是一个对象。MTLCommandQueue.
        //你使用MTLCommandQueue 去创建对象,并且加入MTLCommandBuffer 对象中.确保它们能够按照正确顺序发送到GPU.对于每一帧,一个新的MTLCommandBuffer 对象创建并且填满了由GPU执行的命令.
        _commandQueue = [_device newCommandQueue];
    }
    return self;
}


#pragma -- MTKViewDelegate
//当MTKView视图发生大小改变时调用
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size{
    
    // 保存可绘制的大小，因为当我们绘制时，我们将把这些值传递给顶点着色器
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
    
}

//每当视图需要渲染时调用
- (void)drawInMTKView:(MTKView *)view{
    
//    1. 顶点数据、颜色数据
    static const CJLVertex triangleVertices[] =
    {
        //顶点， RGBA颜色值
        { {  0.5, -0.25, 0.0, 1.0 }, { 1, 0, 0, 1 } },
        { { -0.5, -0.25, 0.0, 1.0 }, { 0, 1, 0, 1 } },
        { { -0.0f, 0.25, 0.0, 1.0 }, { 0, 0, 1, 1 } },
    };
    
//    2.为当前渲染的每个渲染传递创建一个新的命令缓冲区
//    创建渲染缓存区，目的是为了将渲染对象加入到渲染缓存区。Create a new command buffer for each render pass to the current drawable
//使用MTLCommandQueue 创建对象并且加入到MTCommandBuffer对象中去.
//为当前渲染的每个渲染传递创建一个新的命令缓冲区
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    //设置渲染缓存区的命名
    commandBuffer.label = @"MyCommand";
    
//    3、从视图绘制中,获得渲染描述符（MTLRenderPassDescriptor）
    // MTLRenderPassDescriptor:一组渲染目标，用作渲染通道生成的像素的输出目标。
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    
//    判断renderPassDescriptor 渲染描述符是否创建成功,否则则跳过任何渲染.
    if (renderPassDescriptor != nil) {
//        4、创建渲染命令编码器,这样我们才可以渲染到something，相当于OpenGL ES中的program
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        //渲染器名称
        renderEncoder.label = @"MyRenderEncoder";
        
        //5、设置可绘制区域
        /*
        typedef struct {
            double originX, originY, width, height, znear, zfar;
        } MTLViewport;
         */
        //视口指定Metal渲染内容的drawable区域。 视口是具有x和y偏移，宽度和高度以及近和远平面的3D区域
        //为管道分配自定义视口需要通过调用setViewport：方法将MTLViewport结构编码为渲染命令编码器。 如果未指定视口，Metal会设置一个默认视口，其大小与用于创建渲染命令编码器的drawable相同。
        MTLViewport viewPort = {
            0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0
        };
        //设置视口 相当于OpenGL ES中的glViewPort
        [renderEncoder setViewport:viewPort];
        
        //6.设置当前渲染管道状态对象
        [renderEncoder setRenderPipelineState:_pipelineState];
        
        //7.从应用程序OC 代码 中发送数据给Metal 顶点着色器/片元着色器 函数，相当于OpenGL ES中的glVertexAttribPointer
        //顶点数据+颜色数据
        //   1) 指向要传递给着色器的内存的指针
        //   2) 我们想要传递的数据的内存大小
        //   3)一个整数索引，它对应于我们的“vertexShader”函数中的缓冲区属性限定符的索引。
//        CJLVertexInputIndexVertices 是顶点数据的入口，需要由自己定义，相当于OpenGL ES中glGetAttribLocation
        [renderEncoder setVertexBytes:triangleVertices
                               length:sizeof(triangleVertices)
                              atIndex:CJLVertexInputIndexVertices];
        
        //viewPortSize 数据
        //1) 发送到顶点着色函数中,视图大小
        //2) 视图大小内存空间大小
        //3) 对应的索引
        [renderEncoder setVertexBytes:&_viewportSize
                               length:sizeof(_viewportSize)
                              atIndex:CJLVertexInputIndexViewportSize];
        
        //8.画出三角形的3个顶点
        // @method drawPrimitives:vertexStart:vertexCount:
        //@brief 在不使用索引列表的情况下,绘制图元
        //@param 绘制图形组装的基元类型
        //@param 从哪个位置数据开始绘制,一般为0
        //@param 每个图元的顶点个数,绘制的图型顶点数量
        /*
         metal只有5种图片方式，OpenGL ES有9种
         
         MTLPrimitiveTypePoint = 0, 点
         MTLPrimitiveTypeLine = 1, 线段
         MTLPrimitiveTypeLineStrip = 2, 线环
         MTLPrimitiveTypeTriangle = 3,  三角形
         MTLPrimitiveTypeTriangleStrip = 4, 三角型扇
         */
//        相当于OpenGL ES中的glDrawArrays，绘制
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:3];
        
//        9.表示已该编码器生成的命令都已完成,并且从NTLCommandBuffer中分离，即绘制已经完成
        [renderEncoder endEncoding];
        
        /*
        当编码器结束之后,命令缓存区就会接受到2个命令.
         1) present
         2) commit
         因为GPU是不会直接绘制到屏幕上,因此你不给出去指令.是不会有任何内容渲染到屏幕上.
        */
        //10.一旦框架缓冲区完成，使用当前可绘制的进度表，即提交渲染命令
        [commandBuffer presentDrawable:view.currentDrawable];
        
    }
    
//    11.最后,在这里完成渲染并将命令缓冲区推送到GPU，相当于OpenGL ES中的draw
    [commandBuffer commit];
}

@end
