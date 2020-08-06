//
//  CCVertexAttribArrayBuffer.m
//  01 粒子系统
//
//  Created by — on 2018/2/25.
//  Copyright © 2018年 —. All rights reserved.
//

#import "CCVertexAttribArrayBuffer.h"

@implementation CCVertexAttribArrayBuffer


//此方法在当前的OpenGL ES上下文中创建一个顶点属性数组缓冲区
- (id)initWithAttribStride:(GLsizeiptr)aStride
          numberOfVertices:(GLsizei)count
                     bytes:(const GLvoid *)dataPtr
                     usage:(GLenum)usage;
{
    self = [super init];
    
    if(self != nil)
    {
        _stride = aStride;
        _bufferSizeBytes = _stride * count;
        
        //初始化缓存区
        //创建VBO的3个步骤
        //1.生成新缓存对象glGenBuffers
        //2.绑定缓存对象glBindBuffer
        //3.将顶点数据拷贝到缓存对象中glBufferData
        
        // STEP 1 创建缓存对象并返回缓存对象的标识符
        glGenBuffers(1,&_name);
        
        // STEP 2 将缓存对象对应到相应的缓存上
        /*
         glBindBuffer (GLenum target, GLuint buffer);
         target:告诉VBO缓存对象时保存顶点数组数据还是索引数组数据 :GL_ARRAY_BUFFER\GL_ELEMENT_ARRAY_BUFFER
         任何顶点属性，如顶点坐标、纹理坐标、法线与颜色分量数组都使用GL_ARRAY_BUFFER。用于glDraw[Range]Elements()的索引数据需要使用GL_ELEMENT_ARRAY绑定。注意，target标志帮助VBO确定缓存对象最有效的位置，如有些系统将索引保存AGP或系统内存中，将顶点保存在显卡内存中。
         buffer: 缓存区对象
         */

        glBindBuffer(GL_ARRAY_BUFFER,self.name);
        /*
         数据拷贝到缓存对象
         void glBufferData(GLenum target，GLsizeiptr size, const GLvoid*  data, GLenum usage);
         target:可以为GL_ARRAY_BUFFER或GL_ELEMENT_ARRAY
         size:待传递数据字节数量
         data:源数据数组指针
         usage:
         GL_STATIC_DRAW
         GL_STATIC_READ
         GL_STATIC_COPY
         GL_DYNAMIC_DRAW
         GL_DYNAMIC_READ
         GL_DYNAMIC_COPY
         GL_STREAM_DRAW
         GL_STREAM_READ
         GL_STREAM_COPY
         
         ”static“表示VBO中的数据将不会被改动（一次指定多次使用），
         ”dynamic“表示数据将会被频繁改动（反复指定与使用），
         ”stream“表示每帧数据都要改变（一次指定一次使用）。
         ”draw“表示数据将被发送到GPU以待绘制（应用程序到GL），
         ”read“表示数据将被客户端程序读取（GL到应用程序），”
         */
        // STEP 3 数据拷贝到缓存对象
        glBufferData(
                     GL_ARRAY_BUFFER,  // Initialize buffer contents
                     _bufferSizeBytes,  // Number of bytes to copy
                     dataPtr,          // Address of bytes to copy
                     usage);           // Hint: cache in GPU memory
        
    }
    
    return self;
}

//此方法加载由接收存储的数据
- (void)reinitWithAttribStride:(GLsizeiptr)aStride
              numberOfVertices:(GLsizei)count
                         bytes:(const GLvoid *)dataPtr
{
    _stride = aStride;
    _bufferSizeBytes = aStride * count;
    
    // STEP 1 将缓存对象对应到相应的缓存上
    glBindBuffer(GL_ARRAY_BUFFER, self.name);
    // STEP 2 数据拷贝到缓存对象
    glBufferData(
                 GL_ARRAY_BUFFER,
                 _bufferSizeBytes,
                 dataPtr,
                 GL_DYNAMIC_DRAW); 
}

