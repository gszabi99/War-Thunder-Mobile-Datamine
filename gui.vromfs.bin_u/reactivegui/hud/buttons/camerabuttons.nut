from "%globalsDarg/darg_library.nut" import *
let { TouchAreaOutButton } = require("wt.behaviors")
let { setShortcutOn, setShortcutOff } = require("%globalScripts/controls/shortcutActions.nut")
let { btnBgColor, touchButtonSize } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { mkGamepadShortcutImage, mkContinuousButtonParams } = require("%rGui/controls/shortcutSimpleComps.nut")

let borderWidth = hdpxi(1)
let colorActive = 0xFFDADADA
let colorInactive = 0x806D6D6D
let imgSizeBase = (touchButtonSize * 0.8  + 0.5).tointeger()

let isActive = @(sf) (sf & S_ACTIVE) != 0

let mkCameraButton = @(shortcutId, image) function(scale) {
  let stateFlags = Watched(0)
  let bgSize = scaleEven(touchButtonSize, scale)
  let imgSize = scaleEven(imgSizeBase, scale)
  let picture = Picture($"{image}:{imgSize}:{imgSize}")
  let onTouchBegin = @() setShortcutOn(shortcutId)
  let onTouchEnd = @() setShortcutOff(shortcutId)
  return @() mkContinuousButtonParams(onTouchBegin, onTouchEnd, shortcutId, stateFlags).__update({
    watch = stateFlags
    size = [bgSize, bgSize]
    rendObj = ROBJ_BOX
    borderColor = isActive(stateFlags.value) ? null : colorInactive
    fillColor = btnBgColor.empty
    borderWidth
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER

    behavior = TouchAreaOutButton
    cameraControl = true

    children = [
      {
        rendObj = ROBJ_IMAGE
        size = [imgSize, imgSize]
        image = picture
        keepAspect = KEEP_ASPECT_FIT
        color = stateFlags.value ? colorActive : colorInactive
      }
      mkGamepadShortcutImage(shortcutId,
        { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = [pw(50), ph(50)] },
        scale)
    ]
  })
}

return {
  mkFreeCameraButton = mkCameraButton("ID_CAMERA_NEUTRAL", "ui/gameuiskin#hud_free_camera.svg")
  mkViewBackButton = mkCameraButton("ID_CAMERA_VIEW_BACK", "ui/gameuiskin#hud_look_back.svg")
}
