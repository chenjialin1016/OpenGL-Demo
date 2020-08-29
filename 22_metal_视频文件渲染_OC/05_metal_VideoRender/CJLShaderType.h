//
//  CJLShaderType.h
//  05_metal_VideoRender
//
//  Created by - on 2020/8/29.
//  Copyright © 2020 CJL. All rights reserved.
//

#ifndef CJLShaderType_h
#define CJLShaderType_h

#include <simd/simd.h>

//顶点数据结构
typedef struct {
    //顶点坐标(x,y,z,w)
    vector_float4 position;
    //纹理坐标(s,t)
    vector_float2 textureCoordinate;
}CJLVertex;

//转换矩阵：YUV-->RGB
typedef struct {
    //三维矩阵:转换矩阵
    matrix_float3x3 matrix;
    //偏移量
    vector_float3 offset;
}CJLConvertMatrix;

//顶点函数输入索引：viewController传入metal 的索引
//
typedef enum CJLVertexInputIndex
{
    CJLVertexInputIndexVertices = 0,
}CJLVertexInputIndex;

//片元函数缓存区索引
typedef enum CJLFragmentBufferIndex
{
    CJLFragmentInputIndexMatrix = 0,
}CJLFragmentBufferIndex;

//片元函数纹理索引
typedef enum CJLFragmentTextureIndex
{
    //Y纹理
    CJLFragmentTextureIndexTextureY = 0,
    //UV纹理
    CJLFragmentTextureIndexTextureUV = 1,
}CJLFragmentTextureIndex;

#endif /* CJLShaderType_h */
