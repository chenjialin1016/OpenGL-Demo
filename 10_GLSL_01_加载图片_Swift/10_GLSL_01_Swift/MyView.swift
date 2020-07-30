//
//  MyView.swift
//  10_GLSL_01_Swift
//
//  Created by 陈嘉琳 on 2020/7/29.
//

import UIKit
import OpenGLES

class MyView: UIView {

    fileprivate var myEaglLayer: CAEAGLLayer!
    fileprivate var myContext: EAGLContext!
    fileprivate var myColorRenderBuffer: GLuint = GLuint()
    fileprivate var myColorFrameBuffer: GLuint = GLuint()
    
    fileprivate var myProgram: GLuint = GLuint()
    
    override func layoutSubviews() {
        
//        1、创建图层
        setupLayer()
        
//        2、创建上下文
        setupContext()
        
//        3、清空缓存区
        deleteRenderAndFrameBuffer()
        
//        4、设置RenderBuffer
        setupRenderBuffer()
        
//        5、设置FrameBuffer
        setupFrameBuffer()
        
//        6、开始绘制
        renderLayer()
    }

    
    override class var layerClass: AnyClass {
        return CAEAGLLayer.self
    }
    
    
}
//初始化
extension MyView{
    
//    1、创建图层
    fileprivate func setupLayer(){
        //1、创建特殊图层
        self.myEaglLayer = self.layer as? CAEAGLLayer
        
        //2、设置scale
        self.contentScaleFactor = UIScreen.main.scale
        
        //3、设置描述属性
        self.myEaglLayer.drawableProperties = [kEAGLDrawablePropertyRetainedBacking: false, kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8]
    }
    
//    2、创建上下文
    fileprivate func setupContext(){
        //1、创建图形上下文 & 判断是否创建成功
        guard let context = EAGLContext.init(api: .openGLES3) else{
            print("create context failed")
            return
        }
        //2、设置当前图形上下文
        guard EAGLContext.setCurrent(context) else{
            print("setCurrent failed")
            return
        }
        
        self.myContext = context
    }
    
//    3、清空缓存区
    fileprivate func deleteRenderAndFrameBuffer(){
        //1、清理RenderBuffer
        glDeleteBuffers(1, &myColorRenderBuffer)
        myColorRenderBuffer = 0
        
        //2、清理FrameBuffer
        glDeleteBuffers(1, &myColorFrameBuffer)
        myColorFrameBuffer = 0
    }
    
//    4、设置RenderBuffer
    fileprivate func setupRenderBuffer(){
        
        //1、申请一个缓存区标识符
        glGenRenderbuffers(1, &myColorRenderBuffer)
        
        //4、将标识符绑定到GL_RENDERBUFFER
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), myColorRenderBuffer)
        
        //5、将可绘制对象的CAEAGLLayer对象的存储绑定到OpenGL ES RenderBuffer对象
        myContext?.renderbufferStorage(Int(GL_RENDERBUFFER), from: myEaglLayer)
        
    }
    
//    5、设置FrameBuffer
    fileprivate func setupFrameBuffer(){

        //2、申请一个缓存区标识符
        glGenBuffers(1, &myColorFrameBuffer)
        
        //4、将标识符绑定到GL_FRAMEBUFFER
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), myColorFrameBuffer)
        
        //5、将渲染缓存区的myColorRenderBuffer通过glFramebufferRenderbuffer函数绑定到GL_COLOR_ATTACHMENT)上
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), myColorRenderBuffer)
    }
    
}


//绘制
extension MyView{
//    6、开始绘制
    fileprivate func renderLayer(){
        //设置清屏颜色 & 清除缓冲区
        glClearColor(0.3, 0.4, 0.5, 1)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        //1、设置视口大小
        let scale = UIScreen.main.scale
        glViewport(GLint(self.frame.origin.x * scale), GLint(self.frame.origin.y * scale), GLsizei(self.frame.size.width * scale), GLsizei(self.frame.size.height * scale))
        
        //2、读取顶点、片元着色器
        let vertFile = Bundle.main.path(forResource: "shaderv", ofType: "vsh") ?? ""
        let fragFile = Bundle.main.path(forResource: "shaderf", ofType: "fsh") ?? ""
        
        //3、加载shader
        myProgram = loadShaders(vertFile, fragFile)!
       
        //4、链接 & 获取链接状态
       glLinkProgram(myProgram)
       var linkStatus: GLint = GLint()
       glGetProgramiv(myProgram, GLenum(GL_LINK_STATUS), &linkStatus)
       if linkStatus == GLint(GL_FALSE) {
           let message = UnsafeMutablePointer<GLchar>.allocate(capacity: 512)
           glGetProgramInfoLog(myProgram, GLsizei(MemoryLayout<GLchar>.stride*512), nil, message)
           let messageString = String(utf8String: message)
           print("program link error \(messageString)")
           return
       }
        print("program link success!")
        glUseProgram(myProgram)
        
        
        //6、设置顶点数据、纹理数据
        var attrArr: [GLfloat] = [
            0.5, -0.5, -1.0,     1.0, 0.0,
            -0.5, 0.5, -1.0,     0.0, 1.0,
            -0.5, -0.5, -1.0,    0.0, 0.0,
                   
            0.5, 0.5, -1.0,      1.0, 1.0,
            -0.5, 0.5, -1.0,     0.0, 1.0,
            0.5, -0.5, -1.0,     1.0, 0.0,
        ]
        
        //7、处理顶点数据
        /*
         (1)顶点缓存区
         (2)申请一个缓存区标识符
         (3)将attrBuffer绑定到GL_ARRAY_BUFFER标识符上
         (4)把顶点数据从CPU内存复制到GPU上
         */
        var attrBuffer: GLuint = GLuint()
        glGenBuffers(1, &attrBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), attrBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLfloat>.size*attrArr.count, attrArr, GLenum(GL_DYNAMIC_DRAW))
        
