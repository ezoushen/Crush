//
//  ReadOnly+Combine.swift
//
//
//  Created by ezou on 2022/1/29.
//

#if canImport(Combine)
import Foundation
import Combine
import CoreData

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension ManagedObjectBase {
    public struct KVOPublisher<Entity: Crush.Entity, T: Property>: Combine.Publisher {
        public typealias Output = T.RuntimeValue
        public typealias Failure = Never

        public let subject: Entity.Driver
        public let keyPath: KeyPath<Entity, T>
        public let options: NSKeyValueObservingOptions

        public func receive<S>(subscriber: S)
        where S : Subscriber, Never == S.Failure, T.RuntimeValue == S.Input {
            if subject.isFault {
                subject.managedObject.fireFault()
            }
            let subscription = Subscription(
                subject: subject.managedObject,
                subscriber: subscriber,
                keyPath: keyPath.propertyName,
                options: options)
            subscriber.receive(subscription: subscription)
        }

        public class Subscription<S: Combine.Subscriber>: NSObject, Combine.Subscription
        where S.Input == T.PropertyType.RuntimeValue {
            private let keyPath: String
            private let options: NSKeyValueObservingOptions
            
            private var subscriber: S?
            private var subject: NSObject?

            private var waitingForCancellation: Bool = false
            private var lock = UnfairLock()

            private var demand: Subscribers.Demand = .none

            init(subject: NSObject, subscriber: S, keyPath: String, options: NSKeyValueObservingOptions) {
                self.subscriber = subscriber
                self.keyPath = keyPath
                self.options = options
                self.subject = subject

                super.init()
            }

            public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
                if let managedObject = object as? NSManagedObject, managedObject.isDeleted {
                    if lock.tryLock() {
                        removeObservation()
                        lock.unlock()
                    } else {
                        waitingForCancellation = true
                    }
                    return
                }
                sendValue(change: change, key: .oldKey)
                sendValue(change: change, key: .newKey)
            }

            private func sendValue(change: [NSKeyValueChangeKey : Any]?, key: NSKeyValueChangeKey) {
                guard change?.keys.contains(key) == true,
                      let value = change?[key] as? T.PropertyType.ManagedValue
                else { return }
                let input = T.PropertyType.convert(managedValue: value)
                send(value: input)
            }

            private func send(value: S.Input) {
                guard demand > 0 else { return }
                demand -= 1
                demand += subscriber?.receive(value) ?? .none
            }

            func subscribe() {
                lock.lock()
                subject?.addObserver(
                    self, forKeyPath: keyPath, options: options, context: nil)
                if waitingForCancellation {
                    removeObservation()
                }
                lock.unlock()
            }

            public func request(_ demand: Subscribers.Demand) {
                self.demand += demand
                self.subscribe()
            }

            public func cancel() {
                if lock.tryLock() {
                    removeObservation()
                    lock.unlock()
                } else {
                    waitingForCancellation = true
                }
            }

            private func removeObservation() {
                subject?.removeObserver(self, forKeyPath: keyPath)
                subscriber?.receive(completion: .finished)
                subject = nil
                subscriber = nil
            }
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension ReadOnly {
    /// Please be aware that observing property changes requires the managed object not to be a fault. Thus, it'll fire the faulting object first if needed
    public func observe<Property: Crush.Property>(
        _ keyPath: KeyPath<Entity, Property>, options: NSKeyValueObservingOptions
    ) -> ManagedObjectBase.KVOPublisher<Entity, Property> {
        ManagedObjectBase.KVOPublisher<Entity, Property>(
            subject: driver, keyPath: keyPath, options: options)
    }

    /// Please be aware that observing property changes requires the managed object not to be a fault. Thus, it'll fire the faulting object first if needed
    public func observe<Property: Crush.Property>(
        _ keyPath: KeyPath<Entity, Property>, options: NSKeyValueObservingOptions
    ) -> AnyPublisher<Property.RuntimeValue.Safe, Never>
    where
        Property.RuntimeValue: UnsafeSessionProperty
    {
        return ManagedObjectBase.KVOPublisher<Entity, Property>(
            subject: driver, keyPath: keyPath, options: options
        )
            .map { $0.wrapped() }
            .eraseToAnyPublisher()
    }
}
#endif
