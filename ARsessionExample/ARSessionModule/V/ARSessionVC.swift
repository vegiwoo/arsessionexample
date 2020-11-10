//  ARSessionVC.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 10.11.2020.

import UIKit

/// Class for ArSession controller 
class ARSessionVC : UIViewController {
    
    private var vm: ARSessionVM!
    private var arSessionView : ARSessionView!
    private var sessionViewEvent : ARSessionViewEvent!
    
    init(vm: ARSessionVMImplement, arSessionViewEvent : ARSessionViewEvent) {
        self.vm = vm
        self.sessionViewEvent = arSessionViewEvent
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.restorationIdentifier = "ARSessionVC"
        self.createView()
        self.updateView()
        self.addTargets()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.vm.delegate = self
        self.vm.createAndRunARSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.vm.delegate = nil
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    fileprivate func createView() {
        self.arSessionView = ARSessionView(frame: .zero, arSessionViewEvent: self.sessionViewEvent)
        self.view = self.arSessionView
    }
    
    fileprivate func updateView() {
        self.vm.updateViewData = { [weak self] viewData in
            self?.arSessionView.viewData = viewData
        }
    }
    
    fileprivate func addTargets() {
        self.arSessionView.settingsButton.addTarget(self, action: #selector(settingsButtonTapHandler), for: .touchUpInside)
    }
    
    // MARK: Action handlers
    @objc fileprivate func settingsButtonTapHandler(sender: UIButton) {
        
        // Get the current settings for ARSession
        let currentSessionOptons = self.vm.gettingCurrentSettingsFromARSession()
        
        // Create and call ARSessionSettingsVC
        if let arSessionSettingsVC = ModulesBuilder.createArSessionSettingsModule(options: currentSessionOptons) as? ARSessionSettingsVC {
            let viewNC = UINavigationController(rootViewController: arSessionSettingsVC)
            viewNC.setNavigationBarHidden(true, animated: false)
            arSessionSettingsVC.modalPresentationStyle = .popover
            arSessionSettingsVC.arSessionVC = self
            present(viewNC, animated: true, completion: nil)
        }
    }
    
    func receivingNewSettingsForARSession(options: ARSessionSettingsOptions) {
        self.vm.receivingNewSettingsForARSession(options: options)
    }
}

extension ARSessionVC : ARSessionVMDelegate {
    
}
