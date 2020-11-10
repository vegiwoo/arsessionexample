//
//  ARSessionSettingsVM.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 10.11.2020.
//

import UIKit
import Combine

protocol ARSessionSettingsVMDelegate : class {
    func passingNewSettingsARSession(options: ARSessionSettingsOptions)
}

protocol ARSessionSettingsVM {
    var updateViewData: ((ARSessionSettingsData) -> ())? { get set }
    var delegate: ARSessionSettingsVMDelegate? { get set }
    func createLayout() -> UICollectionViewLayout
    func receivingInitialData()
}

class ARSessionSettingsVMImplement : ARSessionSettingsVM{

    var updateViewData: ((ARSessionSettingsData) -> ())?
    
    var currentOptionsOfSession : [ARSessionSettingsOptions]?
    
    // MARK: Publishers and subscribers
    private var arSessionSettingsViewEvent : ARSessionSettingsViewEvent!
    private var arSessionSettingsViewEventSubscriber : AnyCancellable?
    
    weak var delegate: ARSessionSettingsVMDelegate?
    
    init(options : [ARSessionSettingsOptions], arSessionSettingsViewEvent: ARSessionSettingsViewEvent) {
        self.arSessionSettingsViewEvent = arSessionSettingsViewEvent
        self.currentOptionsOfSession = options
        self.subscribe()
    }
    
    deinit {
        self.unsSubscribe()
    }
    
    func subscribe() {
        self.arSessionSettingsViewEventSubscriber = arSessionSettingsViewEvent.publisherSettingsOptions.sink{options in
            self.delegate?.passingNewSettingsARSession(options: options)
        }
        
    }
    
    func unsSubscribe() {
        arSessionSettingsViewEventSubscriber?.cancel()
    }
    
    func createLayout() -> UICollectionViewLayout {
        
        let sizeUnit = SettingsApp.sizeUnit
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: sizeUnit / 8, leading: sizeUnit / 8, bottom: sizeUnit / 8, trailing: sizeUnit / 8)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .absolute(SettingsApp.horizontalCellHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitems: [item])
       
        let section = NSCollectionLayoutSection(group: group)
        
        // Supplementary header view setup
        let headerFooterSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(SettingsApp.hightTextFieldsAndButtons / 2)
        )
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerFooterSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [sectionHeader]
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    func receivingInitialData() {
        if let options = currentOptionsOfSession {
            self.updateViewData?(.success(options: options))
        }
    }
}
