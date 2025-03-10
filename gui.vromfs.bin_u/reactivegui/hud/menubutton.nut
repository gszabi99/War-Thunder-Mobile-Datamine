from "%globalsDarg/darg_library.nut" import *

let { toggleShortcut } = require("%globalScripts/controls/shortcutActions.nut")
let { touchMenuButtonSize, getSvgImage } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { mkGamepadHotkey } = require("%rGui/controls/shortcutSimpleComps.nut")
let { get_settings_blk } = require("blkGetters")


function mkMenuButton(scale = 1.0, ovr = {}) {
  let size = scaleEven(touchMenuButtonSize, scale)

  return {
    behavior = Behaviors.Button
    cameraControl = true
    rendObj = ROBJ_IMAGE
    size = [size, size]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    image = getSvgImage("hud_menu", size)
    onClick = (get_settings_blk()?.debug.disableInGameMenuButton ?? false) ?
      null : @() toggleShortcut("ID_FLIGHTMENU_SETUP")
    hotkeys = mkGamepadHotkey("ID_FLIGHTMENU")
  }.__update(ovr)
}

let mkMenuButtonEditView = {
  rendObj = ROBJ_IMAGE
  size = [touchMenuButtonSize, touchMenuButtonSize]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  image = getSvgImage("hud_menu", touchMenuButtonSize)
}

return {
  mkMenuButton
  mkMenuButtonEditView
}
