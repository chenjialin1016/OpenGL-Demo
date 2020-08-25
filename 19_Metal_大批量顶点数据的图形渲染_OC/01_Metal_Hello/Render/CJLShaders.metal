//
//  CJLShaders.metal
//  01_Metal_Hello
//
//  Created by - on 2020/8/20.
//  Copyright © 2020 CJL. All rights reserved.
//

#include <metal_stdlib>
//使用命名空间 Metal
using namespace metal;

// 导入Metal shader 代码和执行Metal API命令的C代码之间共享的头
#import "CJLShaderTypes.h"

//返回值结构体：顶点着色器输出和片元着色器输入（相当于OpenGL ES中的varying修饰的变量，即桥接）
typedef struct
{
//    处理空间的顶点信息，相当于OpenGL ES中的gl_Position
//    float4 修饰符，是一个4维向量，[[position]]是内建修饰符，不可更改
    float4 clipSpacePosition [[position]];
    
//    颜色，相当于OpenGL ES中的gl_FragColor
    float4 color;
    
}RasterizerData;

//顶点着色器函数
/*
 vertex：修饰符，表示是顶点着色器
 RasterizerData：返回数据类型
 vertexShader：函数名，可自定义
 
 vertexID：表示当前处理的是第几号顶点，[[vertex_id]]也是内建修饰符，不可修改，也不可传递
 vertices：constant修饰，放在常量地址空间，是不可修改的，[[buffer(CJLVertexInputIndexVertices)]]是属性修饰符，存储在缓存
 vertices 和 viewportSizePointer 都是通过CJLRenderer 传递进来的
 */
vertex RasterizerData
vertexShader(uint vertexID [[vertex_id]],
             constant CJLVertex *vertices [[buffer(CJLVertexInputIndexVertices)]],
             constant vector_uint2 *viewportSizePointer [[buffer(CJLVertexInputIndexViewportSize)]])
{
        /*
        处理顶点数据:
           1) 执行坐标系转换,将生成的顶点剪辑空间写入到返回值中.
           2) 将顶点颜色值传递给返回值
        */
       
//    1、定义out
    RasterizerData out;
    
//    2、初始化输出剪辑空间位置，将w改为2.0，实际运行结果比1.0小一倍
    out.clipSpacePosition = vector_float4(0.0, 0.0, 0.0, 1.0);
    
//    3、获取当前顶点坐标的xy，因为是2D图形
    // 索引到我们的数组位置以获得当前顶点
    // 我们的位置是在像素维度中指定的.
    float2 pixelSpacePosition = vertices[vertexID].position.xy;
    
    //将vierportSizePointer 从verctor_uint2 转换为vector_float2 类型
    vector_float2 viewportSize = vector_float2(*viewportSizePointer);
    
//    4、顶点坐标归一化处理
    //每个顶点着色器的输出位置在剪辑空间中(也称为归一化设备坐标空间,NDC),剪辑空间中的(-1,-1)表示视口的左下角,而(1,1)表示视口的右上角.
    //计算和写入 XY值到我们的剪辑空间的位置.为了从像素空间中的位置转换到剪辑空间的位置,我们将像素坐标除以视口的大小的一半.
    //如果是1倍，除以1.0，如果是3倍
    //可以使用一行代码同时分割两个通道。执行除法，然后将结果放入输出位置的x和y通道中
    out.clipSpacePosition.xy = pixelSpacePosition / (viewportSize / 2.0);
    
//    5、颜色原样输出
    //把我们输入的颜色直接赋值给输出颜色. 这个值将于构成三角形的顶点的其他颜色值插值,从而为我们片段着色器中的每个片段生成颜色值.
    out.color = vertices[vertexID].color;
    
    
    //完成! 将结构体传递到管道中下一个阶段:
    return out;
    
}

//当顶点函数执行3次,三角形的每个顶点执行一次后,则执行管道中的下一个阶段.栅格化/光栅化.
/*
 metal自行完成的过程
 1）图元装配
 2）光栅化
 */

//片元着色器函数：描述片元函数
// 片元函数
//[[stage_in]],片元着色函数使用的单个片元输入数据是由顶点着色函数输出.然后经过光栅化生成的.单个片元输入函数数据可以使用"[[stage_in]]"属性修饰符.
//一个顶点着色函数可以读取单个顶点的输入数据,这些输入数据存储于参数传递的缓存中,使用顶点和实例ID在这些缓存中寻址.读取到单个顶点的数据.另外,单个顶点输入数据也可以通过使用"[[stage_in]]"属性修饰符的产生传递给顶点着色函数.
//被stage_in 修饰的结构体的成员不能是如下这些.Packed vectors 紧密填充类型向量,matrices 矩阵,structs 结构体,references or pointers to type 某类型的引用或指针. arrays,vectors,matrices 标量,向量,矩阵数组.

/*
 fragment：修饰符，表示是片元着色器
 float4：返回值类型，即颜色值RGBA
 fragmentShader：函数名称，可自定义
 
 RasterizerData：参数类型（可修改），顶点着色器传递出来的，包含了顶点位置+颜色，类似于GLSL中varying传递的数据
 in：形参变量（可修改）
 [[stage_in]]：属性修饰符，表示单个片元输入（由定点函数输出）(不可修改)，相当于OpenGL ES中的varying
 */
fragment float4 fragmentShader(RasterizerData in [[stage_in]])
{
//    相比于GLSL，只是API变了，原理是一样的
    //返回输入的片元颜色
    return in.color;
}
