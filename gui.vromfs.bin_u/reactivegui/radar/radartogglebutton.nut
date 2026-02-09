from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { touchButtonSize, btnBgStyle, borderColor, borderColorPushed, borderWidth
} = require("%rGui/hud/hudTouchButtonStyle.nut")
let radarState = require("%rGui/radar/radarState.nut")
let { TrackerVisible } = require("%rGui/rocketAim/rocketAamAimState.nut")
let { unlockGuidedTargets, activateTargetLock } = require("guiRadar")

let defImageSize = (0.75 * touchButtonSize).tointeger()
let imgMap = "ui/gameuiskin#hud_switcher_map.svg"
let imgRadar = "ui/gameuiskin#hud_switcher_radar.svg"

let mkRadarToggleButtonEditView = {
  size = [touchButtonSize, touchButtonSize]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    @() {
      size = flex()
      rendObj = ROBJ_BOX
      borderColor = borderColor
      borderWidth
    }
    {
      rendObj = ROBJ_IMAGE
      size = [defImageSize, defImageSize]
      image = Picture($"{imgRadar}:{defImageSize}:{defImageSize}:P")
      keepAspect = KEEP_ASPECT_FIT
    }
  ]
}

function toggleRadar() {
  if (radarState.showRadarOverMap.get()) {
    unlockGuidedTargets(TRIGGER_GROUP_SPECIAL_GUN)
  } else {
    activateTargetLock(TRIGGER_GROUP_SPECIAL_GUN)
  }
  radarState.showRadarOverMap.set(!radarState.showRadarOverMap.get())
}

TrackerVisible.subscribe(@(v)
  v && radarState.IsRadarHudVisible.get() && radarState.IsRadarVisible.get() && radarState.IsBScopeVisible.get()
  ? radarState.showRadarOverMap.set(true) : null
)

function mkRadarToggleButton(scale) {
  let showRadarOverMapW = radarState.showRadarOverMap
  let stateFlags = Watched(0)
  let bgSize = scaleEven(touchButtonSize, scale)
  let imgSize = scaleEven(defImageSize, scale)
  let borderW = round(borderWidth * scale)
  return @() {
      behavior = Behaviors.Button
      size = [bgSize, bgSize]
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      onClick = @() toggleRadar()
      onElemState = @(v) stateFlags.set(v)
      children = [
        @() {
          watch = [stateFlags, btnBgStyle]
          size = flex()
          rendObj = ROBJ_BOX
          borderColor = (stateFlags.get() & S_ACTIVE) != 0 ? borderColorPushed : borderColor
          borderWidth = borderW
          fillColor = btnBgStyle.get().empty
        }
        @() {
          watch = showRadarOverMapW
          rendObj = ROBJ_IMAGE
          size = [imgSize, imgSize]
          image = Picture($"{showRadarOverMapW.get() ? imgMap : imgRadar}:{imgSize}:{imgSize}:P")
          keepAspect = true
        }
      ]
    }
}

return {
  mkRadarToggleButton
  mkRadarToggleButtonEditView
}