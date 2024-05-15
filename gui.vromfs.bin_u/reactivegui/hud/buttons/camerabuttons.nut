from "%globalsDarg/darg_library.nut" import *
let { TouchAreaOutButton } = require("wt.behaviors")
let { setShortcutOn, setShortcutOff } = require("%globalScripts/controls/shortcutActions.nut")
let { btnBgColor, touchButtonSize } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { mkGamepadShortcutImage, mkGamepadHotkey } = require("%rGui/controls/shortcutSimpleComps.nut")

let borderWidth = hdpxi(1)
let colorActive = 0xFFDADADA
let colorInactive = 0x806D6D6D
let imgSize = (touchButtonSize * 0.8  + 0.5).tointeger()

let isActive = @(sf) (sf & S_ACTIVE) != 0

function mkCameraButton(shortcutId, image) {
  return function(ovr = {}) {
    let stateFlags = Watched(0)
    let picture = Picture($"{image}:{imgSize}:{imgSize}")

    return @() {
      size = [touchButtonSize, touchButtonSize]
      watch = stateFlags
      rendObj = ROBJ_BOX
      borderColor = isActive(stateFlags.value) ? null : colorInactive
      fillColor = btnBgColor.empty
      borderWidth
      hotkeys = mkGamepadHotkey(shortcutId)
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      behavior = TouchAreaOutButton
      eventPassThrough = true
      children = [
        {
          rendObj = ROBJ_IMAGE
          size = [imgSize, imgSize]
          image = picture
          keepAspect = KEEP_ASPECT_FIT
          color = stateFlags.value ? colorActive : colorInactive
        }
        mkGamepadShortcutImage(shortcutId, { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = [pw(50), ph(50)] })
      ]
      onElemState = function onElemState(sf) {
        let prevSf = stateFlags.value
        stateFlags(sf)
        let active = isActive(sf)
        if (active != isActive(prevSf))
          if (active)
            setShortcutOn(shortcutId)
          else
            setShortcutOff(shortcutId)
      }
      function onDetach() {
        stateFlags(0)
        setShortcutOff(shortcutId)
      }
    }.__update(ovr)
  }
}

return {
  mkFreeCameraButton = mkCameraButton("ID_CAMERA_NEUTRAL", "ui/gameuiskin#hud_free_camera.svg")
  mkViewBackButton = mkCameraButton("ID_CAMERA_VIEW_BACK", "ui/gameuiskin#hud_look_back.svg")
}
