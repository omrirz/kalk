const electron = require('electron')

const {
  app,
  Menu,
  Tray,
  BrowserWindow,
  globalShortcut,
  nativeTheme
} = require('electron')


const ipc = require('electron').ipcMain
const path = require('path')
const url = require('url')
const _ = require('lodash')

let ConfigManager = require('./src/config_manager')
let computeWinPosDefualt = require('./src/positioner')

// template for menu for copy, paste etc.
const template = require('./src/app_menu').template

// tray and window objects
let tray = null
let win = null

let configManager = new ConfigManager({mode: 'prod'})
let cfg = configManager.cfg
global.configManager = configManager
global.cfg = cfg


ipc.on('updateSettings', (event, to_update, opt) => {
  for (var key in to_update) {
    _.set(cfg, key, to_update[key])
    if (key === 'win_sz.height' || key === 'win_sz.width') {
      win.setSize(cfg.win_sz.width, cfg.win_sz.height)
    }
    if (key === 'window_always_on_top') {
      win.setAlwaysOnTop(to_update[key])
    }
    if (key === 'window_visible_on_all_workspaces') {
      win.setVisibleOnAllWorkspaces(to_update[key])
    }
  }
  for (var key in opt) {
    if (opt[key] === 'set-current-size-as-default') {
      let new_sz = (({ width, height }) => ({ width, height }))(win.getBounds())
      if (new_sz.width >= cfg.win_sz_min.width && new_sz.width <= cfg.screen_details.width &&
        new_sz.height >= cfg.win_sz_min.height && new_sz.height <= cfg.screen_details.height) {
        cfg.win_sz = new_sz
        win.setSize(cfg.win_sz.width, cfg.win_sz.height)
      }
    }
    if (opt[key] === 'reset-window-size-to-original') {
      cfg.win_sz = JSON.parse(JSON.stringify(cfg.win_sz_default))
      win.setSize(cfg.win_sz_default.width, cfg.win_sz_default.height)
    }
    if (opt[key] === 'set-current-pos-as-default') {
      let new_pos = (({ x, y }) => ({ x, y }))(win.getBounds())
      cfg.win_pos = new_pos
      cfg.win_pos_use_default_pos = false
    }
    if (opt[key] === 'reset-window-pos-to-original') {
      cfg.win_pos.x = null
      cfg.win_pos.y = null
      cfg.win_pos_use_default_pos = true
      win.setPosition(cfg.win_pos_default.x, cfg.win_pos_default.y, true)
    }
    if (opt[key] === 'reset-font-size-to-original') {
      cfg.font.font_size = cfg.font.default
    }
    if (opt[key] === 'reset-background-color-to-original') {
      cfg.background_color.color = JSON.parse(JSON.stringify(cfg.background_color.default))
    }
    if (opt[key] === 'reset-input-color-to-original') {
      cfg.input_font_color.color = JSON.parse(JSON.stringify(cfg.input_font_color.default))
    }
    if (opt[key] === 'reset-result-color-to-original') {
      cfg.result_font_color.color = JSON.parse(JSON.stringify(cfg.result_font_color.default))
    }

  }
  event.returnValue = cfg
  configManager.save(cfg)
})

if (process.platform === 'darwin') {
  cfg.shortuct_listener.shortcut = cfg.shortuct_listener.default.mac
  if (cfg.mode !== 'dev') {
    app.dock.hide()
  }
}
if (process.platform === 'win32') {
  cfg.shortuct_listener.shortcut = cfg.shortuct_listener.default.windows
}

const getIconPath = () => {
  let iconName = nativeTheme.shouldUseDarkColors ? 'icon_dark.png': 'icon.png';
  if (process.platform === 'win32') {
    iconName = 'icon_dark.png';
  }
  const iconPath = path.join(__dirname, 'src', 'assets', iconName);
  return iconPath
}


