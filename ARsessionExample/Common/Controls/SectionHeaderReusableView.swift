//
//  SectionHeaderReusableView.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 10.11.2020.
//

import UIKit

class SectionHeaderReusableView: UICollectionReusableView {
    static var reuseIdentifier: String {
        return String(describing: SectionHeaderReusableView.self)
    }
    
    // UIControls
    lazy var titleLabel = makeTitleLabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    
        self.addSubview(titleLabel)
        titleLabel.edgesToSuperview(excluding: .none, insets: .init(top: 0, left: SettingsApp.sizeUnit / 2, bottom: 0, right: -SettingsApp.sizeUnit / 2), relation: .equal, usingSafeArea: false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func makeTitleLabel() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "PingFangHK-Semibold", size: SettingsApp.sizeСalculation(value: 16))
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .systemGray
        label.textAlignment = .left
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return label
    }
}

