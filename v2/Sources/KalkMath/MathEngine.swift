import Foundation
import JavaScriptCore

public struct MathError: Error, Equatable, CustomStringConvertible {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var description: String { message }
}

/// The outcome of evaluating one line of input.
public struct Calculation: Equatable {
    public enum Kind: Equatable {
        /// A value to show, already formatted by mathjs (numbers, vectors, matrices, units, complex numbers, ...).
        case value(String)
        /// The input defines a function (`f(x) = x^2`); there is nothing to show.
        case functionDefinition
        /// Empty input, or only statements hidden with `;`.
        case empty
    }

    public let kind: Kind
    /// The expression as TeX, for typesetting with KaTeX. Empty when there is nothing to typeset.
    public let tex: String

    public var formattedValue: String {
        if case .value(let value) = kind { return value }
        return ""
    }
}

/// Evaluates expressions with mathjs (the same library the Electron version used), running in JavaScriptCore.
public final class MathEngine {
    private let context: JSContext
    private let evaluateFunction: JSValue

    /// Mirrors the Electron app: `math.eval` for the value and `toTex({parenthesis: 'auto'})` for the pretty print.
    /// Values are formatted to 14 significant digits, so `0.1 + 0.2` shows `0.3`.
    private static let bridge = """
    function kalkEvaluate(expression) {
        try {
            var node = math.parse(expression);
            var value = node.compile().eval({});
            var tex = node.toTex({ parenthesis: 'auto' });
            if (tex === 'undefined') tex = '';
            if (typeof value === 'function') return { kind: 'function', tex: tex };
            if (value && value.isResultSet) {
                // Several statements: show the last visible one (statements ending in ';' are hidden).
                var entries = value.entries;
                value = entries.length ? entries[entries.length - 1] : undefined;
                if (typeof value === 'function') return { kind: 'function', tex: tex };
            }
            if (value === undefined) return { kind: 'empty', tex: tex };
            return { kind: 'value', value: math.format(value, { precision: 14 }), tex: tex };
        } catch (error) {
            return { kind: 'error', error: String(error && error.message || error) };
        }
    }
    """

    public init() throws {
        guard let context = JSContext() else { throw MathError("Could not create a JavaScript context") }
        guard let url = Self.mathjsURL, let source = try? String(contentsOf: url, encoding: .utf8) else {
            throw MathError("Could not load math.min.js")
        }

        var loadError: String?
        context.exceptionHandler = { _, exception in
            loadError = exception?.toString()
        }
        context.evaluateScript(source, withSourceURL: url)
        context.evaluateScript(Self.bridge)
        if let loadError { throw MathError("Could not load mathjs: \(loadError)") }

        guard let function = context.objectForKeyedSubscript("kalkEvaluate"), !function.isUndefined else {
            throw MathError("Could not load mathjs")
        }
        self.context = context
        self.evaluateFunction = function
    }

    public func evaluate(_ input: String) throws -> Calculation {
        guard let result = evaluateFunction.call(withArguments: [input]) else {
            throw MathError("Evaluation failed")
        }
        let tex = result.forProperty("tex")?.toString() ?? ""
        switch result.forProperty("kind")?.toString() {
        case "value":
            return Calculation(kind: .value(result.forProperty("value")?.toString() ?? ""), tex: tex)
        case "function":
            return Calculation(kind: .functionDefinition, tex: tex)
        case "empty":
            return Calculation(kind: .empty, tex: tex)
        default:
            throw MathError(result.forProperty("error")?.toString() ?? "Unknown error")
        }
    }

    /// In the .app bundle the script sits in Contents/Resources; under `swift run`/`swift test` it's in the SwiftPM bundle.
    private static var mathjsURL: URL? {
        Bundle.main.url(forResource: "math.min", withExtension: "js")
            ?? Bundle.module.url(forResource: "math.min", withExtension: "js")
    }
}
