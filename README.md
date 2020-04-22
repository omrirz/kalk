
![Alt Text](https://media.giphy.com/media/eKmWjFzyJpcakTtgHW/giphy.gif)


# Kalk

![Logo](./src/assets/logo.png)

### The simplest desktop calculator.

## Download

[Mac installer](https://github.com/omrirz/kalk/releases/download/v.0.0.1/kalk-0.0.1.dmg)

[Windows installer](https://github.com/omrirz/kalk/releases/download/v.0.0.1/kalk.Setup.0.0.1.exe)

## Usage

1. Once you launched the app hit Cmd+5 (Mac) ot Alt+5 (Linux, Windows) to open Kalk.
(You can also use the menubar button to show Kalk. double-click on Ubuntu)

2. Start typing and Kalk will compute the result as you go.
3. At the bottom left corner there is a settings button. Use it!

---

## Development

```console
git clone https://github.com/omrirz/kalk.git
cd kalk && npm install
npm start
```

## Build

### Mac

```console
npm run dist:mac
```

will create a DMG for mac

### Linux

```console
npm run dist:linux
```

will create an AppImage for Linux

### Windows

```console
npm run dist:windows
```

will create an installer for windows
