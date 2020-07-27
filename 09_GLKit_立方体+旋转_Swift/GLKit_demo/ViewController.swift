 //
 //  ViewController.swift
 //  GLKit_demo
 //
 //  Created by  on 2020/7/25.
 //

 import UIKit
 import GLKit
 import OpenGLES


 let kVertexCount = 36
 let ScreenW = UIScreen.main.bounds.size.width

 struct CCVertex {
     var positionCoord: GLKVector3
     var textureCoord: GLKVector2
 }

 class ViewController: UIViewController{
     
     lazy var glkView: GLKView = {
         let glkView = GLKView(frame: CGRect(x: 0, y: 100, width: ScreenW, height: ScreenW))
         glkView.backgroundColor = UIColor.clear
         glkView.drawableDepthFormat = .format24
         glkView.delegate = self
         view.addSubview(glkView)
         return glkView
     }()
     
     var effect: GLKBaseEffect!
     
     lazy var vertices: UnsafeMutablePointer<CCVertex> = {
         let verticesSize = MemoryLayout<CCVertex>.size*kVertexCount
         let vertices = UnsafeMutablePointer<CCVertex>.allocate(capacity: verticesSize)
         return vertices
     }()
     
     lazy var displayLink: CADisplayLink = {
         let link = CADisplayLink(target: self, selector: #selector(update))
         return link
     }()
     var angle: GLfloat = 0
     var vertexBuffer: GLuint = GLuint()

     override func viewDidLoad() {
         super.viewDidLoad()
         
         self.view.backgroundColor = UIColor.black
         
         commonInit()
         
         setupVertex()
         
         addCADisplayLink()
     }
     
 }


 extension ViewController{
     
     fileprivate func commonInit(){
         
 //        1、初始化上下文 & 设置当前上下文
         guard let context = EAGLContext(api: .openGLES3) else{
             return
         }
         EAGLContext.setCurrent(context)
         glkView.context = context
         
 //        读取纹理图片
         let filePath = Bundle.main.path(forResource: "mouse", ofType: "jpg")
         let image = UIImage(contentsOfFile: filePath!)
         guard let textureInfo: GLKTextureInfo = try? GLKTextureLoader.texture(with: (image?.cgImage)!, options: [GLKTextureLoaderOriginBottomLeft:NSNumber.init(integerLiteral: 1)]) else{
             return
         }
         
 //        使用effect
         effect = GLKBaseEffect()
         effect.texture2d0.name = textureInfo.name
         effect.texture2d0.target = GLKTextureTarget(rawValue: textureInfo.target)!
     }
     
     
     fileprivate func setupVertex(){
         
         //1、创建顶点数组
         self.vertices[0] = CCVertex(positionCoord: GLKVector3(v: (-0.5, 0.5, 0.5)), textureCoord: GLKVector2(v: (0, 1)))
        self.vertices[1] = CCVertex(positionCoord: GLKVector3(v: (-0.5, -0.5, 0.5)), textureCoord: GLKVector2(v: (0, 0)))
        self.vertices[2] = CCVertex(positionCoord: GLKVector3(v: (0.5, 0.5, 0.5)), textureCoord: GLKVector2(v: (1, 1)))

        self.vertices[3] = CCVertex(positionCoord: GLKVector3(v: (-0.5, -0.5, 0.5)), textureCoord: GLKVector2(v: (0, 0)))
        self.vertices[4] = CCVertex(positionCoord: GLKVector3(v: (0.5, 0.5, 0.5)), textureCoord: GLKVector2(v: (1, 1)))
        self.vertices[5] = CCVertex(positionCoord: GLKVector3(v: (0.5, -0.5, 0.5)), textureCoord: GLKVector2(v: (1, 0)))
        
        // 上面
        self.vertices[6] = CCVertex(positionCoord: GLKVector3(v: (0.5, 0.5, 0.5)), textureCoord: GLKVector2(v: (1, 1)))
        self.vertices[7] = CCVertex(positionCoord: GLKVector3(v: (-0.5, 0.5, 0.5)), textureCoord: GLKVector2(v: (0, 1)))
        self.vertices[8] = CCVertex(positionCoord: GLKVector3(v: (0.5, 0.5, -0.5)), textureCoord: GLKVector2(v: (1, 0)))
        
        self.vertices[9] = CCVertex(positionCoord: GLKVector3(v: (-0.5, 0.5, 0.5)), textureCoord: GLKVector2(v: (0, 1)))
        self.vertices[10] = CCVertex(positionCoord: GLKVector3(v: (0.5, 0.5, -0.5)), textureCoord: GLKVector2(v: (1, 0)))
        self.vertices[11] = CCVertex(positionCoord: GLKVector3(v: (-0.5, 0.5, -0.5)), textureCoord: GLKVector2(v: (0, 0)))

        // 下面
        self.vertices[12] = CCVertex(positionCoord: GLKVector3(v: (0.5, -0.5, 0.5)), textureCoord: GLKVector2(v: (1, 1)))
        self.vertices[13] = CCVertex(positionCoord: GLKVector3(v: (-0.5, -0.5, 0.5)), textureCoord: GLKVector2(v: (0, 1)))
        self.vertices[14] = CCVertex(positionCoord: GLKVector3(v: (0.5, -0.5, -0.5)), textureCoord: GLKVector2(v: (1, 0)))
        
        self.vertices[15] = CCVertex(positionCoord: GLKVector3(v: (-0.5, -0.5, 0.5)), textureCoord: GLKVector2(v: (0, 1)))
        self.vertices[16] = CCVertex(positionCoord: GLKVector3(v: (0.5, -0.5, -0.5)), textureCoord: GLKVector2(v: (1, 0)))
        self.vertices[17] = CCVertex(positionCoord: GLKVector3(v: (-0.5, -0.5, -0.5)), textureCoord: GLKVector2(v: (0, 0)))

        // 左面
        self.vertices[18] = CCVertex(positionCoord: GLKVector3(v: (-0.5, 0.5, 0.5)), textureCoord: GLKVector2(v: (1, 1)))
        self.vertices[19] = CCVertex(positionCoord: GLKVector3(v: (-0.5, -0.5, 0.5)), textureCoord: GLKVector2(v: (0, 1)))
        self.vertices[20] = CCVertex(positionCoord: GLKVector3(v: (-0.5, 0.5, -0.5)), textureCoord: GLKVector2(v: (1, 0)))
        
        self.vertices[21] = CCVertex(positionCoord: GLKVector3(v: (-0.5, -0.5, 0.5)), textureCoord: GLKVector2(v: (0, 1)))
        self.vertices[22] = CCVertex(positionCoord: GLKVector3(v: (-0.5, 0.5, -0.5)), textureCoord: GLKVector2(v: (1, 0)))
        self.vertices[23] = CCVertex(positionCoord: GLKVector3(v: (-0.5, -0.5, -0.5)), textureCoord: GLKVector2(v: (0, 0)))

        // 右面
        self.vertices[24] = CCVertex(positionCoord: GLKVector3(v: (0.5, 0.5, 0.5)), textureCoord: GLKVector2(v: (1, 1)))
        self.vertices[25] = CCVertex(positionCoord: GLKVector3(v: (0.5, -0.5, 0.5)), textureCoord: GLKVector2(v: (0, 1)))
        self.vertices[26] = CCVertex(positionCoord: GLKVector3(v: (0.5, 0.5, -0.5)), textureCoord: GLKVector2(v: (1, 0)))
        
        self.vertices[27] = CCVertex(positionCoord: GLKVector3(v: (0.5, -0.5, 0.5)), textureCoord: GLKVector2(v: (0, 1)))
        self.vertices[28] = CCVertex(positionCoord: GLKVector3(v: (0.5, 0.5, -0.5)), textureCoord: GLKVector2(v: (1, 0)))
        self.vertices[29] = CCVertex(positionCoord: GLKVector3(v: (0.5, -0.5, -0.5)), textureCoord: GLKVector2(v: (0, 0)))

        // 后面
        self.vertices[30] = CCVertex(positionCoord: GLKVector3(v: (-0.5, 0.5, -0.5)), textureCoord: GLKVector2(v: (0, 1)))
        self.vertices[31] = CCVertex(positionCoord: GLKVector3(v: (-0.5, -0.5, -0.5)), textureCoord: GLKVector2(v: (0, 0)))
        self.vertices[32] = CCVertex(positionCoord: GLKVector3(v: (0.5, 0.5, -0.5)), textureCoord: GLKVector2(v: (1, 1)))
        
        self.vertices[33] = CCVertex(positionCoord: GLKVector3(v: (-0.5, -0.5, -0.5)), textureCoord: GLKVector2(v: (0, 0)))
        self.vertices[34] = CCVertex(positionCoord: GLKVector3(v: (0.5, 0.5, -0.5)), textureCoord: GLKVector2(v: (1, 1)))
        self.vertices[35] = CCVertex(positionCoord: GLKVector3(v: (0.5, -0.5, -0.5)), textureCoord: GLKVector2(v: (1, 0)))
         
         //2、拷贝到顶点缓冲区
         glGenBuffers(1, &vertexBuffer)
 //        绑定顶点缓冲区
         glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
 //        coppy顶点数据
         glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<CCVertex>.size*kVertexCount, vertices, GLenum(GL_STATIC_DRAW))
         
         
         //3、打开通道（需要打开两次）
 //        oc中的sizeof，在swift中需要使用 GLsizei(MemoryLayout<CGFloat>.size * 5)
 //        swift 指针：UnsafeMutablePointer<GLubyte>
         glEnableVertexAttribArray(GLuint(GLKVertexAttrib.position.rawValue))
          glVertexAttribPointer(GLuint(GLKVertexAttrib.position.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<CCVertex>.size), UnsafeMutableRawPointer(bitPattern: 0))
         
         glEnableVertexAttribArray(GLuint(GLKVertexAttrib.texCoord0.rawValue))
         //这里加4的原因是因为苹果对部分包含vector类型数据的结构体加了一个padding,此处这个padding等于4个字节。CCVertex占24个字节，而不是5个float所占的20个字节
         glVertexAttribPointer(GLuint(GLKVertexAttrib.texCoord0.rawValue), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<CCVertex>.size), UnsafeMutableRawPointer(bitPattern: MemoryLayout<GLKVector3>.size+4))
         
     }
     
     fileprivate func addCADisplayLink(){
         displayLink.add(to: RunLoop.main, forMode: .common)
     }
     
     @objc fileprivate func update(){
 //        计算旋转角度
         angle = (angle + 5).truncatingRemainder(dividingBy: 360)
         
 //        修改矩阵堆栈
         effect.transform.modelviewMatrix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(angle), 0.3, 1, -0.7)
         
 //        重新渲染
         glkView.display()
     }
     
 }

 extension ViewController: GLKViewDelegate{
     func glkView(_ view: GLKView, drawIn rect: CGRect) {
         
 //       开启深度测试
         glEnable(GLenum(GL_DEPTH_TEST));
         glClear(GLbitfield(GL_COLOR_BUFFER_BIT) | UInt32(GL_DEPTH_BUFFER_BIT))
         
         //准备绘制
         effect.prepareToDraw()
         
         //开始绘制
         glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(kVertexCount))
     }
 }
