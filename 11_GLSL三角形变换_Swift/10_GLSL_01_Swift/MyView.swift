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
    fileprivate var myVertices: GLuint = GLuint()
    
    fileprivate var myProgram: GLuint = GLuint()
    
    fileprivate var xDegree: Float! = 0
    fileprivate var yDegree: Float! = 0
    fileprivate var zDegree: Float! = 0
    
    fileprivate var bX: Bool = false;
    fileprivate var bY: Bool = false;
    fileprivate var bZ: Bool = false;
    
    fileprivate var timer: Timer?
    
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
    
    @IBAction func xClick(_ sender: Any) {
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(reDegree), userInfo: nil, repeats: true)
        }
        
        bX = !bX
    }
    
    @IBAction func yClick(_ sender: Any) {
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(reDegree), userInfo: nil, repeats: true)
        }
        
        bY = !bY
    }
    @IBAction func zClick(_ sender: Any) {
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(reDegree), userInfo: nil, repeats: true)
        }
        
        bZ = !bZ
    }
    
    
    @objc func reDegree(){
        //如果停止X轴旋转，X = 0则度数就停留在暂停前的度数.
        //更新度数
        xDegree += (bX ? 1 : 0)*5
        yDegree += (bY ? 1 : 0)*5
        zDegree += (bZ ? 1 : 0)*5
        
        renderLayer()
    }
    
}
//初始化
extension MyView{
    
//    1、创建图层
    fileprivate func setupLayer(){
        self.myEaglLayer = self.layer as! CAEAGLLayer
        self.contentScaleFactor = UIScreen.main.scale
        self.myEaglLayer.drawableProperties = [kEAGLDrawablePropertyRetainedBacking: false, kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8];
    }
    
//    2、创建上下文
    fileprivate func setupContext(){
        guard let context = EAGLContext(api: .openGLES2) else{
            print("create context falied")
            return
        }
        
        guard EAGLContext.setCurrent(context) else {
            print("set current context failed")
            return
        }
        
        self.myContext = context
    }
    
//    3、清空缓存区
    fileprivate func deleteRenderAndFrameBuffer(){
       glDeleteBuffers(1, &myColorRenderBuffer)
        myColorRenderBuffer = 0
        
        glDeleteBuffers(1, &myColorFrameBuffer)
        myColorFrameBuffer = 0
    }
    
//    4、设置RenderBuffer
    fileprivate func setupRenderBuffer(){
        
      glGenRenderbuffers(1, &myColorRenderBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), myColorRenderBuffer)
        self.myContext.renderbufferStorage(Int(GL_RENDERBUFFER), from: self.myEaglLayer)
        
    }
    
//    5、设置FrameBuffer
    fileprivate func setupFrameBuffer(){

       glGenBuffers(1, &myColorFrameBuffer)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), myColorFrameBuffer)
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), myColorRenderBuffer)
    }
    
}


//绘制
extension MyView{
//    6、开始绘制
    fileprivate func renderLayer(){
        glClearColor(0, 0, 0, 1)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        let scale = UIScreen.main.scale
        glViewport(GLint(self.frame.origin.x * scale), GLint(self.frame.origin.y * scale), GLsizei(self.frame.size.width * scale), GLsizei(self.frame.size.height * scale))
        
        
        let vertFile = Bundle.main.path(forResource: "shaderv", ofType: "glsl") ?? ""
        let fragFile = Bundle.main.path(forResource: "shaderf", ofType: "glsl") ?? ""
        print("vertFile: \(vertFile)")
        print("fragFile: \(fragFile)")
        
        self.myProgram = loadShaders(vertFile, fragFile)!
        
        guard myProgram != 0 else{
            return
        }
        
//        顶点数组、索引数组
        let attrArr: [GLfloat] = [
            -0.5, 0.5, 0.0,      1.0, 0.0, 1.0, //左上0
            0.5, 0.5, 0.0,       1.0, 0.0, 1.0, //右上1
            -0.5, -0.5, 0.0,     1.0, 1.0, 1.0, //左下2
            
            0.5, -0.5, 0.0,      1.0, 1.0, 1.0, //右下3
            0.0, 0.0, 1.0,       0.0, 1.0, 0.0, //顶点4
        ]
        
        let indices: [GLuint] = [
            0, 3, 2,
            0, 1, 3,
            0, 2, 4,
            0, 4, 1,
            2, 3, 4,
            1, 4, 3,
        ]
        
//        判断顶点缓冲区是否为空
        if  myVertices == 0 {
            glGenBuffers(1, &myVertices)
        }
        
//        copy到GPU
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), myVertices)
        glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLfloat>.size*attrArr.count, attrArr, GLenum(GL_DYNAMIC_DRAW))
        
//        打开顶点通道
        let position = glGetAttribLocation(myProgram, "position")
        glEnableVertexAttribArray(GLuint(position))
        glVertexAttribPointer(GLuint(position), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size*6), UnsafeMutablePointer(bitPattern: 0))
        
//        打开顶点颜色通道
        let  positionColor = glGetAttribLocation(myProgram, "positionColor")
        glEnableVertexAttribArray(GLuint(positionColor))
        glVertexAttribPointer(GLuint(positionColor), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), Int32(MemoryLayout<GLfloat>.size)*6, UnsafeMutablePointer(bitPattern: MemoryLayout<GLfloat>.size*3))
        
