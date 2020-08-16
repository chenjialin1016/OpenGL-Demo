//
//  LongLegVertexAttribArrayBuffer.h
//  001--CClhDemo
//
//  Created by CC老师 on 2020/6/22.
//  Copyright © 2020年 CC老师. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface LongLegVertexAttribArrayBuffer : NSObject
//初始化缓存区
- (id)initWithAttribStride:(GLsizei)stride
          numberOfVertices:(GLsizei)count
                      data:(const GLvoid *)data
                     usage:(GLenum)usage;

//准备绘制(打开通道,以及传递属性)
- (void)prepareToDrawWithAttrib:(GLuint)index
            numberOfCoordinates:(GLint)count
                   attribOffset:(GLsizeiptr)offset
                   shouldEnable:(BOOL)shouldEnable;

//绘制
- (void)drawArrayWithMode:(GLenum)mode
         startVertexIndex:(GLint)first
         numberOfVertices:(GLsizei)count;

//更新(重新开辟缓存区)
- (void)updateDataWithAttribStride:(GLsizei)stride
                  numberOfVertices:(GLsizei)count
                              data:(const GLvoid *)data
                             usage:(GLenum)usage;

@end
