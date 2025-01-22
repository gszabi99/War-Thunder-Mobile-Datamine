import "daRg.behaviors" as Behaviors

let { toggleShortcut } = require("%globalScripts/controls/shortcutActions.nut")
let { touchMenuButtonSize, getSvgImage } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { mkGamepadHotkey } = require("%rGui/controls/shortcutSimpleComps.nut")
let { get_settings_blk } = require("blkGetters")


let menuImage = getSvgImage("hud_menu", touchMenuButtonSize)

let mkMenuButton = @(overrideParams = {}) {
  behavior = Behaviors.Button
  cameraControl = true
  rendObj = ROBJ_IMAGE
  size = [touchMenuButtonSize, touchMenuButtonSize]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  image = menuImage
  onClick = (get_settings_blk()?.debug.disableInGameMenuButton ?? false) ?
    null : @() toggleShortcut("ID_FLIGHTMENU_SETUP")
  hotkeys = mkGamepadHotkey("ID_FLIGHTMENU")
}.__update(overrideParams)

return mkMenuButton
