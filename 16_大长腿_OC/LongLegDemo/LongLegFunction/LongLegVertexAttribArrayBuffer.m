//
//  LongLegVertexAttribArrayBuffer.m
//  001--CClhDemo
//
//  Created by CC老师 on 2020/6/22.
//  Copyright © 2020年 CC老师. All rights reserved.
//

#import "LongLegVertexAttribArrayBuffer.h"

@interface LongLegVertexAttribArrayBuffer ()

@property (nonatomic, assign) GLuint glName;
@property (nonatomic, assign) GLsizeiptr bufferSizeBytes;
@property (nonatomic, assign) GLsizei stride;

@end


@implementation LongLegVertexAttribArrayBuffer

- (void)dealloc {
    if (_glName != 0) {
        glDeleteBuffers(1, &_glName);
        _glName = 0;
    }
}

- (id)initWithAttribStride:(GLsizei)stride
          numberOfVertices:(GLsizei)count
                      data:(const GLvoid *)data
                     usage:(GLenum)usage {
    self = [super init];
    if (self) {
        _stride = stride;
        //根据步长计算出缓存区的大小 stride * count
        _bufferSizeBytes = stride * count;
        //生成缓存区对象的名称;
        glGenBuffers(1, &_glName);
        //将_glName 绑定到对应的缓存区;
        glBindBuffer(GL_ARRAY_BUFFER, _glName);
        //创建并初始化缓存区对象的数据存储;
        glBufferData(GL_ARRAY_BUFFER, _bufferSizeBytes, data, usage);
    }
    return self;
}

- (void)prepareToDrawWithAttrib:(GLuint)index
            numberOfCoordinates:(GLint)count
                   attribOffset:(GLsizeiptr)offset
                   shouldEnable:(BOOL)shouldEnable {
    
    //将_glName 绑定到对应的缓存区;
    glBindBuffer(GL_ARRAY_BUFFER, self.glName);
    //默认顶点属性是关闭的,所以使用前要手动打开;
    if (shouldEnable) {
        glEnableVertexAttribArray(index);
    }
    //定义顶点属性传递的方式;
    glVertexAttribPointer(index, count, GL_FLOAT, GL_FALSE, self.stride, NULL + offset);
}

- (void)drawArrayWithMode:(GLenum)mode
         startVertexIndex:(GLint)first
         numberOfVertices:(GLsizei)count {
    //开始绘制
    glDrawArrays(mode, first, count);
}

- (void)updateDataWithAttribStride:(GLsizei)stride
                  numberOfVertices:(GLsizei)count
                              data:(const GLvoid *)data
                             usage:(GLenum)usage {
    self.stride = stride;
    self.bufferSizeBytes = stride * count;
    //重新绑定缓存区空间
    glBindBuffer(GL_ARRAY_BUFFER, self.glName);
    //绑定缓存区的数据空间;
    glBufferData(GL_ARRAY_BUFFER, self.bufferSizeBytes, data, usage);
}


@end
