//
//  ViewController.swift
//  13_分屏滤镜_Swift
//
//  Created by 陈嘉琳 on 2020/8/8.
//  Copyright © 2020 CJL. All rights reserved.
//

import UIKit
import GLKit

struct SenceVertex {
    var positionCoord: GLKMatrix3
    var textureCoord: GLKMatrix2
}

class ViewController: UIViewController {
    
    fileprivate var vertices: [GLfloat] = []
//    上下文
    fileprivate var context: EAGLContext!
//    用于刷新屏幕
    fileprivate var displayLink: CADisplayLink!
//    开始的时间戳
    fileprivate var startTimeInterval: TimeInterval! = 0
//    着色器程序
    fileprivate var program: GLuint! = 0
//    顶点缓存
    fileprivate var vertexBuffer: GLuint! = 0
//    纹理ID
    fileprivate var textureID: GLuint! = 0

    override func viewDidLoad() {
        super.viewDidLoad()
//        1、设置背景颜色
        self.view.backgroundColor = UIColor.black
        
//        2、创建滤镜工具栏
        setupFilterBar()
        
//        3、滤镜处理初始化
        filterInit()
        
//        4、开始一个滤镜位置
        startFilterAnimation()
        
    }


}

//MARK:--- setup
extension ViewController{
    fileprivate func setupFilterBar(){
        let width = UIScreen.main.bounds.size.width
        let height: CGFloat = 100
        let y = UIScreen.main.bounds.size.height-height
        let filterBar: FilterBar = FilterBar(frame: CGRect(x: 0, y: y, width: width, height: height))
        self.view.addSubview(filterBar)
        filterBar.backgroundColor = UIColor.white
        
        filterBar.itemList = ["无", "灰度", "颠倒", "正方形马赛克", "六边形马赛克", "三角形马赛克"]
        
        filterBar.didScrollToIndex = {[unowned self](bar, index) in
            
            print("select index : \(index)")
            
            switch index {
            case 0:
                self.setupNormalShaderProgram()
            case 1:
                self.setupGrayShaderProgram()
            case 2:
                self.setupReversalShaderProgram()
            case 3:
                self.setupMosaicShaderProgram()
            case 4:
                self.setupHexagonMosaicShaderProgram()
            default:
                self.setupTriangularMosaicShaderProgram()
            }
            
            
//            开始滤镜效果
            self.startFilterAnimation()
            
        }
        
    }
}

//MARK:--- Init
extension ViewController{
    fileprivate func filterInit(){
        
//        1、设置上下文
        setupContext()
        
//        2、创建图层 & 绑定缓存区
        setupLayer()
        
//        3、设置顶点数据
        setupVertexData()
        
//        4、设置纹理
        setupTexture()
        
//        5、设置视口
        glViewport(0, 0, drawableWidth(), drawableHeight())
        
//        6、设置默认着色器
        setupNormalShaderProgram()
    }
    
    private func setupContext(){
        self.context = EAGLContext(api: .openGLES2)
        EAGLContext.setCurrent(context)
    }
    
    private func setupLayer(){
        let layer = CAEAGLLayer()
        layer.frame = CGRect(x: 0, y: 100, width: self.view.frame.size.width, height: self.view.frame.size.width)
        layer.contentsScale = UIScreen.main.scale
        self.view.layer.addSublayer(layer)
        
//        绑定渲染缓存区/帧缓存无
        bindRenderLayer(layer)
    }
    
    private func  bindRenderLayer(_ layer: CAEAGLLayer){
        //1.渲染缓存区,帧缓存区对象
        var renderBuffer = GLuint()
        var frameBuffer = GLuint()
        
        //2.获取帧渲染缓存区名称,绑定渲染缓存区以及将渲染缓存区与layer建立连接
        glGenRenderbuffers(1, &renderBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), renderBuffer)
        context.renderbufferStorage(Int(GL_RENDERBUFFER), from: layer)
        
