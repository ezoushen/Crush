//
//  ViewModel.swift
//  Example-SwiftUI
//
//  Created by ezou on 2020/4/18.
//

import SwiftUI
import Combine

protocol ViewModelProtocol: AnyObject {
    var cancellables: Set<AnyCancellable>  { get set }
}

public class ViewModel: ViewModelProtocol {
    var cancellables: Set<AnyCancellable> = []
    
    let didDismiss: PassthroughSubject<Void, Never> = .init()
    
    deinit {
        didDismiss.send()
    }
}

extension ViewModelProtocol where Self: ObservableObject {
    func bindSubmodel() {
        let allChildren: [Mirror.Child] = {
            func findChildren(mirror: Mirror?) -> [Mirror.Child] {
                guard let mirror = mirror else { return [] }
                return mirror.children + findChildren(mirror: mirror.superclassMirror)
            }
            return findChildren(mirror: Mirror(reflecting: self))
        }()

        allChildren.forEach { lable, value in
            guard var value = value as? SubmodelProtocol else { return }
            value.bind(to: self)
        }
    }
}

extension ObservableObject {
    func binding<T>(_ keyPath: ReferenceWritableKeyPath<Self, T>) -> Binding<T> {
        Binding(
            get: { self[keyPath: keyPath] },
            set: { self[keyPath: keyPath] = $0 }
        )
    }
}

protocol SubmodelProtocol {
    mutating func bind<T: ViewModelProtocol & ObservableObject>(to: T)
}

@propertyWrapper
class Submodel<T: ObservableObject>: SubmodelProtocol {
    
    var wrappedValue: T
        
    init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
}

extension Submodel {
    func bind<T>(to model: T) where T : ViewModelProtocol & ObservableObject {
        wrappedValue.objectWillChange.sink { [unowned model] _ in
            (model.objectWillChange as! ObservableObjectPublisher).send()
        }
        .store(in: &model.cancellables)
    }
}
