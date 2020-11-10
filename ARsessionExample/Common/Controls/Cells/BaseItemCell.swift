//
//  BaseItemCell.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 10.11.2020.
//

import UIKit
import TinyConstraints
import PWSwitch

class BaseItemCell : UICollectionViewCell {
    
    static var reuseIdentifier: String { return "BaseItemCell" } // Overriding in subclass
    
    var sizeUnit : CGFloat = 20.0
    
    lazy var containerView : UIView = {
        let view = UIView()
        return view
    }()
    
    lazy var imageView : UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .systemGray
        imageView.layer.cornerRadius = 10
        return imageView
    }()
    
    var info01Label : UILabel?
    var info02Label : UILabel?
    var info03Label : UILabel?
    
    var labelsVerticalStack : UIStackView!
    
    var accessorySwitch : PWSwitch?
    
    lazy var rightView : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func makeInfoLabel(level: LabelLevel) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false

        switch level {
        case .one:
            label.font = UIFont(name: "PingFangHK-Medium", size: 14)
            label.textColor = #colorLiteral(red: 0.05882352963, green: 0.180392161, blue: 0.2470588237, alpha: 1)
        case .two:
            label.font = UIFont(name: "PingFangHK-Regular", size: 12)
            label.textColor = #colorLiteral(red: 0.1019607857, green: 0.2784313858, blue: 0.400000006, alpha: 1)
        case .three:
            label.font = UIFont(name: "PingFangHK-Light ", size: 10)
            label.textColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        }

        return label
    }
    
    func makeLabelsVerticalStack(labels: [UILabel?]) -> UIStackView {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.distribution = .fillProportionally
        stack.alignment = .fill

        for label in labels.compactMap({$0}) {
            stack.addArrangedSubview(label)
        }
        return stack
    }
    
    func setupCell() {
        self.addSubview(imageView)
        self.addSubview(labelsVerticalStack)
        self.addSubview(rightView)
        
        // imageView
        imageView.centerY(to: self)
        imageView.leftToSuperview(offset: sizeUnit / 2, relation: .equalOrLess)
        imageView.height(to: self, multiplier: 0.8, relation: .equalOrLess)
        imageView.widthToHeight(of: imageView, multiplier: 1.0, relation: .equal)
        
        // rightView
        rightView.centerY(to: imageView)
        rightView.rightToSuperview(offset: -sizeUnit)
        rightView.height(to: imageView, multiplier: 0.5)
        rightView.widthToHeight(of: rightView, multiplier: 1.0)
        
        // labelsVerticalStack
        labelsVerticalStack.leftToRight(of: imageView, offset: sizeUnit / 3)
        labelsVerticalStack.topToSuperview()
        labelsVerticalStack.rightToLeft(of: rightView, offset: sizeUnit / 3)
        labelsVerticalStack.bottomToSuperview()
    }
    
    func makeAccessorySwitch() -> PWSwitch {
        let uiSwitch = PWSwitch (frame: CGRect(x: 0, y: 0, width: 50, height: 26))
        uiSwitch.translatesAutoresizingMaskIntoConstraints = false
        uiSwitch.thumbDiameter = sizeUnit
        uiSwitch.cornerRadius = 10 / 1.5
        uiSwitch.tintColor = .systemGray
        return uiSwitch
    }
}

enum LabelLevel : String {
    case one, two, three
}
