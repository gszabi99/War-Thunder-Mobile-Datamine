from "%globalsDarg/darg_library.nut" import *
let { setShortcutOn, setShortcutOff } = require("%globalScripts/controls/shortcutActions.nut")
let { btnBgColor, touchButtonSize } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { mkGamepadShortcutImage, mkGamepadHotkey } = require("%rGui/controls/shortcutSimpleComps.nut")

let borderWidth = hdpxi(1)
let colorActive = 0xFFDADADA
let colorInactive = 0x806D6D6D
let imgSize = (touchButtonSize * 0.8  + 0.5).tointeger()

let isActive = @(sf) (sf & S_ACTIVE) != 0
let shortcutId = "ID_CAMERA_NEUTRAL"

let function mkFreeCameraButton(ovr = {}) {
  let stateFlags = Watched(0)
  let picture = Picture($"ui/gameuiskin#hud_free_camera.svg:{imgSize}:{imgSize}")

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
    behavior = Behaviors.TouchAreaOutButton
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
          setShortcutOn("ID_CAMERA_NEUTRAL")
        else
          setShortcutOff("ID_CAMERA_NEUTRAL")
    }
    function onDetach() {
      stateFlags(0)
      setShortcutOff("ID_CAMERA_NEUTRAL")
    }
  }.__update(ovr)
}

return mkFreeCameraButton
