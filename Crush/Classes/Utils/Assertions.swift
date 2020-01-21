import Foundation

/// drop-in replacements

private func never() -> Never {
    repeat {
        RunLoop.current.run()
    } while (true)
}


func assert(_ condition: @autoclosure () -> Bool,_ message: @autoclosure  () -> String = "", file: StaticString = #file, line: UInt = #line) {
    Assertions.assertClosure(condition(), message(), file, line)
}

func assertionFailure(_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    Assertions.assertionFailureClosure(message(), file, line)
}

func precondition(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    Assertions.preconditionClosure(condition(), message(), file, line)
}

func preconditionFailure(_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) -> Never {
    Assertions.preconditionFailureClosure(message(), file, line)
}

func fatalError(_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) -> Never {
    Assertions.fatalErrorClosure(message(), file, line)
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
