//
//  CJLShaderTypes.h
//  01_Metal_Hello
//
//  Created by - on 2020/8/20.
//  Copyright © 2020 CJL. All rights reserved.
//

//C 与OC 之间产生桥接关系

/*
 介绍:
 头文件包含了 Metal shaders 与C/OBJC 源之间共享的类型和枚举常数
*/

#ifndef CJLShaderTypes_h
#define CJLShaderTypes_h

// 缓存区索引值 共享与 shader 和 C 代码 为了确保Metal Shader缓存区索引能够匹配 Metal API Buffer 设置的集合调用
typedef enum CJLVertexInputIndex
{
//    顶点
    CJLVertexInputIndexVertices = 0,
    
//    视图大小
    CJLVertexInputIndexViewportSize = 1,
    
}CJLVertexInputIndex;


//结构体:顶点/颜色值
typedef struct
{
//    像素空间的位置
//    像素中心点（100，100）
    vector_float4 position;
    
//    RGBA颜色
    vector_float4 color;
}CJLVertex;

#endif /* CJLShaderTypes_h */
