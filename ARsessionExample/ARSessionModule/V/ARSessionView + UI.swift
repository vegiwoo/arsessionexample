//
//  ARSessionView + UI.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 10.11.2020.
//

import Foundation
import RealityKit
import TinyConstraints

/// Work with constraints
extension ARSessionView {
    
    func setupView() {
        self.backgroundColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
        self.addSubview(self.arView)
        arView.edgesToSuperview()
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
}