        //3.获取帧缓存区名称,绑定帧缓存区以及将渲染缓存区附着到帧缓存区上
        glGenFramebuffers(1, &frameBuffer)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), frameBuffer)
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), renderBuffer)
    }
    
    
    private func setupVertexData(){
        //1、开辟顶点数组（开辟空间）
//        let verticesSize = MemoryLayout<SenceVertex>.size*4
//        self.vertices = UnsafeMutablePointer<SenceVertex>.allocate(capacity: verticesSize)
        self.vertices = [
            -1, 1, 0,   0, 1,
            -1,-1,0,    0,0,
            1,  1,0,    1,1,
            1,-1,0,     1,0,
        ]
        
//        2、添加顶点数据：初始化4个顶点坐标 & 纹理坐标
        var vertexBuffer = GLuint()
        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLfloat>.size*vertices.count, vertices, GLenum(GL_STATIC_DRAW))
        
        self.vertexBuffer = vertexBuffer
    }
    
    private func setupTexture(){
        let filePath = Bundle.main.path(forResource: "mouse", ofType: "jpg") ?? ""
        let image = UIImage(contentsOfFile: filePath)
        
        self.textureID = createTextureWithImage(image!)
    }
    
    private func createTextureWithImage(_ image: UIImage) -> GLuint{
//        1、将UIImage转换为CGImageRef & 判断图片是否转换成功
        guard let cgImageRef = image.cgImage else{
            print("failed to load image")
            exit(1)
        }
//        2、获取图片的大小：宽和高
        let width = cgImageRef.width
        let height = cgImageRef.height
        
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        
        var colorSpace = cgImageRef.colorSpace
//        3、获取图片的字节数:宽*高*4（RGBA）
        let imageData = UnsafeMutablePointer<GLubyte>.allocate(capacity:MemoryLayout<GLubyte>.size*width*height*4)
//        4、创建上下文
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        var context = CGContext(data: imageData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width*4, space: colorSpace!, bitmapInfo: cgImageRef.bitmapInfo.rawValue)
//        翻转
        context?.translateBy(x: 0, y: CGFloat(height))
        context?.scaleBy(x: 1.0, y: -1.0)
        colorSpace = nil
        context?.clear(rect)
        
//        绘制图片
        context?.draw(cgImageRef, in: rect)
        UIGraphicsEndImageContext()
        
//        设置图片纹理
//        5、获取图片纹理ID
        var textureID = GLuint()
        glGenTextures(1, &textureID)
        glBindTexture(GLenum(GL_TEXTURE_2D), textureID)
        
//        6、载入纹理2D数据
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(width), GLsizei(height), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), imageData)
        
//        7、设置纹理属性
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
        
//        8、绑定纹理
        glBindTexture(GLenum(GL_TEXTURE_2D), 0)
        
//        9、释放
        context = nil
        free(imageData)
        
        return textureID
    }
    
    fileprivate func drawableWidth() -> GLint{
        var backingWidth = GLint()
        glGetRenderbufferParameteriv(GLenum(GL_RENDERBUFFER), GLenum(GL_RENDERBUFFER_WIDTH), &backingWidth)
        return backingWidth
   }
   
    fileprivate func  drawableHeight() -> GLint{
        var backingHeight = GLint()
        glGetRenderbufferParameteriv(GLenum(GL_RENDERBUFFER), GLenum(GL_RENDERBUFFER_HEIGHT), &backingHeight)
        return backingHeight
   }
    
}

//MARK:--- Animation
extension ViewController{
    fileprivate func startFilterAnimation(){
//        1、判断定时器是否为空
        if (displayLink != nil) {
            self.displayLink.invalidate()
            self.displayLink = nil
        }
        
//        2、设置定时器方法
        self.startTimeInterval = 0
        self.displayLink = CADisplayLink(target: self, selector: #selector(timeAnimation))
        
//        3、将定时器添加到runloop中
        self.displayLink.add(to: RunLoop.main, forMode: .common)
    }
    
    @objc private func timeAnimation(){
//        1、获取当前的时间戳
        if self.startTimeInterval != 0 {
            self.startTimeInterval = self.displayLink.timestamp
        }
        
//        2、使用program & 绑定buffer
        glUseProgram(program)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        
//        3、传入时间
        let current = displayLink.timestamp - startTimeInterval
        let time = glGetUniformLocation(program, "Time")
        glUniform1f(time, GLfloat(current))
        
//        4、清除画布
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        glClearColor(1, 1, 1, 1)
        
//        5、重绘 & 渲染到屏幕上
        glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, 4)
        context.presentRenderbuffer(Int(GL_RENDERBUFFER))
        
        
    }
}


//MARK:--- Shader
extension ViewController{
    fileprivate func setupNormalShaderProgram(){
        setupShaderProgramWithName("Normal")
    }
    
