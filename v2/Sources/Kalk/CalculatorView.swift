import AppKit
import SwiftUI

struct CalculatorView: View {
    @ObservedObject var model: CalculatorModel
    @ObservedObject var settings: KalkSettings
    let openSettings: () -> Void

    @FocusState private var isInputFocused: Bool
    @State private var texHeight: CGFloat = 0

    private var fontSize: CGFloat { settings.fontSize }

    var body: some View {
        VStack(alignment: .leading, spacing: fontSize * 0.6) {
            HStack(spacing: 10) {
                Text(">>")
                    .font(.system(size: fontSize))
                TextField("", text: $model.input)
                    .textFieldStyle(.plain)
                    .font(.system(size: fontSize))
                    .tracking(fontSize * 0.05)
                    .focused($isInputFocused)
                    .onSubmit(model.commit)
            }
            .foregroundColor(settings.inputColor.color)
            .frame(minHeight: 40)

            TeXView(tex: model.tex, color: settings.inputColor.nsColor, fontSize: fontSize, height: $texHeight)
                .frame(maxWidth: .infinity)
                .frame(height: texHeight)

            Text(model.result)
                .font(.system(size: fontSize))
                .foregroundColor(settings.resultColor.color)
                .textSelection(.enabled)
                .lineLimit(2)
                .truncationMode(.middle)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            if settings.showHistory && !model.history.isEmpty {
                historyList
            } else {
                Spacer(minLength: 0)
            }

            HStack(alignment: .bottom) {
                Button(action: openSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 15))
                }
                .buttonStyle(.plain)
                .foregroundColor(settings.inputColor.color.opacity(0.55))
                .help("Settings")

                Spacer()

                if model.isErrorVisible, let error = model.error {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.45, green: 0.11, blue: 0.14))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color(red: 0.97, green: 0.84, blue: 0.85)))
                        .lineLimit(2)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(settings.backgroundColor.color)
        // The window's title bar is hidden; don't leave room for it.
        .ignoresSafeArea()
        .onAppear { isInputFocused = true }
        .onReceive(model.$focusRequest) { _ in isInputFocused = true }
    }

    /// Past calculations, newest first. Clicking one puts its expression back in the input.
    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(model.history) { entry in
                    HistoryRow(
                        entry: entry,
                        fontSize: max(10, fontSize * 0.72),
                        inputColor: settings.inputColor.color,
                        resultColor: settings.resultColor.color,
                        onUse: { model.use(entry) },
                        onDelete: { model.remove(entry) }
                    )
                }
            }
        }
        .frame(maxHeight: .infinity)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(settings.inputColor.color.opacity(0.12))
                .frame(height: 1)
        }
    }
}

/// One past calculation. Click to reuse it; hover for a delete button, or right-click to delete.
private struct HistoryRow: View {
    let entry: HistoryEntry
    let fontSize: CGFloat
    let inputColor: Color
    let resultColor: Color
    let onUse: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Button(action: onUse) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(entry.input)
                        .foregroundColor(inputColor.opacity(isHovered ? 0.85 : 0.6))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 8)
                    Text(entry.result)
                        .foregroundColor(resultColor.opacity(isHovered ? 1 : 0.75))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .layoutPriority(1)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Use \(entry.input)")

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(inputColor.opacity(0.5))
            }
            .buttonStyle(.plain)
            .help("Delete from history")
            // Keep the space reserved so rows don't shift when the button appears.
            .opacity(isHovered ? 1 : 0)
            .disabled(!isHovered)
        }
        .font(.system(size: fontSize))
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .background(RoundedRectangle(cornerRadius: 4).fill(inputColor.opacity(isHovered ? 0.07 : 0)))
        .onHover { isHovered = $0 }
        .contextMenu {
            Button("Use", action: onUse)
            Button("Copy Result") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(entry.result, forType: .string)
            }
            Divider()
            Button("Delete", action: onDelete)
        }
    }
}
