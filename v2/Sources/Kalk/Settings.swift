import AppKit
import SwiftUI

struct RGB: Equatable {
    var red: Double
    var green: Double
    var blue: Double

    init(_ red: Double, _ green: Double, _ blue: Double) {
        (self.red, self.green, self.blue) = (red, green, blue)
    }

    init(_ color: Color) {
        let ns = NSColor(color).usingColorSpace(.sRGB) ?? .black
        self.init(ns.redComponent * 255, ns.greenComponent * 255, ns.blueComponent * 255)
    }

    var nsColor: NSColor {
        NSColor(srgbRed: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
    }

    var color: Color { Color(nsColor: nsColor) }
}

/// User preferences, persisted in UserDefaults. Defaults match the original Electron app.
final class KalkSettings: ObservableObject {
    static let defaultSize = CGSize(width: 400, height: 250)
    static let minSize = CGSize(width: 200, height: 200)
    static let defaultFontSize = 18.0
    static let fontSizeRange = 8.0...40.0
    static let defaultBackground = RGB(40, 44, 52)
    static let defaultInputColor = RGB(255, 255, 255)
    static let defaultResultColor = RGB(103, 243, 108)

    private let defaults: UserDefaults

    @Published var windowSize: CGSize { didSet { defaults.set([windowSize.width, windowSize.height], forKey: "windowSize") } }
    /// Bottom-left window origin in screen coordinates, or nil to place the window under the menubar icon.
    @Published var windowOrigin: CGPoint? {
        didSet {
            if let windowOrigin {
                defaults.set([windowOrigin.x, windowOrigin.y], forKey: "windowOrigin")
            } else {
                defaults.removeObject(forKey: "windowOrigin")
            }
        }
    }
    @Published var alwaysOnTop: Bool { didSet { defaults.set(alwaysOnTop, forKey: "alwaysOnTop") } }
    @Published var visibleOnAllSpaces: Bool { didSet { defaults.set(visibleOnAllSpaces, forKey: "visibleOnAllSpaces") } }
    @Published var showHistory: Bool { didSet { defaults.set(showHistory, forKey: "showHistory") } }
    @Published var fontSize: Double { didSet { defaults.set(fontSize, forKey: "fontSize") } }
    @Published var backgroundColor: RGB { didSet { save(backgroundColor, "backgroundColor") } }
    @Published var inputColor: RGB { didSet { save(inputColor, "inputColor") } }
    @Published var resultColor: RGB { didSet { save(resultColor, "resultColor") } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let size = defaults.array(forKey: "windowSize") as? [Double]
        windowSize = size?.count == 2 ? CGSize(width: size![0], height: size![1]) : Self.defaultSize
        let origin = defaults.array(forKey: "windowOrigin") as? [Double]
        windowOrigin = origin?.count == 2 ? CGPoint(x: origin![0], y: origin![1]) : nil
        alwaysOnTop = defaults.object(forKey: "alwaysOnTop") as? Bool ?? true
        visibleOnAllSpaces = defaults.object(forKey: "visibleOnAllSpaces") as? Bool ?? true
        showHistory = defaults.object(forKey: "showHistory") as? Bool ?? true
        fontSize = defaults.object(forKey: "fontSize") as? Double ?? Self.defaultFontSize
        backgroundColor = Self.load("backgroundColor", from: defaults) ?? Self.defaultBackground
        inputColor = Self.load("inputColor", from: defaults) ?? Self.defaultInputColor
        resultColor = Self.load("resultColor", from: defaults) ?? Self.defaultResultColor
    }

    private func save(_ rgb: RGB, _ key: String) {
        defaults.set([rgb.red, rgb.green, rgb.blue], forKey: key)
    }

    private static func load(_ key: String, from defaults: UserDefaults) -> RGB? {
        guard let values = defaults.array(forKey: key) as? [Double], values.count == 3 else { return nil }
        return RGB(values[0], values[1], values[2])
    }
}
