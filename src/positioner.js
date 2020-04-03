module.exports = computeWinPosDefualt = (cfg) => {
    let win_pos_default = {x: cfg.tray_pos.x, y: cfg.tray_pos.y}

    if ((cfg.tray_pos.x + cfg.win_sz.width) > cfg.screen_details.width) {
        win_pos_default.x = cfg.screen_details.width - cfg.win_sz.width
    }

    if ((cfg.tray_pos.y + cfg.win_sz.height) > cfg.screen_details.height) {
        win_pos_default.y = cfg.screen_details.height - cfg.win_sz.height
    }

    win_pos_default.x -= Math.floor((cfg.win_sz.width) / 2) - 8
    
    return win_pos_default
}