//当应用程序希望使用缓冲区呈现任何几何图形时，必须准备一个顶点属性数组缓冲区。当你的应用程序准备一个缓冲区时，一些OpenGL ES状态被改变，允许绑定缓冲区和配置指针。
- (void)prepareToDrawWithAttrib:(GLuint)index
            numberOfCoordinates:(GLint)count
                   attribOffset:(GLsizeiptr)offset
                   shouldEnable:(BOOL)shouldEnable
{
    if (count < 0 || count > 4) {
        NSLog(@"Error:Count Error");
        return ;

    }
    
    if (_stride < offset) {
        NSLog(@"Error:_stride < Offset");
        return;
    }
    
    if (_name == 0) {
        NSLog(@"Error:name == Null");
    }
    
    // STEP 1 将缓存对象对应到相应的缓存上
    glBindBuffer(GL_ARRAY_BUFFER,self.name);
    
    //判断是否使用
    if(shouldEnable)
    {
        // Step 2
        //出于性能考虑，所有顶点着色器的属性（Attribute）变量都是关闭的，意味着数据在着色器端是不可见的，哪怕数据已经上传到GPU，由glEnableVertexAttribArray启用指定属性，才可在顶点着色器中访问逐顶点的属性数据.
        //VBO只是建立CPU和GPU之间的逻辑连接，从而实现了CPU数据上传至GPU。但是，数据在GPU端是否可见，即，着色器能否读取到数据，由是否启用了对应的属性决定，这就是glEnableVertexAttribArray的功能，允许顶点着色器读取GPU（服务器端）数据。
        //顶点数据传入GPU之后，还需要通知OpenGL如何解释这些顶点数据，这个工作由函数glVertexAttribPointer完成
                glEnableVertexAttribArray(index);
    }
    
    // Step 3
    //顶点数据传入GPU之后，还需要通知OpenGL如何解释这些顶点数据，这个工作由函数glVertexAttribPointer完成
    /*
     glVertexAttribPointer (GLuint indx, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid* ptr)
     indx:参数指定顶点属性位置
     size:指定顶点属性大小
     type:指定数据类型
     normalized:数据被标准化
     stride:步长
     ptr:偏移量 NULL+offset
     */
    glVertexAttribPointer(
                          index,
                          count,
                          GL_FLOAT,
                          GL_FALSE,
                          (int)self.stride,
                          NULL + offset);
    
}

//绘制
//提交由模式标识的绘图命令，并指示OpenGL ES从准备好的缓冲区中的顶点开始，从先前准备好的缓冲区中使用计数顶点。
+ (void)drawPreparedArraysWithMode:(GLenum)mode
                  startVertexIndex:(GLint)first
                  numberOfVertices:(GLsizei)count;
{
    //绘制
    /*
     glDrawArrays (GLenum mode, GLint first, GLsizei count);提供绘制功能。当采用顶点数组方式绘制图形时，使用该函数。该函数根据顶点数组中的坐标数据和指定的模式，进行绘制。
     参数列表:
     mode，绘制方式，OpenGL2.0以后提供以下参数：GL_POINTS、GL_LINES、GL_LINE_LOOP、GL_LINE_STRIP、GL_TRIANGLES、GL_TRIANGLE_STRIP、GL_TRIANGLE_FAN。
     first，从数组缓存中的哪一位开始绘制，一般为0。
     count，数组中顶点的数量。
     */
    glDrawArrays(mode, first, count);
}

//将绘图命令模式和instructsopengl ES确定使用缓冲区从顶点索引的第一个数的顶点。顶点索引从0开始。
- (void)drawArrayWithMode:(GLenum)mode
         startVertexIndex:(GLint)first
         numberOfVertices:(GLsizei)count
{
    if (self.bufferSizeBytes < (first + count) * self.stride) {
        NSLog(@"Vertex Error!");
    }
    
    //绘制
    /*
     glDrawArrays (GLenum mode, GLint first, GLsizei count);提供绘制功能。当采用顶点数组方式绘制图形时，使用该函数。该函数根据顶点数组中的坐标数据和指定的模式，进行绘制。
     参数列表:
     mode，绘制方式，OpenGL2.0以后提供以下参数：GL_POINTS、GL_LINES、GL_LINE_LOOP、GL_LINE_STRIP、GL_TRIANGLES、GL_TRIANGLE_STRIP、GL_TRIANGLE_FAN。
     first，从数组缓存中的哪一位开始绘制，一般为0。
     count，数组中顶点的数量。
     */
    glDrawArrays(mode, first, count);
}


- (void)dealloc
{
    //从当前上下文删除缓冲区
    if (0 != _name)
    {
        glDeleteBuffers (1, &_name);
        _name = 0;
    }
}


@end
