//
//  ARSessionSettingsVC.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 10.11.2020.
//

import UIKit

class ARSessionSettingsVC : UIViewController {
    
    private var arSessionSettingsView: ARSessionSettingsView!
    var vm : ARSessionSettingsVM!
    var arSessionSettingsViewEvent : ARSessionSettingsViewEvent!
    
    weak var arSessionVC: ARSessionVC?
    
    init(vm : ARSessionSettingsVMImplement,arSessionSettingsViewEvent : ARSessionSettingsViewEvent ) {
        self.vm = vm
        self.arSessionSettingsViewEvent = arSessionSettingsViewEvent
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.restorationIdentifier = "ARSessionSettingsVC"

        self.createView()
        self.updateView()
        self.addTargets()
        
        self.navigationController?.navigationBar.barTintColor = arSessionSettingsView.backgroundColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.vm.delegate = self
        self.vm.receivingInitialData()
    }
    
    fileprivate func createView() {
        let uiCollectionViewLayout = vm.createLayout()
        self.arSessionSettingsView = ARSessionSettingsView(frame: view.bounds, layout: uiCollectionViewLayout, arSessionSettingsViewEvent: self.arSessionSettingsViewEvent)
        self.view.addSubview(self.arSessionSettingsView)
        self.arSessionSettingsView.edgesToSuperview()
    }
    
    fileprivate func updateView() {
        vm.updateViewData = { [weak self] viewData in
            self?.arSessionSettingsView.viewData = viewData
        }
    }
    
    fileprivate func addTargets() {
        self.arSessionSettingsView.closeButton.addTarget(self, action: #selector(closeButtonTapHandler), for: .touchUpInside)
    }

    @objc fileprivate func closeButtonTapHandler (sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension ARSessionSettingsVC : ARSessionSettingsVMDelegate {
    func passingNewSettingsARSession(options: ARSessionSettingsOptions) {
        self.arSessionVC?.receivingNewSettingsForARSession(options: options)
    }
}
