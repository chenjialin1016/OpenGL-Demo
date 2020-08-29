//
//  CJLShaders.metal
//  05_metal_VideoRender
//
//  Created by - on 2020/8/29.
//  Copyright © 2020 CJL. All rights reserved.
//

#include <metal_stdlib>
#import "CJLShaderType.h"
using namespace metal;

//结构体(用于顶点函数输出/片元函数输入)
typedef struct
{
    float4 clipSpacePosition [[position]]; // position的修饰符表示这个是顶点
    
    float2 textureCoordinate; // 纹理坐标
    
} RasterizerData;

//RasterizerData 返回数据类型->片元函数
// vertex_id是顶点shader每次处理的index，用于定位当前的顶点
// buffer表明是缓存数据，0是索引
vertex RasterizerData
vertexShader(uint vertexID [[ vertex_id ]],
             constant CJLVertex *vertexArray [[ buffer(CJLVertexInputIndexVertices) ]])
{
    RasterizerData out;
    //顶点坐标
    out.clipSpacePosition = vertexArray[vertexID].position;
    //纹理坐标
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    return out;
}


//YUV->RGB 参考学习链接: https://mp.weixin.qq.com/s/KKfkS5QpwPAdYcEwFAN9VA
// stage_in表示这个数据来自光栅化。（光栅化是顶点处理之后的步骤，业务层无法修改）
// texture表明是纹理数据，CCFragmentTextureIndexTextureY是索引
// texture表明是纹理数据，CCFragmentTextureIndexTextureUV是索引
// buffer表明是缓存数据， CCFragmentInputIndexMatrix是索引
fragment float4
samplingShader(RasterizerData input [[stage_in]],
               texture2d<float> textureY [[ texture(CJLFragmentTextureIndexTextureY) ]],
               texture2d<float> textureUV [[ texture(CJLFragmentTextureIndexTextureUV) ]],
               constant CJLConvertMatrix *convertMatrix [[ buffer(CJLFragmentInputIndexMatrix) ]])
{
    //1.获取纹理采样器
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    /*
     2. 读取YUV 纹理对应的像素点值，即颜色值
        textureY.sample(textureSampler, input.textureCoordinate).r
        从textureY中的纹理采集器中读取,纹理坐标对应上的R值.(Y)
        textureUV.sample(textureSampler, input.textureCoordinate).rg
        从textureUV中的纹理采集器中读取,纹理坐标对应上的RG值.(UV)
     */
    //r 表示 第一个分量，相当于 index 0
    //rg 表示 数组中前面两个值，相当于 index 的0 和 1，用xy也可以
    float3 yuv = float3(textureY.sample(textureSampler, input.textureCoordinate).r,
                        textureUV.sample(textureSampler, input.textureCoordinate).rg);
    
    //3.将YUV 转化为 RGB值.convertMatrix->matrix * (YUV + convertMatrix->offset)
    float3 rgb = convertMatrix->matrix * (yuv + convertMatrix->offset);
    
    //4.返回颜色值(RGBA)
    return float4(rgb, 1.0);
}
