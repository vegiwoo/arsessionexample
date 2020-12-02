//
//  ARSessionView + Gestures.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 02.12.2020.
//

import UIKit

// Work with gestures
extension ARSessionView {
    /// Add screen gesture recognizers related to `UITapGestureRecognizer`.
    func makeScreenUITapGestureRecognizers () {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapGestureRecognizerHandler(sender:)))
        arView.addGestureRecognizer(tapRecognizer)
    }
    
    /// Removes active gesture recognizers related to`UITapGestureRecognizer`.
    func killUITapGestureRecognizers () {
        arView.gestureRecognizers?.removeAll(where: {type(of: $0) == UITapGestureRecognizer.self})
    }
    
}
