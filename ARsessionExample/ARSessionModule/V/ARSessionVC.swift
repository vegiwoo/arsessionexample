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
        self.createView()
        self.updateView()
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
    
    func createView() {
        self.arSessionView = ARSessionView(frame: .zero, arSessionViewEvent: self.sessionViewEvent)
        self.view = self.arSessionView
    }
    
    func updateView() {
        self.vm.updateViewData = { [weak self] viewData in
            self?.arSessionView.viewData = viewData
        }
    }
}

extension ARSessionVC : ARSessionVMDelegate {
    
}
