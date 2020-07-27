
 //  ViewController.swift
 //  GLKit_demo
 //
 //  Created by  on 2020/7/25.
 //
 import UIKit
 import GLKit

 class ViewController: GLKViewController {
     
     var context: EAGLContext?
     var effect: GLKBaseEffect!

     override func viewDidLoad() {
         super.viewDidLoad()
         
         setupConfig()
         
         setupVertex()
         
         setupTexture()
     }

     override func glkView(_ view: GLKView, drawIn rect: CGRect) {
         glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
         
         //准备绘制
         effect.prepareToDraw()
         
         //开始绘制
         glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)
     }
     
 }


 extension ViewController{
     
     fileprivate func setupConfig(){
         
         //1、初始化上下文，并判断是否创建成功
         context = EAGLContext.init(api: .openGLES3)
         guard let cont = self.context  else{return}
         
         
         //2、设置当前上下文
         EAGLContext.setCurrent(cont)
         
         //3、初始化GLKView，并设置上下文、缓冲区
         let glView = self.view as! GLKView
         glView.context = cont
         glView.drawableColorFormat = .RGBA8888
         glView.drawableDepthFormat = .format24
         
         //4、设置背景色
         glClearColor(0.3, 0.4, 0.5, 1.0)
         
     }
     
     
     fileprivate func setupVertex(){
         
         //1、创建顶点数组
         var vertexData: [GLfloat] = [
             
             0.5, -0.5, 0.0,    1.0, 0.0, //右下
             0.5, 0.5,  0.0,    1.0, 1.0, //右上
             -0.5, 0.5, 0.0,    0.0, 1.0, //左上
             
             0.5, -0.5, 0.0,    1.0, 0.0, //右下
             -0.5, 0.5, 0.0,    0.0, 1.0, //左上
             -0.5, -0.5, 0.0,   0.0, 0.0, //左下
         ];
         
         //2、拷贝到顶点缓冲区
         var bufferID: GLuint = 0
 //        创建顶点缓冲区标识符
         glGenBuffers(1, &bufferID)
 //        绑定顶点缓冲区
         glBindBuffer(GLenum(GL_ARRAY_BUFFER), bufferID)
 //        coppy顶点数据
         glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLfloat>.stride*vertexData.count, &vertexData, GLenum(GL_STATIC_DRAW))
         
         
         //3、打开通道（需要打开两次）
 //        oc中的sizeof，在swift中需要使用 GLsizei(MemoryLayout<CGFloat>.size * 5)
 //        swift 指针：UnsafeMutablePointer<GLubyte>
         glEnableVertexAttribArray(GLuint(GLKVertexAttrib.position.rawValue))
          glVertexAttribPointer(GLuint(GLKVertexAttrib.position.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.stride*5), nil)
         
         glEnableVertexAttribArray(GLuint(GLKVertexAttrib.texCoord0.rawValue))
         glVertexAttribPointer(GLuint(GLKVertexAttrib.texCoord0.rawValue), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.stride*5), UnsafeMutableRawPointer(bitPattern: 3*MemoryLayout<GLfloat>.stride))
         
     }
     
     fileprivate func setupTexture(){
         //1、获取图片路径
         let path = Bundle.main.path(forResource: "mouse", ofType: "jpg")
         
         //2、设置纹理参数
         guard let textureInfo = try? GLKTextureLoader.texture(withContentsOfFile: path!, options: [GLKTextureLoaderOriginBottomLeft:NSNumber.init(integerLiteral: 1)] ) else {
             return
         }
         effect = GLKBaseEffect()
         effect.texture2d0.enabled = GLboolean(GL_TRUE)
         effect.texture2d0.name = textureInfo.name
         
         
         
     }
     
 }