        //8、打开通道：将顶点数据通过myProgram中的传递 到顶点着色器的position
        /*
         //1.glGetAttribLocation,用来获取vertex attribute的入口的.
         //2.告诉OpenGL ES,通过glEnableVertexAttribArray，
         //3.最后数据是通过glVertexAttribPointer传递过去的。
         */
        let position = glGetAttribLocation(myProgram, "position")
        glEnableVertexAttribArray(GLuint(position))
        glVertexAttribPointer(GLuint(position), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern: 0))
        
        
        //9、处理纹理数据
        /*
        //1.glGetAttribLocation,用来获取vertex attribute的入口的.
        //2.告诉OpenGL ES,通过glEnableVertexAttribArray，
        //3.最后数据是通过glVertexAttribPointer传递过去的。
        */
        let textColor = glGetAttribLocation(myProgram, "textCoordinate")
        glEnableVertexAttribArray(GLuint(textColor))
        glVertexAttribPointer(GLuint(textColor), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern:MemoryLayout<GLfloat>.size * 3))
        
        
        
        //10、加载纹理
        setupTexture("mouse")
        
        //11、设置纹理采样器
        glUniform1i(glGetUniformLocation(myProgram, "colorMap"), 0)
        
        //12、绘制
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)
        
        //13、从渲染缓冲区显示到屏幕上
        myContext?.presentRenderbuffer(Int(GL_RENDERBUFFER))
    }
    
//    从图片中加载纹理
    fileprivate func setupTexture(_ fileName: String){
        //1、将UIImage转换为CGImageRef
        guard let spriteImage = UIImage(named: fileName)?.cgImage else{
            print("Failed to load image \(fileName)")
            return
        }
        
        //2、读取图的大小、宽和高
        let width = spriteImage.width
        let height = spriteImage.height
        
        
        //3、获取图片字节数
        let spriteData: UnsafeMutablePointer = UnsafeMutablePointer<GLubyte>.allocate(capacity: MemoryLayout<GLubyte>.size * width * height * 4)
        
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        
        //4、创建上下文
        var spriteContext = CGContext(data: spriteData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width*4, space: spriteImage.colorSpace!, bitmapInfo: spriteImage.bitmapInfo.rawValue)
        
        //5、在CGContextRef上，将图片绘制出来 & 使用默认方式绘制
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        spriteContext?.draw(spriteImage, in: rect)
        
        //6、画图完毕就释放上下文
        UIGraphicsEndImageContext()
        spriteContext = nil
        
        //7、绑定纹理到默认的纹理ID
        glBindTexture(GLenum(GL_TEXTURE_2D), 0)
        
        //8、设置纹理属性
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
        
        //9、载入纹理
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(width), GLsizei(height), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), spriteData)
        
        //10、释放spriteData
        free(spriteData)
    }
    
//    加载shader
    fileprivate func loadShaders(_ vert: String, _ frag: String) -> GLuint?{

        var programe: GLuint = glCreateProgram()
        
        //2、编译顶点着色器、片元着色器
        guard let verShader = compileShader(GLenum(GL_VERTEX_SHADER), vert) else{
            return nil
        }
        
        guard let fragShader = compileShader(GLenum(GL_FRAGMENT_SHADER), frag) else{
            return nil
        }
        
        //3、创建最终的程序
        glAttachShader(GLuint(programe), verShader)
        glAttachShader(GLuint(programe), fragShader)
        
        //4、释放不需要的shader
        glDeleteShader(verShader)
        glDeleteShader(fragShader)
        
        return programe
        
    }
    
//    编译shader
    fileprivate func compileShader(_ type: GLenum, _ file: String)->GLuint?{
        
        let shader: GLuint = glCreateShader(type)
        
        //1、读取文件路径字符串
        guard  let content = try? String(contentsOfFile: file, encoding: .utf8) else{
            
            print("content is nil")
            return nil
        }
        
//      转换成c字符串赋值给已创建的shader
        content.withCString { (pointer) in
            var pon: UnsafePointer<GLchar>? = pointer
            //3、将着色器源码附加到着色器对象上
            glShaderSource(shader, 1, &pon, nil)
        }
        
        //4、把着色器代码编译成目标代码
        glCompileShader(shader)
        
        return shader
    }
}
