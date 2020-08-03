//
//  CustomViewController.swift
//  GLKit_demo
//
//  Created by 陈嘉琳 on 2020/8/2.
//

import UIKit
import GLKit
import OpenGLES

class CustomViewController: GLKViewController {

    var mContext: EAGLContext!
    var mEffect: GLKBaseEffect!
    
    var count: Int = 0
    
    var xDegree: Float = 0
    var yDegree: Float = 0
    var zDegree: Float = 0
     
    var bX: Bool = false
    var bY: Bool = false
    var bZ: Bool = false
        
        var timer: DispatchSourceTimer!
//    var timer: Timer!

     override func viewDidLoad() {
         super.viewDidLoad()
         
         self.view.backgroundColor = UIColor.black
//        !!!!!必须设置代理，否则不执行
        self.delegate = self
         
//         新建图层
        setupContext()
        
//        渲染图层
        render()
     }
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glClearColor(0.3, 0.3, 0.3, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
        
        mEffect.prepareToDraw()
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei(self.count), GLenum(GL_UNSIGNED_INT), UnsafePointer(bitPattern: 0))
    }
    
    @IBAction func xClick(_ sender: Any) {
        bX = !bX
    }
    
    @IBAction func yClick(_ sender: Any) {
        bY = !bY
        
    }
    
    @IBAction func zClick(_ sender: Any) {
        bZ = !bZ

    }
    
    @objc func reDegree(){
        self.xDegree += 0.1 * (self.bX ? 1 : 0)
        self.yDegree += 0.1 * (self.bY ? 1 : 0)
        self.zDegree += 0.1 * (self.bZ ? 1 : 0)
    }

}

 extension CustomViewController{
     
     fileprivate func setupContext(){
        
        self.mContext = EAGLContext(api: .openGLES2)
        
        let view: GLKView = self.view as! GLKView
        
        view.context = self.mContext
        view.drawableColorFormat = .RGBA8888
        view.drawableDepthFormat = .format24
        
        EAGLContext.setCurrent(self.mContext)
 
        glEnable(GLenum(GL_DEPTH_TEST))
     }
     
    
    fileprivate func render(){
        let attrArr: [GLfloat] = [
            -0.5, 0.5, 0.0,      1.0, 0.0, 1.0,         0.0, 1.0,//左上0
            0.5, 0.5, 0.0,       1.0, 0.0, 1.0,         1.0, 1.0,//右上1
            -0.5, -0.5, 0.0,     1.0, 1.0, 1.0,         0.0, 0.0,//左下2
            
            0.5, -0.5, 0.0,      1.0, 1.0, 1.0,         1.0, 0.0,//右下3
            0.0, 0.0, 1.0,       0.0, 1.0, 0.0,         0.5, 0.5//顶点4
        ]
        
        let indices: [GLuint] = [
                    0, 3, 2,
                   0, 1, 3,
                   0, 2, 4,
                   0, 4, 1,
                   2, 3, 4,
                   1, 4, 3,
        ]
        
        self.count = MemoryLayout<GLuint>.size*indices.count / MemoryLayout<GLuint>.size
        
//        开辟顶点缓存区
        var buffer: GLuint = GLuint()
        glGenBuffers(1, &buffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), buffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLfloat>.size*attrArr.count, attrArr, GLenum(GL_STATIC_DRAW))
        
//        开辟索引缓存区
        var index: GLuint = GLuint()
        glGenBuffers(1, &index)
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), index)
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), MemoryLayout<GLfloat>.size*indices.count, indices, GLenum(GL_STATIC_DRAW))
        
//        使用顶点
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.position.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.position.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size*8), UnsafeMutablePointer(bitPattern: 0))
        
//        使用索引
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.color.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.color.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), Int32(MemoryLayout<GLfloat>.size)*8, UnsafeMutablePointer(bitPattern: MemoryLayout<GLfloat>.size*3))
        
//        -------使用纹理
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.texCoord0.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.texCoord0.rawValue), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), Int32(MemoryLayout<GLfloat>.size)*8, UnsafeMutablePointer(bitPattern: MemoryLayout<GLfloat>.size*6))
        
//        获取纹理路径
        let filePath = Bundle.main.path(forResource: "mouse", ofType: "jpg")
        guard let info: GLKTextureInfo = try? GLKTextureLoader .texture(withContentsOfFile: filePath!, options: [GLKTextureLoaderOriginBottomLeft: NSNumber(integerLiteral: 1)]) else {
            return
        }
        
//        着色器
        mEffect = GLKBaseEffect()
        mEffect.texture2d0.enabled = GLboolean(GL_TRUE)
        mEffect.texture2d0.name = info.name
        
//        投影矩阵
        let size = self.view.bounds.size
        let aspect = fabs(size.width / size.height)
        var projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90), Float(aspect), 0.1, 100.0)
        projectionMatrix = GLKMatrix4Scale(projectionMatrix, 1.0, 1, 1)
        mEffect.transform.projectionMatrix = projectionMatrix
        
//        模型视图矩阵
        var modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0, 0, -2.0)
        mEffect.transform.modelviewMatrix = modelViewMatrix
        
//        设置定时器
//        https://www.jianshu.com/p/fc04be41c698
        let seconds: Double = 0.1
        timer = DispatchSource.makeTimerSource()
        //循环执行，马上开始，间隔为1s,误差允许10微秒
        timer?.schedule(deadline: DispatchTime.now(), repeating: seconds, leeway: .milliseconds(10))
        timer.setEventHandler {
            self.xDegree += 0.1 * (self.bX ? 1 : 0)
            self.yDegree += 0.1 * (self.bY ? 1 : 0)
            self.zDegree += 0.1 * (self.bZ ? 1 : 0)
        }
        timer.resume()

    }

 }


extension CustomViewController: GLKViewControllerDelegate{
    func glkViewControllerUpdate(_ controller: GLKViewController) {
        var modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0, 0, -2.5)
        modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, xDegree)
        modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, yDegree)
        modelViewMatrix = GLKMatrix4RotateZ(modelViewMatrix, zDegree)

        mEffect.transform.modelviewMatrix = modelViewMatrix
    }
    
}
