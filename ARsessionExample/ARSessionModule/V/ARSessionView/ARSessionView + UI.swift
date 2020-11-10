//
//  ARSessionView + UI.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 10.11.2020.
//

import UIKit
import RealityKit
import TinyConstraints

/// Work with constraints
extension ARSessionView {
    
    func setupView() {
        self.backgroundColor = .black
        self.addSubview(self.arView)
        arView.edgesToSuperview()
        
        self.addSubview(functionalButtonsStack)
        self.functionalButtonsStack.addArrangedSubview(settingsButton)
    }
    
    func makeArView () -> ARView {
        let view = ARView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
        view.automaticallyConfigureSession = false
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return view
    }
    
    func makeFunctionalButton (sfSymbolName: String) -> UIButton {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        let segmentedControlSymbolsConfig = UIImage.SymbolConfiguration(pointSize: 35, weight: .light, scale: .medium)
        let titleImage = UIImage(systemName: sfSymbolName, withConfiguration: segmentedControlSymbolsConfig)!.withTintColor(.white, renderingMode: .alwaysOriginal)
        button.setImage(titleImage, for: .normal)
        button.alpha = 0.7
        return button
    }
    
    func makeFunctionalButtonsStack() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .fill
        return stack
    }
}
