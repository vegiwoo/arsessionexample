//
//  ItemCellWithImageWithSwitch.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 10.11.2020.
//

import Foundation
import PWSwitch

class ItemCellWithImageWithSwitch : BaseItemCell {
    override var reuseIdentifier: String? { return "ItemCellWithImageWithSwitch"}
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.info01Label = self.makeInfoLabel(level: .one)
        self.info03Label = self.makeInfoLabel(level: .three)
        self.labelsVerticalStack = self.makeLabelsVerticalStack(labels: [self.info01Label, self.info03Label])
        self.accessorySwitch = makeAccessorySwitch()
        
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupCell() {
        self.addSubview(imageView)
        self.addSubview(labelsVerticalStack)
        self.addSubview(rightView)
        self.addSubview(accessorySwitch!)
        
        // imageView
        imageView.leftToSuperview()
        imageView.centerY(to: self)
        imageView.height(sizeUnit * 1.5, relation: .equalOrLess)
        imageView.widthToHeight(of: imageView)
        
        // rightView
        rightView.edgesToSuperview(excluding: .left, usingSafeArea: false)
        rightView.width(sizeUnit * 2)
        
        // labelsVerticalStack
        labelsVerticalStack.leftToRight(of: imageView, offset: sizeUnit / 2)
        labelsVerticalStack.topToSuperview()
        labelsVerticalStack.rightToLeft(of: rightView, offset: -sizeUnit / 2)
        labelsVerticalStack.bottomToSuperview()
        
        // accessorySwitch
        accessorySwitch!.center(in: rightView)
    }
}
