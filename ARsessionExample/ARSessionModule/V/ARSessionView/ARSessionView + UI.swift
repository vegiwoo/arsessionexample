//
//  ARSessionView + UI.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 10.11.2020.
//

import UIKit
import ARKit
import RealityKit
import TinyConstraints
import FocusEntity

/// Work with constraints
extension ARSessionView {
    
    func setupView() {
        self.backgroundColor = .black
        self.addSubview(self.arView)
        arView.edgesToSuperview()
        
        changingStackFunctionality()
    }
    
    func makeArView () -> CustomARView {
        let view = CustomARView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        view.automaticallyConfigureSession = false
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.focusEntity.isEnabled = true
        return view
    }
    
    func makeCoachingOverlayView(goal: ARCoachingOverlayView.Goal) -> ARCoachingOverlayView {
        let coachingOverlayView = ARCoachingOverlayView()
        coachingOverlayView.translatesAutoresizingMaskIntoConstraints = false
        coachingOverlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlayView.activatesAutomatically = true
        coachingOverlayView.goal = goal
        return coachingOverlayView
    }
    
    func makeFunctionalButton (sfSymbolName: String) -> UIButton {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        let segmentedControlSymbolsConfig = UIImage.SymbolConfiguration(pointSize: 35, weight: .bold, scale: .default)
        let titleImage = UIImage(systemName: sfSymbolName, withConfiguration: segmentedControlSymbolsConfig)!.withTintColor(.white, renderingMode: .alwaysOriginal)
        button.setImage(titleImage, for: .normal)
        button.alpha = 0.7
        return button
    }
    
    func makeFunctionalButtonsStack(uiviews: [UIView]) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center
        
        for view in uiviews {
            stack.addArrangedSubview(view)
        }
        
        return stack
    }

    func changingStackFunctionality() {
        
        var initialButtonStackEdgesToSuperview  : Constraints?
        var placingButtonStackEdgesToSuperview  : Constraints?
        var editingButtonStackEdgesToSuperview  : Constraints?

        DispatchQueue.main.async {
        
            //Filling  stack
            switch self.presentationMode {
            case .initial:
                
                self.detectPlacementPointForTargetShape = false
                
                UIView.animate(withDuration: 0.7) {
                    
                    placingButtonStackEdgesToSuperview?.deActivate()
                    editingButtonStackEdgesToSuperview?.deActivate()
                    
                    if let placingButtonStack = self.placingButtonStack, self.subviews.contains(placingButtonStack) {
                        placingButtonStack.removeFromSuperview()
                    }
                    if let editingButtonStack = self.editingButtonStack, self.subviews.contains(editingButtonStack) {
                        editingButtonStack.removeFromSuperview()
                    }
    
                    self.placingButtonStack = nil
                    self.editingButtonStack = nil
                    
                    self.initialButtonStack = self.makeFunctionalButtonsStack(uiviews: [self.modelButton, self.settingsButton])
                    self.addSubview(self.initialButtonStack!)
                    initialButtonStackEdgesToSuperview = self.initialButtonStack!.edgesToSuperview(excluding: .top, insets: .init(top: 0, left: 50, bottom: 15, right: 50), relation: .equal, priority: .defaultHigh, isActive: true, usingSafeArea: true)
                    
                    // focusEntity
                    //if self.arView.focusEntity.isEnabled {self.arView.focusEntity.isEnabled.toggle()}
                    
                    // buttons targets
                    // modelButton
                    self.modelButton.removeTarget(nil, action: nil, for: .allEvents)
                    self.modelButton.addTarget(self, action: #selector(self.modelButtonTapHandler), for: .touchUpInside)
                    
                    // settingsButton
                    self.settingsButton.removeTarget(nil, action: nil, for: .allEvents)
                    self.settingsButton.addTarget(self, action: #selector(self.settingsButtonTapHandler), for: .touchUpInside)
                }
            case .placing:
                
                self.detectPlacementPointForTargetShape = true
                
                UIView.animate(withDuration: 0.7) {
                    initialButtonStackEdgesToSuperview?.deActivate()
                    editingButtonStackEdgesToSuperview?.deActivate()
                    
                    if let initialButtonStack = self.initialButtonStack, self.subviews.contains(initialButtonStack) {
                        initialButtonStack.removeFromSuperview()
                    }
                    if let editingButtonStack = self.editingButtonStack, self.subviews.contains(editingButtonStack) {
                        editingButtonStack.removeFromSuperview()
                    }
                    self.initialButtonStack = nil
                    self.editingButtonStack = nil
                    
                    self.placingButtonStack = self.makeFunctionalButtonsStack(uiviews: [self.succsessButton, self.canceledButton])
                    self.addSubview(self.placingButtonStack!)
                    placingButtonStackEdgesToSuperview =  self.placingButtonStack!.edgesToSuperview(excluding: .top, insets: .init(top: 0, left: 50, bottom: 15, right: 50), relation: .equal, priority: .defaultHigh, isActive: true, usingSafeArea: true)
                    
                    // focusEntity
                    //if !self.arView.focusEntity.isEnabled {self.arView.focusEntity.isEnabled.toggle()}

                    // buttons targets
                    // succsessButton
                    self.succsessButton.removeTarget(nil, action: nil, for: .allEvents)
                    self.succsessButton.addTarget(self, action: #selector(self.successButtonPlacing(sender:)), for: .touchUpInside)
                    // canceledButton
                    self.canceledButton.removeTarget(nil, action: nil, for: .allEvents)
                    self.canceledButton.addTarget(self, action: #selector(self.cancelButtonPlacing), for: .touchUpInside)
                }

            case .editing:
                
                self.detectPlacementPointForTargetShape = false
                
                UIView.animate(withDuration: 0.7) {
                    initialButtonStackEdgesToSuperview?.deActivate()
                    placingButtonStackEdgesToSuperview?.deActivate()
                    
                    if let initialButtonStack = self.initialButtonStack, self.subviews.contains(initialButtonStack) {
                        initialButtonStack.removeFromSuperview()
                    }
                    if let placingButtonStack = self.placingButtonStack, self.subviews.contains(placingButtonStack) {
                        placingButtonStack.removeFromSuperview()
                    }
                    
                    self.editingButtonStack = self.makeFunctionalButtonsStack(uiviews: [self.succsessButton, self.trashButton])
                    
                    
                    self.addSubview(self.editingButtonStack!)
                    editingButtonStackEdgesToSuperview = self.editingButtonStack!.edgesToSuperview(excluding: .top, insets: .init(top: 0, left: 50, bottom: 15, right: 50), relation: .equal, priority: .defaultHigh, isActive: true, usingSafeArea: true)
                    
                    // focusEntity
                    //if self.arView.focusEntity.isEnabled {self.arView.focusEntity.isEnabled.toggle()}
                    
                    // buttons targets
                    self.succsessButton.removeTarget(nil, action: nil, for: .allEvents)
                    self.succsessButton.addTarget(self, action: #selector(self.successButtonEditing(sender:)), for: .touchUpInside)
                    
                    self.trashButton.removeTarget(nil, action: nil, for: .allEvents)
                    self.trashButton.addTarget(self, action: #selector(self.trashButtonEditing(sender:)), for: .touchUpInside)
                }
            case .none:
                break
            }
        }
    }
}
