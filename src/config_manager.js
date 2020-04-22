let fs = require('fs')
const path = require('path')

module.exports = class ConfigManager {
	constructor(opt) {
		this.settings_dir = path.join(require('os').homedir(), '.kalk')
		if (!fs.existsSync(this.settings_dir)){
			fs.mkdirSync(this.settings_dir);
		}
		this.cfg_file_name = path.join(this.settings_dir, 'config.json')
		if (!fs.existsSync(this.cfg_file_name)) {
			this.cfg = JSON.parse(JSON.stringify(default_cfg))
			this.save(this.cfg)
		} else {
			this.load()
		}

		if (opt.mode === 'dev') {
			this.cfg.mode = 'dev'
			this.cfg.show_window = true
			this.cfg.show_window_settings = true
		} else {
			this.cfg.mode = 'prod'
			this.cfg.show_window = true
			this.cfg.show_window_settings = false
		}
	}

	save(cfg) {
		let data = JSON.stringify(cfg, null, 4);
		fs.writeFileSync(this.cfg_file_name, data);
	}

	load() {
		let rawdata = fs.readFileSync(this.cfg_file_name);
		this.cfg = JSON.parse(rawdata);
	}
}

const default_cfg = {
	win_sz: {
		width: 400,
		height: 250,
	},
	win_settings_sz: {
		width: 800,
		height: 600
	},
	win_sz_dev: {
		width: 1200,
		height: 840,
	},
	win_settings_sz_dev: {
		width: 1000,
		height: 840,
	},
	win_sz_min: {
		width: 200,
		height: 200
	},
	win_sz_default: {
		width: 400,
		height: 250,
	},
	win_pos: {
		x: null,
		y: null
	},
	win_pos_default: {
		x: null,
		y: null
	},
	win_pos_use_default_pos: true,
	window_visible_on_all_workspaces: true,
	window_always_on_top: true,
	tray_pos: null,
	font: {
		min: 8,
		max: 40,
		default: 18,
		font_size: 18
	},
	background_color: {
		default: [40, 44, 52],
		color: [40, 44, 52]
	},
	input_font_color: {
		default: [255, 255, 255],
		color: [255, 255, 255]
	},
	result_font_color: {
		default: [103, 243, 108],
		color: [103, 243, 108]
	},
	background_color_settings: {
		default: '#FFFFFF',
		color: '#FFFFFF'
	},
	shortuct_listener: {
		default: {
			mac: 'Command+5',
			windows: 'Alt+5',
			linux: 'Alt+5'
		},
		shortcut: 'Alt+5'
	
	},
	mode: null,
	show_window: false,
	show_window_settings: false,
	screen_details: null,

}
