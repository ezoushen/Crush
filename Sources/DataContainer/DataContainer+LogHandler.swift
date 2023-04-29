//
//  DataContainer+LogHandler.swift
//  
//
//  Created by ezou on 2021/10/15.
//

import Foundation
import os

internal typealias LogHandler = DataContainer.LogHandler

extension DataContainer {
    /// Predefined `LogLevel` for `DataContainer`
    public enum LogLevel {
        /// Normal log
        case info
        /// Potential error
        case warning
        /// Non fatal error
        case error
        /// Fatal error
        case critical
    }

    /// Define desired logging behaviour.
    ///
    /// Example:
    ///
    ///     let handler = LogHandler(
    ///         info: { print("info: \($0)") },
    ///         warning: { print("warning: \($0)") },
    ///         error: { msg, err in print("error: \(msg), details: \(String(describing: err))" },
    ///         critical: { msg, err in print("critical: \(msg), details: \(String(describing: err)") })
    ///
    public struct LogHandler {
        public static var `default`: LogHandler {
            if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
                let logger = Logger()
                return LogHandler(
                    info: { logger.info("\($0)") },
                    warning: { logger.warning("\($0)") },
                    error: { msg, err in err == nil ? logger.error("\(msg)") : logger.error("\(msg), error: \(err!)") },
                    critical: { msg, err in err == nil ? logger.critical("\(msg)") : logger.critical("\(msg), error: \(err!)") })
            }
            return LogHandler(
                info: { print($0) },
                warning: { print($0)},
                error: { msg, err in err == nil ? print(msg) : print("\(msg), error: \(err!)") },
                critical: { msg, err in err == nil ? print(msg) : print("\(msg), error: \(err!)") })
        }

        static var current: LogHandler = .default

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
