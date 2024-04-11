from "%globalsDarg/darg_library.nut" import *
let { touchButtonSize, btnBgColor,borderColor, borderColorPushed } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { toggleShortcut } = require("%globalScripts/controls/shortcutActions.nut")
let { mkGamepadHotkey, mkGamepadShortcutImage } = require("%rGui/controls/shortcutSimpleComps.nut")
let { defShortcutOvr}  = require("hudButtonsPkg.nut")
let { curActionBarTypes } = require("%rGui/hud/actionBar/actionBarState.nut")

let returnToShipShortcutIds = {
  AB_SUPPORT_PLANE = "ID_WTM_LAUNCH_AIRCRAFT"
  AB_SUPPORT_PLANE_2 = "ID_WTM_LAUNCH_AIRCRAFT_2"
  AB_SUPPORT_PLANE_3 = "ID_WTM_LAUNCH_AIRCRAFT_3"
  AB_SUPPORT_PLANE_4 = "ID_WTM_LAUNCH_AIRCRAFT_4"
}

let defImageSize = (0.75 * touchButtonSize).tointeger()

let mkSquareButtonEditView = @(img){
  size = [touchButtonSize, touchButtonSize]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    @() {
      size = flex()
      rendObj = ROBJ_BOX
      borderColor = borderColor
      borderWidth = [hdpx(3)]
    }
    {
      rendObj = ROBJ_IMAGE
      size = [defImageSize, defImageSize]
      image = Picture($"{img}:{defImageSize}:{defImageSize}:P")
      keepAspect = KEEP_ASPECT_FIT
    }
  ]
}

let returnToShipButton = function() {
  let shortcutId = Computed(@() returnToShipShortcutIds.findvalue(@(_, id) id in curActionBarTypes.get()))
  let stateFlags = Watched(0)
  return @() !shortcutId.get()
    ? { watch = shortcutId }
    : {
      watch = shortcutId
      behavior = Behaviors.Button
      eventPassThrough = true
      size = [touchButtonSize, touchButtonSize]
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      onClick = @() shortcutId.get() ? toggleShortcut(shortcutId.get()) : null
      onElemState = @(v) stateFlags(v)
      hotkeys = mkGamepadHotkey(shortcutId.get())
      children = [
        @() {
          watch = stateFlags
          size = flex()
          rendObj = ROBJ_BOX
          borderColor = (stateFlags.value & S_ACTIVE) != 0 ? borderColorPushed : borderColor
          borderWidth = [hdpx(3)]
          fillColor = btnBgColor.empty
        }
        {
          rendObj = ROBJ_IMAGE
          size = [defImageSize, defImageSize]
          image = Picture($"ui/gameuiskin#hud_ship_selection.svg:{defImageSize}:{defImageSize}:P")
          keepAspect = true
        }
        mkGamepadShortcutImage(shortcutId.get(), defShortcutOvr)
      ]
    }
}

return {
  returnToShipButton
  mkSquareButtonEditView
}