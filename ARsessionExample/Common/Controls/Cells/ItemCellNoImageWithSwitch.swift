//  ItemCellNoImageWithSwitch.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 10.11.2020.

import UIKit

class ItemCellNoImageWithSwitch : BaseItemCell {
    
    override var reuseIdentifier: String? { return "ItemCellNoImageWithSwitch"}
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.info01Label = self.makeInfoLabel(level: .one)
        self.info03Label = self.makeInfoLabel(level: .three)
        self.labelsVerticalStack = self.makeLabelsVerticalStack(labels: [self.info01Label, self.info03Label])
        self.accessorySwitch = self.makeAccessorySwitch()
        
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupCell() {
        self.addSubview(labelsVerticalStack)
        self.addSubview(rightView)
        self.addSubview(accessorySwitch!)
        
        // rightView
        rightView.edgesToSuperview(excluding: .left, usingSafeArea: false)
        rightView.width(sizeUnit * 2)
        
        // labelsVerticalStack
        labelsVerticalStack.edgesToSuperview(excluding: .right, usingSafeArea: false)
        labelsVerticalStack.rightToLeft(of: rightView, offset: -sizeUnit / 3)
        
        // accessorySwitch
        accessorySwitch!.center(in: rightView)
    }
}
