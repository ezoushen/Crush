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

extension ObservableObject {
    func binding<T>(_ keyPath: ReferenceWritableKeyPath<Self, T>) -> Binding<T> {
        Binding(
            get: { self[keyPath: keyPath] },
            set: { self[keyPath: keyPath] = $0 }
        )
    }
}
