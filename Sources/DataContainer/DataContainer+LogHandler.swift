//
//  DataContainer+LogHandler.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import Foundation

internal typealias LogHandler = DataContainer.LogHandler

extension DataContainer {
    public enum LogLevel {
        case info, warning, error, critical
    }

    public struct LogHandler {
        public static var `default`: LogHandler {
            .init(
                info: { print($0) },
                warning: { print($0)},
                error: { msg, err in print(msg) },
                critical: { msg, err in print(msg) })
        }

        private static let queue: DispatchQueue = .init(
            label: "\(Bundle.main.bundleIdentifier ?? "").LogHandler",
            qos: .background)

        public enum Level {
            case info, warning, error, critical
        }

        private let _info: (String) -> Void
        private let _warning: (String) -> Void
        private let _error: (String, Error?) -> Void
        private let _critical: (String, Error?) -> Void

        public init(
            info: @escaping (String) -> Void,
            warning: @escaping (String) -> Void,
            error: @escaping (String, Error?) -> Void,
            critical: @escaping (String, Error?) -> Void)
        {
            _info = info
            _warning = warning
            _error = error
            _critical = critical
        }

        func log(_ level: Level, _ message: String, error: Error? = nil) {
            Self.queue.async {
                switch level {
                case .info: return _info(message)
                case .warning: return _warning(message)
                case .error: return _error(message, error)
                case .critical: return _critical(message, error)
                }
            }
        }
    }
}
