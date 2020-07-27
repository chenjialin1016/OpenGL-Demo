//
//  CAViewController.swift
//  GLKit_demo
//
//  Created by 陈嘉琳 on 2020/7/27.
//

import UIKit

let ScreenW = UIScreen.main.bounds.size.width

class CAViewController: UIViewController {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet var view0: UIView!
    @IBOutlet var view1: UIView!
    @IBOutlet var view2: UIView!
    @IBOutlet var view3: UIView!
    @IBOutlet var view4: UIView!
    @IBOutlet var view5: UIView!
    
    lazy var displayLink: CADisplayLink = {
        let link = CADisplayLink(target: self, selector: #selector(update))
        return link
    }()
    var angle: GLfloat = 0
    
    var faces: [UIView] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.containerView.backgroundColor = UIColor.black

        //添加面
        addFaces()
        
        //添加定时器
//        addCADisplayLink()
        
    }



}

extension CAViewController{
    
    fileprivate func addFaces(){
        faces = [view0, view1, view2, view3, view4, view5]
        
//        父view的layer图层
        var perspective: CATransform3D = CATransform3DIdentity
        perspective.m34 = -1.0 / 500.0
        perspective = CATransform3DRotate(perspective, -.pi/4, 1, 0, 0)
        perspective = CATransform3DRotate(perspective, -.pi/4, 0, 1, 0)
        self.containerView.layer.sublayerTransform = perspective
        
//        添加face1
        var transform = CATransform3DMakeTranslation(0, 0, 100)
        self.addFaceWithTransform(0, transform)
        
//        添加face2
        transform = CATransform3DMakeTranslation(100, 0, 0)
        transform = CATransform3DRotate(transform, .pi/2, 0, 1, 0)
        self.addFaceWithTransform(1, transform)
        
//        添加face3
        transform = CATransform3DMakeTranslation(0, -100, 0)
//        transform = CATransform3DRotate(transform, .pi/2, 1, 0, 0)
//        self.addFaceWithTransform(2, transform)
//
//        添加face4
        transform = CATransform3DMakeTranslation(0, 100, 0)
        transform = CATransform3DRotate(transform, -.pi/2, 1, 0, 0)
        self.addFaceWithTransform(3, transform)
//
//        添加face5
        transform = CATransform3DMakeTranslation(-100, 0, 0)
//        transform = CATransform3DRotate(transform, -.pi/2, 0, 1, 0)
        self.addFaceWithTransform(4, transform)
//
////        添加face6
//        transform = CATransform3DMakeTranslation(0, 0, -100)
//        transform = CATransform3DRotate(transform, .pi, 0, 1, 0)
//        self.addFaceWithTransform(5, transform)

    }
    
    private func addFaceWithTransform(_ index: Int, _ transform: CATransform3D){
//        获取face，并加入容器中
        let face = self.faces[index]
        self.containerView.addSubview(face)
        
//        将face视图放入容器的中心
        let containerSize = self.containerView.bounds.size
        face.center = CGPoint(x: containerSize.width/2, y: containerSize.height/2)
        
//        添加transform
        face.layer.transform = transform
        
    }
    
   
   fileprivate func addCADisplayLink(){
    self.displayLink.add(to: RunLoop.main, forMode: .common)
   }
   
   @objc fileprivate func update(){
    self.angle = (self.angle+5).truncatingRemainder(dividingBy: 360)
    let deg = self.angle * (.pi/180)
    var temp = CATransform3DIdentity
    temp = CATransform3DRotate(temp, CGFloat(deg), 0.3, 1, 0.7)
    
    self.containerView.layer.sublayerTransform = temp
   }
    

}