app.on('ready', () => {

  const iconPath = getIconPath()
  tray = new Tray(iconPath)

  // set menu for copy, paste etc.
  const menu = Menu.buildFromTemplate(template)
  Menu.setApplicationMenu(menu)


  // set config variables
  cfg.tray_pos = tray.getBounds()

  cfg.screen_details = electron.screen.getPrimaryDisplay().workArea

  cfg.win_pos_default = computeWinPosDefualt(cfg)

  // set window position to default
  if (cfg.win_pos_use_default_pos) {
    cfg.win_pos.x = JSON.parse(JSON.stringify(cfg.win_pos_default.x))
    cfg.win_pos.y = JSON.parse(JSON.stringify(cfg.win_pos_default.y))
  }

  // tooltip for hovering the app icon
  tray.setToolTip('Kalk')

  // show window on click
  tray.on('click', () => {
    win.isVisible() ? win.hide() : win.show()
  })

  // settings button from index
  ipc.on('toggleSettings', function (event, data) {
    win_settings.isVisible() ? win_settings.hide() : win_settings.show()
  })

  // close app from settings
  ipc.on('closeApp', (evt, arg) => {
    app.quit()
  })


  // create the caclculator window
  win = new BrowserWindow({
    webPreferences: {
      nodeIntegration: true
    },
    // backgroundColor: cfg.background_color.color,
    width: cfg.mode === 'dev' ? cfg.win_sz_dev.width : cfg.win_sz.width,
    height: cfg.mode === 'dev' ? cfg.win_sz_dev.height : cfg.win_sz.height,
    minHeight: cfg.win_sz_min.height,
    minWidth: cfg.win_sz_min.width,
    x: cfg.win_pos.x,
    y: cfg.win_pos.y,
    frame: false,
    show: cfg.show_window,
    // transparent: true,
    icon: './assets/icon.png'
  })
  global.win = win

  // create the setings window
  win_settings = new BrowserWindow({
    webPreferences: {
      nodeIntegration: true
    },
    // backgroundColor: cfg.background_color_settings.color,
    width: cfg.mode === 'dev' ? cfg.win_settings_sz_dev.width : cfg.win_settings_sz.width,
    height: cfg.mode === 'dev' ? cfg.win_settings_sz_dev.height : cfg.win_settings_sz.height,
    minHeight: cfg.win_settings_sz.height,
    minWidth: cfg.win_settings_sz.width,
    x: _.floor(cfg.screen_details.width / 2) - _.floor((cfg.win_settings_sz.width) / 2),
    y: _.floor(cfg.screen_details.height / 2) - _.floor((cfg.win_settings_sz.height) / 2),
    frame: false,
    show: cfg.show_window_settings
  })
  global.win = win

    // make the window allways on top
    if (cfg.window_always_on_top) {
      win.setAlwaysOnTop(true)
    }

  // available in all workspaces on mac e.g. on tray click it will show
  // in current desktop
  if (cfg.window_visible_on_all_workspaces) {
    win.setVisibleOnAllWorkspaces(true)
  }

  win.focus()

  // no menu for app
  win.setMenu(null)

  // Show dev tools
  if (cfg.mode === 'dev') {
    win.webContents.openDevTools()
    win_settings.webContents.openDevTools()
  }

  nativeTheme.on('updated', () => {
    const iconPath = getIconPath()
    tray.setImage(iconPath)
  })


  win.loadURL(url.format({
    pathname: path.join(__dirname, './src/kalk.html'),
    protocol: 'file:',
    slashes: true
  }))

  win_settings.loadURL(url.format({
    pathname: path.join(__dirname, './src/settings.html'),
    protocol: 'file:',
    slashes: true
  }))

  // Register a shortcut listener.
  globalShortcut.register(cfg.shortuct_listener.shortcut, () => {
    win.isVisible() ? win.hide() : win.show()
  })


})

app.on('will-quit', () => {
  // Unregister a shortcut.
  globalShortcut.unregister(cfg.shortuct_listener.shortcut)

  // Unregister all shortcuts.
  globalShortcut.unregisterAll()
})

console.log('main')