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
        imageView.layer.cornerRadius = SettingsApp.sizeUnit / 8
        imageView.tintColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
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
            label.textColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
            label.numberOfLines = 1
        case .two:
            label.font = UIFont(name: "PingFangHK-Regular", size: 14)
            label.textColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
            label.numberOfLines = 1
        case .three:
            label.font = UIFont(name: "PingFangHK-Light", size: 14)
            label.textColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
            label.numberOfLines = 0
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
        imageView.height(to: self, multiplier: 1.00, relation: .equal)
        imageView.widthToHeight(of: imageView, multiplier: 1.0, relation: .equal)
        
        // rightView
        rightView.centerY(to: imageView)
        rightView.rightToSuperview(offset: -sizeUnit * 3)
        rightView.height(to: imageView, multiplier: 0.5)
        rightView.widthToHeight(of: rightView, multiplier: 1.0)

        // labelsVerticalStack
        labelsVerticalStack.leftToRight(of: imageView, offset: sizeUnit / 2)
        labelsVerticalStack.topToSuperview()
        labelsVerticalStack.rightToLeft(of: rightView, offset: sizeUnit / 2)
        labelsVerticalStack.bottomToSuperview()
    }
    
    func makeAccessorySwitch() -> PWSwitch {
        let uiSwitch = PWSwitch (frame: CGRect(x: 0, y: 0, width: 50, height: 26))
        uiSwitch.translatesAutoresizingMaskIntoConstraints = false
        uiSwitch.thumbDiameter = sizeUnit
        uiSwitch.cornerRadius = 10 / 1.5
        uiSwitch.tintColor = .systemGray
        uiSwitch.shouldFillOnPush = true
        uiSwitch.trackOnBorderColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
        uiSwitch.trackOnFillColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        uiSwitch.thumbOnFillColor = .systemGray5
        uiSwitch.thumbOffFillColor = .systemGray5
        return uiSwitch
    }
}

enum LabelLevel : String {
    case one, two, three
}
