let { toggleShortcut } = require("%globalScripts/controls/shortcutActions.nut")
let { touchMenuButtonSize, getSvgImage } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { mkGamepadHotkey } = require("%rGui/controls/shortcutSimpleComps.nut")

let menuImage = getSvgImage("hud_menu", touchMenuButtonSize)

let mkMenuButton = @(overrideParams = {}) {
  behavior = Behaviors.Button
  rendObj = ROBJ_IMAGE
  size = [touchMenuButtonSize, touchMenuButtonSize]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  image = menuImage
  onClick = @() toggleShortcut("ID_FLIGHTMENU_SETUP")
  hotkeys = mkGamepadHotkey("ID_FLIGHTMENU")
}.__update(overrideParams)

return mkMenuButton