    fileprivate func setupGrayShaderProgram(){
        setupShaderProgramWithName("Gray")
        
    }
    fileprivate func setupReversalShaderProgram(){
        setupShaderProgramWithName("Reversal")
        
    }
    fileprivate func setupMosaicShaderProgram(){
        setupShaderProgramWithName("Mosaic")
    }
    fileprivate func setupHexagonMosaicShaderProgram(){
        setupShaderProgramWithName("HexagonMosaic")
    }
    fileprivate func setupTriangularMosaicShaderProgram(){
        setupShaderProgramWithName("TriangularMosaic")
    }
    
//    初始化着色器程序：公共的着色器传递数据方法
    private func setupShaderProgramWithName(_ name: String){
//        1、获取program & 使用program
        let program = programWithShaderName(name)
        glUseProgram(program)
        
//        2、数据传递
        let positionSlot = glGetAttribLocation(program, "Position")
        let textCoordSlot = glGetAttribLocation(program, "TextureCoords")
        let textureSlot = glGetAttribLocation(program, "Texture")
        
        glEnableVertexAttribArray(GLuint(positionSlot))
        glVertexAttribPointer(GLuint(positionSlot), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), Int32(MemoryLayout<GLfloat>.size)*5, UnsafeMutablePointer(bitPattern: 0))
        
        glEnableVertexAttribArray(GLuint(textCoordSlot))
        glVertexAttribPointer(GLuint(textCoordSlot), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), Int32(MemoryLayout<GLfloat>.size)*5, UnsafeMutablePointer(bitPattern: MemoryLayout<GLfloat>.size*3))
        
//        3、激活纹理
        glActiveTexture(GLenum(GL_TEXTURE0))
        glBindTexture(GLenum(GL_TEXTURE_2D), textureID)
        glUniform1i(textureSlot, 0)
        
//        4、保存program
        self.program = program
    }
}

//MARK:--- Shader compile and link
extension ViewController{
    fileprivate func programWithShaderName(_ shaderName: String) -> GLuint{
//        1、编译着色器
        let vertexShader = compileShaderWithName(shaderName, GLenum(GL_VERTEX_SHADER))
        let fragmentShader = compileShaderWithName(shaderName, GLenum(GL_FRAGMENT_SHADER))
        
//        2、创建program & 着色器附着到program
        let program = glCreateProgram()
        glAttachShader(program, vertexShader)
        glAttachShader(program, fragmentShader)
        
//        3、链接program
        glLinkProgram(program)
        
//        4、检查链接状态
        var linkStatus = GLint()
        glGetProgramiv(program, GLenum(GL_LINK_STATUS), &linkStatus)
        if linkStatus == GL_FALSE {
            var message = [GLchar].init(repeating: GLchar(), count: 512)
            glGetProgramInfoLog(program, GLsizei(MemoryLayout<GLchar>.size*512), UnsafeMutablePointer(bitPattern: 0), &message[0])
            let messageString = String(utf8String: message)
            print("program link 失败：\(messageString)")
            exit(1)
        }
        print("program link success")
        
        return program
    }
    
    private func compileShaderWithName(_ name: String, _ type: GLenum) -> GLuint{
//        1、获取文件路径
        let shaderPath = Bundle.main.path(forResource: name, ofType: type == GL_VERTEX_SHADER ? "vsh" : "fsh")
        guard let shaderString = try? String(contentsOfFile: shaderPath!, encoding: .utf8) else{
            print("读取shader失败")
            exit(1)
        }
        
//        2、创建shader
        let shader = glCreateShader(type)
        
//        3、将oc字符串转换为c字符串 & 获取shader source
        shaderString.withCString { (pointer) in
            var source: UnsafePointer<GLchar>? = pointer
            glShaderSource(shader, 1, &source, nil)
        
        }
        
//        4、编译shader
        glCompileShader(shader)
        
//        5、获取编译状态
        var compileStatus = GLint()
        glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &compileStatus)
        if compileStatus == GL_FALSE {
            var message = [GLchar].init(repeating: GLchar(), count: 512)
            glGetShaderInfoLog(shader, GLsizei(MemoryLayout<GLchar>.size*512), UnsafeMutablePointer(bitPattern: 0), &message[0])
            let messageString = String(utf8String: message)
            print("shader编译失败：\(messageString)")
            exit(1)
        }
        
//        6、返回shader
        return shader
        
       
    }
}


