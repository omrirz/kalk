# Kalk v2

![Logo](./Resources/logo.png)

### The simplest desktop calculator — now native.

A Swift/SwiftUI rewrite of [Kalk](https://github.com/omrirz/Kalk), the menubar calculator. Same idea, a few MB instead of an Electron bundle.

Like the original, expressions are evaluated by [mathjs](https://mathjs.org) 5.10.3 (run in JavaScriptCore) and typeset with [KaTeX](https://katex.org) (in a WKWebView), so results match the Electron version.

## Usage

1. Launch Kalk — it lives in the menu bar.
2. Press **⌘5** (or click the menubar icon) to show and hide it.
3. Start typing; Kalk computes the result as you go and typesets the expression.
4. Press **Enter** to save a calculation to history and start a new line; **↑ / ↓** recall earlier expressions, clicking an entry in the history list reuses it, and hovering shows a ⓧ to delete it (or right-click → Delete). History is kept across launches (last 100).
5. Press **⌥ Option** to see why an expression doesn't parse, **Esc** to hide.
6. The gear button (or right-click on the menubar icon, or ⌘,) opens Settings: window size and position, always-on-top, all Spaces, font size, colors, history and launch at login.

Anything [mathjs supports](https://mathjs.org/docs/expressions/syntax.html) works, for example:

| Input | Notes |
| --- | --- |
| `12 * (3 + 4) / 2`, `2pi`, `5!` | arithmetic, implicit multiplication |
| `sqrt(2)`, `log(100, 10)`, `sin(30 deg)` | functions and constants |
| `[1, 2, 3] * 2`, `cross([1,0,0], [0,1,0])` | vectors |
| `det([1, 2; 3, 4])`, `inv([1, 2; 3, 4])` | matrices |
| `5 cm to inch` | units |
| `sqrt(-4)` | complex numbers |
| `r = 3; pi r^2`, `f(x) = x^2; f(4)` | variables and functions; `;` separates statements |

## Development

Requires Xcode 15+ (Swift 5.9) and macOS 13+.

```console
swift run Kalk     # run from source
swift test         # run the math engine tests
```

The code is split into:

- `Sources/KalkMath` — a Swift wrapper around mathjs (unit tested)
- `Sources/Kalk` — the AppKit/SwiftUI menubar app; `Web/` holds the KaTeX page

## Build

```console
./scripts/build-app.sh          # dist/Kalk.app (universal: Apple silicon + Intel)
./scripts/build-app.sh --dmg    # also dist/Kalk.dmg
```

The app is ad-hoc signed. To distribute it, sign with a Developer ID by setting `CODESIGN_IDENTITY` and notarize it.
