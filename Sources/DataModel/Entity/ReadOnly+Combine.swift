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
extension ManagedObject {
    public struct KVOPublisher<T: ValuedProperty>: Combine.Publisher {
        public typealias Output = T.PropertyValue
        public typealias Failure = Never

        public let subject: ManagedObject<Entity>
        public let keyPath: KeyPath<Entity, T>
        public let options: NSKeyValueObservingOptions

        public func receive<S>(subscriber: S)
        where S : Subscriber, Never == S.Failure, T.PropertyValue == S.Input {
            let subscription = Subscription(
                subject: subject,
                subscriber: subscriber,
                keyPath: keyPath.propertyName,
                options: options)
            subscriber.receive(subscription: subscription)
            subscription.subscribe()
        }

        public class Subscription<S: Combine.Subscriber>: NSObject, Combine.Subscription
        where S.Input == T.FieldConvertor.RuntimeObjectValue {
            private let keyPath: String
            private let options: NSKeyValueObservingOptions
            
            private var subscriber: S?
            private var subject: NSObject?

            private var waitingForCancellation: Bool = false
            private var lock = os_unfair_lock()

            init(subject: NSObject, subscriber: S, keyPath: String, options: NSKeyValueObservingOptions) {
                self.subscriber = subscriber
                self.keyPath = keyPath
                self.options = options
                self.subject = subject

                super.init()
            }

            public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
                if let managedObject = object as? NSManagedObject, managedObject.isDeleted {
                    return removeObservation()
                }
                if change?.keys.contains(.oldKey) == true,
                   let value = change?[.oldKey] as? T.FieldConvertor.ManagedObjectValue {
                    _ = subscriber?.receive(T.FieldConvertor.convert(value: value))
                }
                if change?.keys.contains(.newKey) == true,
                   let value = change?[.newKey] as? T.FieldConvertor.ManagedObjectValue {
                    _ = subscriber?.receive(T.FieldConvertor.convert(value: value))
                }
            }

            func subscribe() {
                os_unfair_lock_lock(&lock)
                subject?.addObserver(
                    self, forKeyPath: keyPath, options: options, context: nil)
                if waitingForCancellation {
                    removeObservation()
                }
                os_unfair_lock_unlock(&lock)
            }

            public func request(_ demand: Subscribers.Demand) { }

            public func cancel() {
                if os_unfair_lock_trylock(&lock) {
                    removeObservation()
                } else {
                    waitingForCancellation = true
                }
            }

            private func removeObservation() {
                subject?.removeObserver(self, forKeyPath: keyPath)
                subject = nil
                subscriber = nil
            }
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension ReadOnly {
    public func observe<T: ValuedProperty>(
        _ keyPath: KeyPath<Entity, T>, options: NSKeyValueObservingOptions
    ) -> ManagedObject<Entity>.KVOPublisher<T> {
        ManagedObject<Entity>.KVOPublisher<T>(
            subject: managedObject, keyPath: keyPath, options: options)
    }

    public func observe<T: ValuedProperty>(
        _ keyPath: KeyPath<Entity, T>, options: NSKeyValueObservingOptions
    ) -> AnyPublisher<T.PropertyValue.Safe, Never>
    where
        T.PropertyValue: UnsafeSessionProperty
    {
        return ManagedObject<Entity>.KVOPublisher<T>(
            subject: managedObject, keyPath: keyPath, options: options
        )
            .map { $0.wrapped() }
            .eraseToAnyPublisher()
    }
}
#endif
