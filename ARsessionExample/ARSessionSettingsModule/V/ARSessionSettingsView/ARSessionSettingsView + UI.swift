//
//  ARSessionSettingsView + UI.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 10.11.2020.
//

import Foundation

extension ARSessionSettingsView {
    func setupView() {
        self.backgroundColor = .systemGray5
        
        self.addSubview(closeButton)
        
        self.addSubview(titleLabel)
        titleLabel.text = "Settings"
        
        self.addSubview(collectionView)
        collectionView.backgroundColor = self.backgroundColor
    }
}
