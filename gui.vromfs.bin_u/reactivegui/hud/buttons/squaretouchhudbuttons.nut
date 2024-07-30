from "%globalsDarg/darg_library.nut" import *
let { touchButtonSize, btnBgColor,borderColor, borderColorPushed } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { toggleShortcut } = require("%globalScripts/controls/shortcutActions.nut")
let { mkGamepadHotkey, mkGamepadShortcutImage } = require("%rGui/controls/shortcutSimpleComps.nut")
let { defShortcutOvr}  = require("hudButtonsPkg.nut")

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

function mkSimpleSquareButton(shortcutId, img) {
  let stateFlags = Watched(0)
  return @() {
      behavior = Behaviors.Button
      eventPassThrough = true
      size = [touchButtonSize, touchButtonSize]
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      onClick = @() toggleShortcut(shortcutId)
      onElemState = @(v) stateFlags(v)
      hotkeys = mkGamepadHotkey(shortcutId)
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
          image = Picture($"{img}:{defImageSize}:{defImageSize}:P")
          keepAspect = true
        }
        mkGamepadShortcutImage(shortcutId, defShortcutOvr)
      ]
    }
}

return {
  mkSimpleSquareButton
  mkSquareButtonEditView
}