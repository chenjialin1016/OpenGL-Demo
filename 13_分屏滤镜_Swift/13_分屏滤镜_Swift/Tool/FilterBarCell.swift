//
//  FilterBarCell.swift
//  13_分屏滤镜_Swift
//
//  Created by 陈嘉琳 on 2020/8/8.
//  Copyright © 2020 CJL. All rights reserved.
//

import UIKit

class FilterBarCell: UICollectionViewCell {
    
    var title: String!{
        willSet{
            title = newValue
        }
    }
    var isSelect: Bool!{
        didSet{
            self.label.text = title
            self.label.backgroundColor = isSelect ? UIColor.black : UIColor.clear
            self.label.textColor = isSelect ? UIColor.white : UIColor.black
        }
    }
    
    fileprivate var label: UILabel! = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 15
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.frame = self.label.frame.insetBy(dx: 10, dy: 10)
    }
    
}

extension FilterBarCell{
    fileprivate func commonInit(){
        label.frame = self.bounds
        self.addSubview(self.label)
    }
    
}
