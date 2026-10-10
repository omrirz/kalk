import Foundation
import KalkMath

struct HistoryEntry: Equatable, Identifiable {
    let id = UUID()
    let input: String
    let result: String

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.input == rhs.input && lhs.result == rhs.result
    }
}

@MainActor
final class CalculatorModel: ObservableObject {
    static let historyLimit = 100

    @Published var input = "" {
        didSet {
            if !isRecalling { historyCursor = nil }
            evaluate()
        }
    }
    @Published private(set) var result = ""
    @Published private(set) var tex = ""
    @Published private(set) var error: String?
    @Published private(set) var isErrorVisible = false
    /// Bumped whenever the window is shown, so the view can focus the input field.
    @Published private(set) var focusRequest = 0
    /// Newest first.
    @Published private(set) var history: [HistoryEntry] = [] {
        didSet { saveHistory() }
    }

    private let engine: MathEngine?
    private let defaults: UserDefaults

    /// Index into `history` while browsing with ↑/↓, or nil when editing a fresh line.
    private var historyCursor: Int?
    /// What the user was typing before browsing history, restored by ↓ past the newest entry.
    private var draft = ""
    private var isRecalling = false
    /// True when the current input evaluated to a value, so `result` belongs to it.
    private var hasValue = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        do {
            engine = try MathEngine()
        } catch {
            engine = nil
            self.error = (error as? MathError)?.message ?? error.localizedDescription
        }
        loadHistory()
    }

    func requestFocus() {
        focusRequest += 1
    }

    /// Shows the last parse error, if any. Triggered by pressing Option.
    func revealError() {
        isErrorVisible = error != nil
    }

    // MARK: - History

    /// Saves the current line to history and starts a fresh one. Triggered by Enter.
    func commit() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, hasValue else { return }

        let entry = HistoryEntry(input: trimmed, result: result)
        if history.first != entry {
            history.insert(entry, at: 0)
            if history.count > Self.historyLimit { history.removeLast(history.count - Self.historyLimit) }
        }
        input = ""
    }

    /// Steps through earlier inputs, like a shell. `older` is ↑, otherwise ↓.
    func recall(older: Bool) {
        guard !history.isEmpty else { return }
        let next: Int?
        switch (historyCursor, older) {
        case (nil, true):
            draft = input
            next = 0
        case (nil, false):
            return
        case (let index?, true):
            next = min(index + 1, history.count - 1)
        case (let index?, false):
            next = index == 0 ? nil : index - 1
        }

        isRecalling = true
        historyCursor = next
        input = next.map { history[$0].input } ?? draft
        isRecalling = false
    }

    func use(_ entry: HistoryEntry) {
        input = entry.input
        requestFocus()
    }

    func remove(_ entry: HistoryEntry) {
        history.removeAll { $0.id == entry.id }
        historyCursor = nil
    }

    func clearHistory() {
        history = []
        historyCursor = nil
    }

    private func loadHistory() {
        let saved = defaults.array(forKey: "history") as? [[String: String]] ?? []
        history = saved.compactMap { item in
            guard let input = item["input"], let result = item["result"] else { return nil }
            return HistoryEntry(input: input, result: result)
        }
    }

    private func saveHistory() {
        defaults.set(history.map { ["input": $0.input, "result": $0.result] }, forKey: "history")
    }

    // MARK: - Evaluation

    private func evaluate() {
        guard let engine else { return }
        isErrorVisible = false
        hasValue = false
        do {
            let calculation = try engine.evaluate(input)
            error = nil
            hasValue = calculation.formattedValue.isEmpty == false
            switch calculation.kind {
            case .functionDefinition:
                // Like the original app, keep showing the previous result while a function is being defined.
                return
            case .empty, .value:
                result = calculation.formattedValue
                tex = calculation.tex
            }
        } catch {
            // Keep the last valid result while the user is mid-expression (e.g. "2 +").
            self.error = (error as? MathError)?.message ?? error.localizedDescription
        }
    }
}
