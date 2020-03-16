import Foundation

/// drop-in replacements
#if DEBUG
@inlinable var isRunningInTest: Bool { ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil }

@inlinable func assert(_ condition: @autoclosure () -> Bool,_ message: @autoclosure  () -> String = "", file: StaticString = #file, line: UInt = #line) {
    isRunningInTest
        ? Assertions.assertClosure(condition(), message(), file, line)
        : Swift.assert(condition(), message(), file: file, line: line)
}

@inlinable func assertionFailure(_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    isRunningInTest
        ? Assertions.assertionFailureClosure(message(), file, line)
        : Swift.assertionFailure(message(), file: file, line: line)
}

@inlinable func precondition(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    isRunningInTest
        ? Assertions.preconditionClosure(condition(), message(), file, line)
        : Swift.precondition(condition(), message(), file: file, line: line)
}

@inlinable func preconditionFailure(_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) -> Never {
    isRunningInTest
        ? Assertions.preconditionFailureClosure(message(), file, line)
        : Swift.preconditionFailure(message(), file: file, line: line)
}

@inlinable func fatalError(_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) -> Never {
    isRunningInTest
        ? Assertions.fatalErrorClosure(message(), file, line)
        : Swift.fatalError(message(), file: file, line: line)
}

/// Stores custom assertions closures, by default it points to Swift functions. But test target can override them.
public class Assertions {

    public static var assertClosure              = swiftAssertClosure
    public static var assertionFailureClosure    = swiftAssertionFailureClosure
    public static var preconditionClosure        = swiftPreconditionClosure
    public static var preconditionFailureClosure = swiftPreconditionFailureClosure
    public static var fatalErrorClosure          = swiftFatalErrorClosure

    public static let swiftAssertClosure              = { Swift.assert($0, $1, file: $2, line: $3) }
    public static let swiftAssertionFailureClosure    = { Swift.assertionFailure($0, file: $1, line: $2) }
    public static let swiftPreconditionClosure        = { Swift.precondition($0, $1, file: $2, line: $3) }
    public static let swiftPreconditionFailureClosure = { Swift.preconditionFailure($0, file: $1, line: $2) }
    public static let swiftFatalErrorClosure          = { Swift.fatalError($0, file: $1, line: $2) }
}
#endif
