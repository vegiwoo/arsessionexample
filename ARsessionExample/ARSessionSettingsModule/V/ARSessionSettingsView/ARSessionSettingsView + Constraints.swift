//
//  ARSessionSettingsView + Constraints.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 10.11.2020.
//

import Foundation

extension ARSessionSettingsView {
    func setupConstraints() {
        
        let sizeUnit = SettingsApp.sizeUnit
        
        // closeButton
        closeButton.rightToSuperview(offset: -sizeUnit/2)
        closeButton.topToSuperview(offset: sizeUnit)
        closeButton.height(sizeUnit * 2)
        closeButton.widthToHeight(of: closeButton, multiplier: 1.00)
        
        // titleLabel
        titleLabel.centerY(to: closeButton)
        titleLabel.leftToSuperview(offset: sizeUnit)
        titleLabel.topToSuperview(offset: sizeUnit)
        titleLabel.right(to: closeButton, offset: -sizeUnit)
        titleLabel.height(SettingsApp.horizontalCellHeight)
        
        // collectionView
        collectionView.edgesToSuperview(excluding: .top, insets: .init(top: 0, left: sizeUnit / 2, bottom: sizeUnit / 2, right: sizeUnit / 2), relation: .equal, priority: .defaultHigh, isActive: true, usingSafeArea: false)
        collectionView.topToBottom(of: titleLabel, offset: sizeUnit / 2)
    }
}