//        构建矩阵
        let projectionMatrixSlot = glGetUniformLocation(myProgram, "projrctionMatrix")
        let modelViewMatrixSlot = glGetUniformLocation(myProgram, "modelViewMatrix")
        
        let width: Float = Float(self.frame.size.width)
        let height: Float = Float(self.frame.size.height)
        let aspect = width / height
        
//        创建4*4的投影矩阵
        var _projectionMatrix: KSMatrix4 = KSMatrix4()
        //获取单元矩阵
        ksMatrixLoadIdentity(&_projectionMatrix)
        //获取透视矩阵
        /*
         参数1：矩阵
         参数2：视角，度数为单位
         参数3：纵横比
         参数4：近平面距离
         参数5：远平面距离
         参考PPT
         */
        //设置透视投影
        ksPerspective(&_projectionMatrix, 30.0, aspect, 5.0, 20.0)
        
        //将投影矩阵传递到顶点着色器
        //链接：https://www.it1352.com/1705628.html
        var components = MemoryLayout.size(ofValue: _projectionMatrix.m) / MemoryLayout.size(ofValue: _projectionMatrix.m.0)
        withUnsafePointer(to: &_projectionMatrix.m) {
            $0.withMemoryRebound(to: GLfloat.self, capacity: components) {
                glUniformMatrix4fv(projectionMatrixSlot, 1, GLboolean(GL_FALSE), $0)
            }
        }
       
        
//      创建4*4模型视图矩阵
        var _modelViewMatrix: KSMatrix4 = KSMatrix4()
        //获取单元矩阵
        ksMatrixLoadIdentity(&_modelViewMatrix)
        //平移
        ksTranslate(&_modelViewMatrix, 0, 0, -10)
        
//        创建旋转
        var _rotationMatrix: KSMatrix4 = KSMatrix4()
        //初始化为单元矩阵
        ksMatrixLoadIdentity(&_rotationMatrix)
        //旋转
        ksRotate(&_rotationMatrix, xDegree, 1, 0, 0)
        ksRotate(&_rotationMatrix, yDegree, 0, 1, 0)
        ksRotate(&_rotationMatrix, zDegree, 0, 0, 1)
        
        //矩阵相乘
        //用局部变量存储结构，在拷贝至模型视图矩阵
        var result: KSMatrix4 = KSMatrix4()
        ksMatrixMultiply(&result, &_rotationMatrix, &_modelViewMatrix)
        _modelViewMatrix = result
        //将mv矩阵传递到顶点着色器
        components = MemoryLayout.size(ofValue: _modelViewMatrix.m) / MemoryLayout.size(ofValue: _modelViewMatrix.m.0)
        withUnsafePointer(to: &_modelViewMatrix) {
            $0.withMemoryRebound(to: GLfloat.self, capacity: components) {
                glUniformMatrix4fv(modelViewMatrixSlot, 1, GLboolean(GL_FALSE), $0)
            }
        }
        
//        打开正背面剔除
        glEnable(GLenum(GL_CULL_FACE))
        
//        索引绘图
        /*
            model : 图元装配方式
            count： 绘图顶点个数（并不是顶点个数，是索引个数）
            type：类型，GL_UNSIGNED_BYTE
            indices：索引数组
            */
//        MemoryLayout<GLfloat>.size 与 MemoryLayout.size(ofValue:indices) 是有区别的！！！！！
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei(MemoryLayout<GLuint>.size*indices.count / MemoryLayout<GLuint>.size), GLenum(GL_UNSIGNED_INT), indices)
        
        self.myContext.presentRenderbuffer(Int(GL_RENDERBUFFER))
        
    }
    
    
//    加载shader
    fileprivate func loadShaders(_ vert: String, _ frag: String) -> GLuint?{

        var programe: GLuint = glCreateProgram()
        
        let vertShader = compileShader(GLenum(GL_VERTEX_SHADER), vert) ?? 0
        let fragShader = compileShader(GLenum(GL_FRAGMENT_SHADER), frag) ?? 0
        
        glAttachShader(programe, vertShader)
        glAttachShader(programe, fragShader)
        
        glDeleteShader(vertShader)
        glDeleteShader(fragShader)
        
        glLinkProgram(programe)
        
        var linkStatus = GLint()
        glGetProgramiv(programe, GLenum(GL_LINK_STATUS), &linkStatus)
        if linkStatus == GL_FALSE {
            var message = [GLchar].init(repeating: GLchar(), count: 512)
            glGetProgramInfoLog(programe, GLsizei(MemoryLayout<GLchar>.size*512), UnsafeMutablePointer(bitPattern: 0), &message[0])
            let messageString = NSString(utf8String: message)
            print("program link failed error: \(messageString)")
            return 0
        }
        
        print("program link success")
        glUseProgram(programe)
       
        
        return programe
        
    }
    
//    编译shader
    fileprivate func compileShader(_ type: GLenum, _ file: String)->GLuint?{
        
        let shader = glCreateShader(type)
        
        guard let content = try? String(contentsOfFile: file, encoding: .utf8) else{
            print("content is nil")
            return nil
        }
        
        content.withCString { (pointer) in
            var source: UnsafePointer<GLchar>? = pointer
            glShaderSource(shader, 1, &source, nil)
        }
       
        glCompileShader(shader)
        
        return shader
    }
}
