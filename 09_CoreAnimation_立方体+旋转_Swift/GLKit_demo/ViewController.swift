 //
 //  ViewController.swift
 //  GLKit_demo
 //
 //  Created by  on 2020/7/25.
 //

 import UIKit


 class ViewController: UIViewController{
     

     override func viewDidLoad() {
         super.viewDidLoad()
         
         self.view.backgroundColor = UIColor.white
         
        
     }
    
    @IBAction func btnClick(_ sender: Any) {
        
        let vc = CAViewController.init()
        self.present(vc, animated: true, completion: nil)
        
    }
    
     
 }


