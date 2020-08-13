//
//  FilterBar.swift
//  13_分屏滤镜_Swift
//
//  Created by 陈嘉琳 on 2020/8/8.
//  Copyright © 2020 CJL. All rights reserved.
//

import UIKit


let CellIdentifier: String = "FilterBarCell"

class FilterBar: UIView {
    
    var didScrollToIndex:((FilterBar, Int)->Void) = {(filterBar, index) in}
    
    var itemList: [String]!
    
    fileprivate var collectionView: UICollectionView!
    
    fileprivate var collectionViewLayout: UICollectionViewFlowLayout!
    
    fileprivate var currentIndex: Int!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension FilterBar{
    fileprivate func commonInit(){
        
        createCollectionViewLayout()
        
        collectionView = UICollectionView(frame: self.bounds, collectionViewLayout: collectionViewLayout)
        self.addSubview(collectionView)
        
        collectionView.backgroundColor = UIColor.white
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(FilterBarCell.self, forCellWithReuseIdentifier: CellIdentifier)
    }
    
    fileprivate func createCollectionViewLayout(){
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        
        let itemW: CGFloat = 100
        let itemH: CGFloat = self.frame.size.height
        flowLayout.itemSize = CGSize(width: itemW, height: itemH)
        
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        flowLayout.scrollDirection = .horizontal
        
        collectionViewLayout = flowLayout
    }
    
    
}

extension FilterBar: UICollectionViewDelegate, UICollectionViewDataSource{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: FilterBarCell = collectionView.dequeueReusableCell(withReuseIdentifier: CellIdentifier, for: indexPath) as! FilterBarCell
        cell.title = itemList[indexPath.row]
        cell.isSelect = indexPath.row == currentIndex
        
        return cell;
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectIndex(indexPath)
    }
    
    fileprivate func selectIndex(_ indexPath: IndexPath){
        currentIndex = indexPath.row
        collectionView.reloadData()
        
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        
        didScrollToIndex(self, indexPath.row)
        
    }
}
