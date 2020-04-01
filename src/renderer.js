// This file is required by the index.html file and will
// be executed in the renderer process for that window.
// All of the Node.js APIs are available in this process.
let kalk = require('./kalk.js')
var remote = require('electron').remote
var ipcRenderer = require('electron').ipcRenderer

var cfg = remote.getGlobal('cfg')

document.getElementById('settings-button').addEventListener('click', function () {
    ipcRenderer.send('toggleSettings')
})

function array_to_color_string(arr) {
    return ('rgb(' + arr.join() + ')')
}

function setFontSize() {
    $('#main-input-input').css('font-size', cfg.font.font_size + 'px')
    $('#main-input-span').css('font-size', cfg.font.font_size + 'px')
    $('#main-result').css('font-size', cfg.font.font_size + 'px')
    $('#pretty').css('font-size', (cfg.font.font_size / 16) + 'em')
}

function setColors() {
    $('body').css('background-color', array_to_color_string(cfg.background_color.color))
    $('#main-input-input').css('background-color', array_to_color_string(cfg.background_color.color))
    $('#main-input-input').css('color', array_to_color_string(cfg.input_font_color.color))
    $('#main-input-span').css('color', array_to_color_string(cfg.input_font_color.color))
    $('#pretty').css('color', array_to_color_string(cfg.input_font_color.color))
    $('#main-result').css('color', array_to_color_string(cfg.result_font_color.color))
}

function onKalkOpen() {
    setFontSize()
    setColors()
    // $('#main-input-input').focus()
}
onKalkOpen()

ipcRenderer.on('setKalkSizes', () => {
    setFontSize()
})

ipcRenderer.on('setColors', () => {
    setColors()
})

ipcRenderer.on('focus-input', (event) => {
    $('#main-input-input').focus()
})

console.log('renderer')
