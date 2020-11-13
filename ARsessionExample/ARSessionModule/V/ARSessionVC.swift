//  ARSessionVC.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 10.11.2020.

import UIKit
import RealityKit
import ARKit
import SwiftUI
import Combine
import FocusEntity

//class Model {
//    let modelName : String
//    let modelImage : UIImage
//    var modelEntity : ModelEntity?
//
//    private var cancellable : AnyCancellable? = nil
//
//    init(modelName : String) {
//        self.modelName = modelName
//        self.modelImage = UIImage(named: modelName)!
//
//        let fileName = modelName.appending(".usdz")
//
//        self.cancellable = ModelEntity.loadModelAsync(named: fileName)
//            .sink(receiveCompletion: { complition in
//                switch complition {
//                case .finished:
//                    print("DEBUG: Model success load with name \(self.modelName)")
//                case .failure(let error):
//                    print("DEBUG: Model \(self.modelImage) load with error \(error.localizedDescription)")
//                }
//            }, receiveValue: { modelEntity in
//                self.modelEntity = modelEntity
//            })
//
//    }
//}

//struct ARViewContainer : UIViewRepresentable {
//
//    @Binding var modelcConfirmedToPlacement: Model?
//
//    func makeUIView(context: Context) -> ARView {
//
//        let view = ARView(frame: .zero)
//        view.addCoaching()
//        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        view.debugOptions = [.showPhysics]
//
//
//        let config = ARWorldTrackingConfiguration()
//        config.planeDetection = [.horizontal]
//        config.environmentTexturing = .automatic
//
//        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
//            config.sceneReconstruction = .mesh
//        }
//
//        view.session.run(config, options: [])
//        return view
//
//        //return CustomARView(frame: .zero)
//    }
//
//
//    func updateUIView(_ uiView: ARView, context: Context) {
//        if let model = self.modelcConfirmedToPlacement {
//            if let modelEntity = model.modelEntity {
//
////                //parentEntity
////                let parentEntity = ModelEntity()
////                parentEntity.addChild(modelEntity)
////                let entityBounds = modelEntity.visualBounds(relativeTo: parentEntity)
//
//                let anchorEntity = AnchorEntity(plane: .any)
//                anchorEntity.addChild(modelEntity.clone(recursive: true))
//                modelEntity.generateCollisionShapes(recursive: true)
//                uiView.installGestures([.all], for: modelEntity)
//                uiView.scene.addAnchor(anchorEntity)
//
////                parentEntity.collision = CollisionComponent(shapes: [ShapeResource.generateBox(size: entityBounds.extents).offsetBy(translation: entityBounds.center)])
////                uiView.installGestures([.rotation, .scale, .translation], for: parentEntity)
//
////
//
//                print("DEBUG: Adding model '\(model.modelName)' to scene.")
//            } else {
//                print("DEBUG: Unable load modelEntity for '\(model.modelName)'.")
//            }
//
//            DispatchQueue.main.async {
//                self.modelcConfirmedToPlacement = nil
//            }
//        }
//    }
//}

//class CustomARView : ARView {
//
//    var focusEntity : FocusEntity!
//
//    required init(frame frameRect: CGRect) {
//        super.init(frame: frameRect)
//        focusEntity = FocusEntity(on: self, style: .classic)
//        focusEntity.delegate = self
//        focusEntity.setAutoUpdate(to: true)
//
//        self.setupArView()
//    }
//
//    @objc required dynamic init?(coder decoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    func setupArView() {
//        let config = ARWorldTrackingConfiguration()
//        config.planeDetection = [.horizontal]
//        config.environmentTexturing = .automatic
//
//        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
//            config.sceneReconstruction = .mesh
//        }
//        self.session.run(config)
//    }
//}

//extension CustomARView : FocusEntityDelegate {
//    func toTrackingState() {
//        print("tracking")
//    }
//
//    func toInitializingState() {
//        print("initilazing")
//    }
//}


/// Class for ArSession controller 
class ARSessionVC : UIViewController {
    
