const remote = require('electron').remote
const ipcRendererSettings = require('electron').ipcRenderer

var cfg = remote.getGlobal('cfg')
var win = remote.getGlobal('win')

const closeSettings = document.getElementById('close-settings')
closeSettings.addEventListener('click', () => {
    $('#main-input-input').focus()
    win.webContents.send('focus-input')
    ipcRendererSettings.send('toggleSettings')
})


const closeApp = document.getElementById('close-app')
closeApp.addEventListener('click', () => {
    ipcRendererSettings.send('closeApp')
})


function onSettingsOpen() {

    document.getElementById('shortuct_listener').innerHTML = "'" + cfg.shortuct_listener.shortcut + "'"

    document.getElementById('kalk-height').value = cfg.win_sz.height
    document.getElementById('kalk-width').value = cfg.win_sz.width
    document.getElementById('font-size').value = cfg.font.font_size
    document.getElementById('background-color-red').value = cfg.background_color.color[0]
    document.getElementById('background-color-green').value = cfg.background_color.color[1]
    document.getElementById('background-color-blue').value = cfg.background_color.color[2]

    document.getElementById('input-color-red').value = cfg.input_font_color.color[0]
    document.getElementById('input-color-green').value = cfg.input_font_color.color[1]
    document.getElementById('input-color-blue').value = cfg.input_font_color.color[2]

    document.getElementById('result-color-red').value = cfg.result_font_color.color[0]
    document.getElementById('result-color-green').value = cfg.result_font_color.color[1]
    document.getElementById('result-color-blue').value = cfg.result_font_color.color[2]

    document.getElementById('window-always-on-top').checked = cfg.window_always_on_top
    document.getElementById('window-visible-on-all-workspaces').checked = cfg.window_visible_on_all_workspaces

}
onSettingsOpen()

var shell = require('electron').shell;
//open links externally by default
$(document).on('click', 'a[href^="http"]', function (event) {
    event.preventDefault();
    shell.openExternal(this.href);
})

$('#kalk-height').on('input', function () {
    let height = parseInt($(this).val())
    if (height >= cfg.win_sz_min.height && height <= cfg.screen_details.height) {
        ipcRendererSettings.send('updateSettings', {
            'win_sz.height': height
        })
    }
})
$('#kalk-width').on('input', function () {
    let width = parseInt($(this).val())
    if (width >= cfg.win_sz_min.width && width <= cfg.screen_details.width) {
        ipcRendererSettings.send('updateSettings', {
            'win_sz.width': width
        })
    }
})

win.on('resize', () => {
    ipcRendererSettings.sendSync('updateSettings', {}, {
        'do': 'set-current-size-as-default',
        'do1': 'set-current-pos-as-default'
    })
    onSettingsOpen()
})

$('#reset-window-size-to-original').on('click', function () {
    ipcRendererSettings.sendSync('updateSettings', {}, {
        'do': 'reset-window-size-to-original'
    })
    onSettingsOpen()
})

win.on('move', function () {
    ipcRendererSettings.sendSync('updateSettings', {}, {
        'do': 'set-current-pos-as-default'
    })
});

$('#reset-window-pos-to-original').on('click', function () {
    ipcRendererSettings.sendSync('updateSettings', {}, {
        'do': 'reset-window-pos-to-original'
    })
})

$('#font-size').on('input', function () {
    let font_size = parseInt($(this).val())
    if (font_size >= cfg.font.min && font_size <= cfg.font.max) {
        ipcRendererSettings.sendSync('updateSettings', {
            'font.font_size': font_size
        })
        win.webContents.send('setKalkSizes')
    }
})

$('#reset-font-size-to-original').on('click', function () {
    win.webContents.send('setKalkSizes', {
        'font_size': cfg.font.default
    })
    ipcRendererSettings.sendSync('updateSettings', {}, {
        'do': 'reset-font-size-to-original'
    })
    onSettingsOpen()
})

$('#reset-background-color-to-original').on('click', function () {
    ipcRendererSettings.sendSync('updateSettings', {}, {
        'do': 'reset-background-color-to-original'
    })
    onSettingsOpen()
    win.webContents.send('setColors')
})

$('#reset-input-color-to-original').on('click', function () {
    ipcRendererSettings.sendSync('updateSettings', {}, {
        'do': 'reset-input-color-to-original'
    })
    onSettingsOpen()
    win.webContents.send('setColors')
})

$('#reset-result-color-to-original').on('click', function () {
    ipcRendererSettings.sendSync('updateSettings', {}, {
        'do': 'reset-result-color-to-original'
    })
    onSettingsOpen()
    win.webContents.send('setColors')
})

$('#background-color-red').on('input', function () {
    let color = parseInt($(this).val())
    ipcRendererSettings.send('updateSettings', {
        'background_color.color[0]': color
    })
    win.webContents.send('setColors')
})

$('#background-color-green').on('input', function () {
    let color = parseInt($(this).val())
    ipcRendererSettings.send('updateSettings', {
        'background_color.color[1]': color
    })
    win.webContents.send('setColors')
})

$('#background-color-blue').on('input', function () {
    let color = parseInt($(this).val())
    ipcRendererSettings.send('updateSettings', {
        'background_color.color[2]': color
    })
    win.webContents.send('setColors')
})

$('#input-color-red').on('input', function () {
    let color = parseInt($(this).val())
    ipcRendererSettings.send('updateSettings', {
        'input_font_color.color[0]': color
    })
    win.webContents.send('setColors')
})

$('#input-color-green').on('input', function () {
    let color = parseInt($(this).val())
    ipcRendererSettings.send('updateSettings', {
        'input_font_color.color[1]': color
    })
    win.webContents.send('setColors')
})

$('#input-color-blue').on('input', function () {
    let color = parseInt($(this).val())
    ipcRendererSettings.send('updateSettings', {
        'input_font_color.color[2]': color
    })
    win.webContents.send('setColors')
})

$('#result-color-red').on('input', function () {
    let color = parseInt($(this).val())
    ipcRendererSettings.send('updateSettings', {
        'result_font_color.color[0]': color
    })
    win.webContents.send('setColors')
})

$('#result-color-green').on('input', function () {
    let color = parseInt($(this).val())
    ipcRendererSettings.send('updateSettings', {
        'result_font_color.color[1]': color
    })
    win.webContents.send('setColors')
})

$('#result-color-blue').on('input', function () {
    let color = parseInt($(this).val())
    ipcRendererSettings.send('updateSettings', {
        'result_font_color.color[2]': color
    })
    win.webContents.send('setColors')
})


$('#window-always-on-top').change(function () {
    ipcRendererSettings.send('updateSettings', {
        'window_always_on_top': this.checked
    })
})

$('#window-visible-on-all-workspaces').change(function () {
    ipcRendererSettings.send('updateSettings', {
        'window_visible_on_all_workspaces': this.checked
    })
})

console.log('renderer_settings')
