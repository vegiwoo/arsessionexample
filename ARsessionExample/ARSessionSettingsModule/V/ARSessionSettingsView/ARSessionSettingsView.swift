//
//  ARSessionSettingsView.swift
//  ARsessionExample
//
//  Created by Dmitry Samartcev on 10.11.2020.
//

import UIKit
import Foundation
import Combine
import PWSwitch

class ARSessionSettingsView : UIView {
    var viewData : ARSessionSettingsData = .initial {
        didSet {
            setNeedsLayout()
        }
    }

    enum Section : Int, CaseIterable {
        case planeDetectionMode
        
        var name : String {
            switch self {
            case .planeDetectionMode:
                return "Plane detection mode".uppercased()
            }
        }
    }
    
    private var arSessionSettingsViewEvent: ARSessionSettingsViewEvent!
    
    // MARK: DataSource & DataSourceSnapshot
    typealias DataSource = UICollectionViewDiffableDataSource<Section, ARSessionSettingsOptions>
    typealias DataSourceSnapShot = NSDiffableDataSourceSnapshot<Section,ARSessionSettingsOptions>
    var datasource : DataSource!
    internal var snapshot = DataSourceSnapShot()
    
    // MARK: UIControls
    var layout: UICollectionViewLayout!
    var collectionView : UICollectionView!
    
    // MARK: View lifecircle
    init(frame: CGRect, layout: UICollectionViewLayout, arSessionSettingsViewEvent: ARSessionSettingsViewEvent) {
        self.layout = layout
        self.arSessionSettingsViewEvent = arSessionSettingsViewEvent
        super.init(frame: frame)
        
        self.setupView()
        self.setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        switch self.viewData {
        case .initial:
            break
        case .success(options: let options):
            DispatchQueue.main.async {
                self.applySnapshot(options: options)
            }
        }
    }
    
    
    
    func setupCollectionView(layout: UICollectionViewLayout) {
        self.collectionView =  UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.collectionView.backgroundColor = .systemGray5
        self.collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.collectionView.delegate = self
        
        // Register custom elements
        self.collectionView.register(SectionHeaderReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeaderReusableView.reuseIdentifier)
        self.collectionView.register(ItemCellWithImageWithSwitch.self, forCellWithReuseIdentifier: ItemCellWithImageWithSwitch.reuseIdentifier)
        
        // Configure DataSource
        self.datasource = configureCollectionViewDataSource()
    }
    
    func configureCollectionViewDataSource() -> DataSource {
        let dataSource = DataSource(collectionView: self.collectionView, cellProvider: { (collectionView, indexPath, option) -> UICollectionViewCell? in
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ItemCellWithImageWithSwitch.reuseIdentifier, for: indexPath) as! ItemCellWithImageWithSwitch
            
            self.configure(cell: cell, with: option)
            
            return cell
        })
        
        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader else {
                return nil
            }
            let view = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: SectionHeaderReusableView.reuseIdentifier,
                for: indexPath) as? SectionHeaderReusableView
            let section = self.datasource.snapshot().sectionIdentifiers[indexPath.section]
            view?.titleLabel.text = section.name
            return view
        }
        return dataSource
    }
    
    fileprivate func configure(cell: ItemCellWithImageWithSwitch, with option: ARSessionSettingsOptions) {
        
        // labels
        if let info01Label = cell.info01Label{
            info01Label.text = option.name
        }
        
        if let info03Label = cell.info03Label{
            info03Label.text = option.description
        }

        // accessorySwitch
        if let accessorySwitch = cell.accessorySwitch {
            accessorySwitch.setOn(option.isSelected, animated: true)
            accessorySwitch.addTarget(self, action: #selector(self.accessorySwitchValueChangeHandler), for: .valueChanged)
        }
        
    }
    
    func applySnapshot<T>(options: [T]) {
        
        snapshot = DataSourceSnapShot()
        
        let sections = Section.allCases
        snapshot.appendSections(sections)
        
        for section in sections {
            switch section {
            case .planeDetectionMode:
                if let options = options as? [ARSessionSettingsOptions] {
                    snapshot.appendItems(options.filter{$0.group == .planeDetectionMode}, toSection: ARSessionSettingsView.Section(rawValue: section.rawValue))
                }
            }
        }
    }
    
    @objc fileprivate func accessorySwitchValueChangeHandler (sender: PWSwitch) {
        if let cell = sender.superview as? ItemCellWithImageWithSwitch,
           let indexPath = collectionView.indexPath(for: cell),
           let option = datasource.itemIdentifier(for: indexPath) {
            
            option.isSelected.toggle()
            arSessionSettingsViewEvent.publish(options: option)
        }
    }
}

extension ARSessionSettingsView : UICollectionViewDelegate {
    
}

class ARSessionSettingsViewEvent {
    var publisherSettingsOptions: AnyPublisher<ARSessionSettingsOptions, Never> {
        subjectOptions.eraseToAnyPublisher()
    }
   
    private let subjectOptions = PassthroughSubject<ARSessionSettingsOptions, Never>()
   
    private(set) var options : ARSessionSettingsOptions? = nil {
        didSet {
            if let options = options {
                subjectOptions.send (options)
            }
        }
    }
    
    func publish(options: ARSessionSettingsOptions) {
        self.options = options
    }
}