    private var vm: ARSessionVM!
    private var arSessionView : ARSessionView!
    private var sessionViewEvent : ARSessionViewEvent!
    
//    struct ModelPickerView : View {
//
//        @Binding var isPlacementEnabled : Bool
//        @Binding var selectedModel: Model?
//
//        var models : [Model]
//
//        var body: some View {
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack(spacing: 30) {
//                    ForEach(0..<self.models.count){index in
//                        Button(action: {
//                            print("DEBUG: Select model with name \(self.models[index].modelName)")
//                            self.selectedModel = self.models[index]
//                            self.isPlacementEnabled = true
//
//                        }) {
//                            Image(uiImage: self.models[index].modelImage)
//                                .resizable()
//                                .frame(width: 80, height: 80, alignment: .center)
//                                .background(Color.white)
//                                .cornerRadius(12)
//                        }
//                        .buttonStyle(PlainButtonStyle())
//                    }
//                }
//            }
//            .padding(20)
//            .background(Color.black.opacity(0.5))
//        }
//    }
//
//    struct PlacementButtonsView : View {
//
//        @Binding var isPlacementEnabled : Bool
//        @Binding var selectedModel: Model?
//        @Binding var modelConfirmedToPlacement: Model?
//
//        var body: some View {
//            HStack{
//                let buttonSize: CGFloat = 50.0
//                let buttonOpacity: Double = 0.75
//                let buttonPadding: CGFloat = 20.0
//                // Confirm button
//                Button (action: {
//                    print("DEBUG: Press confirm button")
//                    self.modelConfirmedToPlacement = self.selectedModel
//                    self.resetPlacementParameters()
//                }) {
//                    Image(systemName: "checkmark")
//                        .frame(width: buttonSize, height: buttonSize, alignment: .center)
//                        .font(.title)
//                        .background(Color.white.opacity(buttonOpacity))
//                        .cornerRadius(buttonSize/2)
//                        .padding(buttonPadding)
//                }
//                // Cancel button
//                Button (action: {
//                    print("DEBUG: Press cancel button")
//                    self.resetPlacementParameters()
//                }) {
//                    Image(systemName: "xmark")
//                        .frame(width: buttonSize, height: buttonSize, alignment: .center)
//                        .font(.title)
//                        .background(Color.white.opacity(buttonOpacity))
//                        .cornerRadius(buttonSize/2)
//                        .padding(buttonPadding)
//                }
//            }
//        }
//
//        func resetPlacementParameters () {
//            self.isPlacementEnabled = false
//            self.selectedModel = nil
//        }
//    }

    // ----- //
//    struct ContentView : View {
//
//        @State private var isPlacementEnabled: Bool = false
//        @State private var selectedModel: Model?
//        @State private var modelConfirmedToPlacement: Model?
//
//        private var models : [Model] = {
//            let fm = FileManager.default
//            guard let path = Bundle.main.resourcePath, let files = try? fm.contentsOfDirectory(atPath: path) else { return [] }
//            var availableModels = [Model]()
//            for filename in files where filename.hasSuffix("usdz") {
//                let modelName = filename.replacingOccurrences(of: ".usdz", with: "")
//                availableModels.append(Model(modelName: modelName))
//            }
//            return availableModels.sorted(by: {$0.modelName < $1.modelName})
//        }()
//
//        var body: some View {
//            ZStack(alignment: .bottom) {
//                ARViewContainer(modelcConfirmedToPlacement: self.$modelConfirmedToPlacement).onTapGesture {
//
//
//                }
//
//                if self.isPlacementEnabled {
//                    PlacementButtonsView(isPlacementEnabled: self.$isPlacementEnabled,
//                                         selectedModel: self.$selectedModel,
//                                         modelConfirmedToPlacement: self.$modelConfirmedToPlacement)
//                } else {
//                    ModelPickerView(isPlacementEnabled: self.$isPlacementEnabled,
//                                    selectedModel: self.$selectedModel,
//                                    models: models)
//                }
//            }
//
//        }
//    }
//    let contentView = UIHostingController(rootView: ContentView())
    // ----- //
    
    init(vm: ARSessionVMImplement, arSessionViewEvent : ARSessionViewEvent) {
        self.vm = vm
        self.sessionViewEvent = arSessionViewEvent
        super.init(nibName: nil, bundle: nil)
        
//        // ----- //
//        addChild(contentView)
//        self.view.addSubview(contentView.view)
//        contentView.view.translatesAutoresizingMaskIntoConstraints = false
//        contentView.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
//        contentView.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
//        contentView.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
//        contentView.view.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
//        contentView.view.heightAnchor.constraint(equalToConstant: 100).isActive = true
//        // ----- //
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
        // ... 
    }
    
    func receivingNewSettingsForARSession(options: ARSessionSettingsOptions) {
        self.vm.receivingNewSettingsForARSession(option: options)
    }
}

extension ARSessionVC : ARSessionVMDelegate {
    func showSettingsPage() {
        // Get the current settings for ARSession
        let currentSessionOptons = self.vm.gettingCurrentSettingsFromARSession()
        
        // Create and call ARSessionSettingsVC
        if let arSessionSettingsVC = ModulesBuilder.createArSessionSettingsModule(options: currentSessionOptons, arSessionVMEvent: self.vm.arSessionVMEvent) as? ARSessionSettingsVC {
            let viewNC = UINavigationController(rootViewController: arSessionSettingsVC)
            viewNC.setNavigationBarHidden(true, animated: false)
            arSessionSettingsVC.modalPresentationStyle = .popover
            arSessionSettingsVC.arSessionVC = self
            present(viewNC, animated: true, completion: nil)
        }
    }
}

//struct ARSessionVC_Previews: PreviewProvider {
//    static var previews: some View {
//        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
//    }
//}
//

