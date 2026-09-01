from "%globalsDarg/darg_library.nut" import *
from "blkGetters" import get_settings_blk
from "%globalScripts/controls/shortcutActions.nut" import toggleShortcut
from "%rGui/controls/shortcutSimpleComps.nut" import mkGamepadHotkey
from "%rGui/hud/hudTouchButtonStyle.nut" import touchMenuButtonSize, getSvgImage


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
