import ServiceManagement
import SwiftUI

struct SettingsActions {
    let resetSize: () -> Void
    let resetPosition: () -> Void
    let clearHistory: () -> Void
    let close: () -> Void
    let quit: () -> Void
}

struct SettingsView: View {
    @ObservedObject var settings: KalkSettings
    let actions: SettingsActions

    var body: some View {
        VStack(spacing: 0) {
            TabView {
                GeneralSettings(settings: settings, actions: actions)
                    .tabItem { Text("General") }
                HowToView()
                    .tabItem { Text("How to") }
                AboutView()
                    .tabItem { Text("About") }
            }
            .padding([.top, .horizontal], 12)

            HStack {
                Spacer()
                Button("Close Settings", action: actions.close)
                    .keyboardShortcut(.cancelAction)
                Button("Quit Kalk", role: .destructive, action: actions.quit)
            }
            .padding(12)
        }
        .frame(minWidth: 520, minHeight: 560)
    }
}

private struct GeneralSettings: View {
    @ObservedObject var settings: KalkSettings
    let actions: SettingsActions
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    private var maxSize: CGSize {
        NSScreen.main?.visibleFrame.size ?? CGSize(width: 4000, height: 4000)
    }

    var body: some View {
        Form {
            Section("Kalk size") {
                HStack {
                    NumberField(label: "Width", value: dimension(\.width),
                                range: KalkSettings.minSize.width...maxSize.width)
                    NumberField(label: "Height", value: dimension(\.height),
                                range: KalkSettings.minSize.height...maxSize.height)
                    Spacer()
                    Button("Reset size", action: actions.resetSize)
                }
            }

            Section("Kalk position") {
                Toggle("Window always on top", isOn: $settings.alwaysOnTop)
                Toggle("Window visible in all Spaces", isOn: $settings.visibleOnAllSpaces)
                HStack {
                    Text("Drag the top of the window to move it.")
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Reset position", action: actions.resetPosition)
                }
            }

            Section("Font size") {
                HStack {
                    Slider(value: $settings.fontSize, in: KalkSettings.fontSizeRange, step: 1)
                    Text("\(Int(settings.fontSize)) pt")
                        .monospacedDigit()
                        .frame(width: 44, alignment: .trailing)
                    Button("Reset") { settings.fontSize = KalkSettings.defaultFontSize }
                }
            }

            Section("Kalk colors") {
                ColorRow(title: "Background color", rgb: $settings.backgroundColor, defaultValue: KalkSettings.defaultBackground)
                ColorRow(title: "Input font color", rgb: $settings.inputColor, defaultValue: KalkSettings.defaultInputColor)
                ColorRow(title: "Result font color", rgb: $settings.resultColor, defaultValue: KalkSettings.defaultResultColor)
            }

            Section("History") {
                Toggle("Show history in the Kalk window", isOn: $settings.showHistory)
                HStack {
                    Text("Press Enter to save a calculation, ↑ and ↓ to recall earlier ones.")
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Clear history", action: actions.clearHistory)
                }
            }

            Section("Startup") {
                Toggle("Launch Kalk at login", isOn: Binding(
                    get: { launchAtLogin },
                    set: { enabled in
                        do {
                            if enabled {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            NSLog("Kalk: failed to update login item: \(error)")
                        }
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                    }
                ))
            }
        }
        .formStyle(.grouped)
    }

    private func dimension(_ keyPath: WritableKeyPath<CGSize, CGFloat>) -> Binding<Double> {
        Binding(
            get: { settings.windowSize[keyPath: keyPath] },
            set: { settings.windowSize[keyPath: keyPath] = $0 }
        )
    }
}

/// A number field that edits free text and commits it, clamped to `range`, on Enter or when focus leaves.
/// Committing on every keystroke would reject intermediate values (e.g. "3" on the way to "300").
private struct NumberField: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(label, text: $text)
            .focused($isFocused)
            .frame(width: 120)
            .onSubmit(commit)
            .onAppear { text = Self.format(value) }
            .onChange(of: isFocused) { focused in
                if !focused { commit() }
            }
            .onChange(of: value) { newValue in
                // Reflect outside changes (window resized by dragging, reset button) unless the user is typing.
                if !isFocused { text = Self.format(newValue) }
            }
    }

    private func commit() {
        if let number = Double(text.trimmingCharacters(in: .whitespaces)) {
            value = min(max(number, range.lowerBound), range.upperBound).rounded()
        }
        text = Self.format(value)
    }

    private static func format(_ value: Double) -> String {
        String(Int(value.rounded()))
    }
}

private struct ColorRow: View {
    let title: String
    @Binding var rgb: RGB
    let defaultValue: RGB

    var body: some View {
        HStack {
            ColorPicker(title, selection: Binding(get: { rgb.color }, set: { rgb = RGB($0) }), supportsOpacity: false)
            Button("Reset") { rgb = defaultValue }
                .disabled(rgb == defaultValue)
        }
    }
}

private struct HowToView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Shortcuts").font(.title2.bold())
                Label("Press ⌘5 to show and hide Kalk.", systemImage: "keyboard")
                Label("While typing, press ⌥ (Option) to view parsing errors.", systemImage: "exclamationmark.bubble")
                Label("Press Enter to save a calculation to history, ↑ and ↓ to recall earlier ones.", systemImage: "clock.arrow.circlepath")
                Label("Press Esc to hide Kalk.", systemImage: "escape")
                Label("Right-click the menubar icon for Settings and Quit.", systemImage: "menubar.rectangle")

                Text("Examples").font(.title2.bold()).padding(.top, 8)
                VStack(alignment: .leading, spacing: 6) {
                    example("12 * (3 + 4) / 2", "operators and parentheses")
                    example("2^10, 5!, 17 mod 5", "powers, factorials, modulo")
                    example("sqrt(2) + 2pi", "functions, constants, implicit multiplication")
                    example("sin(30 deg)", "trigonometry in radians or degrees")
                    example("[1, 2, 3] * 2", "vectors")
                    example("det([1, 2; 3, 4])", "matrices: det, inv, transpose, dot, cross")
                    example("5 cm to inch", "units")
                    example("sqrt(-4)", "complex numbers")
                    example("r = 3; pi r^2", "variables, separated by ;")
                    example("f(x) = x^2 + 1; f(4)", "your own functions")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }

    private func example(_ code: String, _ note: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(code).font(.system(.body, design: .monospaced))
            Text("— \(note)").foregroundColor(.secondary)
        }
    }
}

private struct AboutView: View {
    private var logo: NSImage {
        Bundle.main.image(forResource: "logo") ?? NSApp.applicationIconImage
    }

    var body: some View {
        VStack(spacing: 10) {
            Image(nsImage: logo)
                .resizable()
                .frame(width: 96, height: 96)
            Text("Kalk").font(.largeTitle.bold())
            Text("The simplest desktop calculator.")
            Text("Made by Omri Rozenzaft.")
            Link("View source on GitHub", destination: URL(string: "https://github.com/omrirz/Kalk")!)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
