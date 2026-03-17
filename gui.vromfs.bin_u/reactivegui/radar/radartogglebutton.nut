from "%globalsDarg/darg_library.nut" import *
let { getBorderCommand, COMMADN_STATE } = require("%rGui/components/translucentButton.nut")
let { borderColor, borderWidth } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { tacticalMapSize } = require("%rGui/hud/components/tacticalMap.nut")
let radarState = require("%rGui/radar/radarState.nut")
let { TrackerVisible } = require("%rGui/rocketAim/rocketAamAimState.nut")
let { unlockGuidedTargets, activateTargetLock } = require("guiRadar")


let imgMultiplier = 0.75
let btnGap = hdpx(8)

let toggleBtnH = tacticalMapSize[1] / 5
let toggleBtnW = toggleBtnH * 1.08

let toggleActiveBtnH = toggleBtnW
let toggleActiveBtnW = toggleActiveBtnH * 1.14

let defImageSize = (imgMultiplier * toggleBtnH).tointeger()
let imgMap = "ui/gameuiskin#hud_switcher_map.svg"
let imgRadar = "ui/gameuiskin#hud_switcher_radar.svg"

let mkImg = @(image, size) {
  rendObj = ROBJ_IMAGE
  size = [size, size]
  image = Picture($"{image}:{size}:{size}:P")
  keepAspect = KEEP_ASPECT_FIT
}

let mkRadarBorderCommand = @(color, width) [
  [VECTOR_COLOR, color],
  [VECTOR_WIDTH, width]
].extend(getBorderCommand(COMMADN_STATE.RIGHT))

let mkRadarToggleButtonEditView = {
  flow = FLOW_VERTICAL
  gap = btnGap
  children = [
    {
      size = [toggleActiveBtnW, toggleActiveBtnH]
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      rendObj = ROBJ_VECTOR_CANVAS
      fillColor = 0x00000000
      commands = mkRadarBorderCommand(borderColor, borderWidth)
      children = mkImg(imgMap, defImageSize)
    }
    {
      size = [toggleBtnW, toggleBtnH]
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      rendObj = ROBJ_VECTOR_CANVAS
      fillColor = 0x00000000
      commands = mkRadarBorderCommand(borderColor, borderWidth)
      children = mkImg(imgRadar, defImageSize)
    }
  ]
}

TrackerVisible.subscribe(@(v)
  v && radarState.IsRadarHudVisible.get() && radarState.IsRadarVisible.get() && radarState.IsBScopeVisible.get()
  ? radarState.showRadarOverMap.set(true) : null
)

function mkRadarToggleButton(scale) {
  let showRadarOverMapW = radarState.showRadarOverMap
  let btnW = scaleEven(toggleBtnW, scale)
  let btnH = scaleEven(toggleBtnH, scale)
  let activeBtnW = scaleEven(toggleActiveBtnW, scale)
  let activeBtnH = scaleEven(toggleActiveBtnH, scale)

  let imgSize = scaleEven(toggleBtnH * imgMultiplier, scale)
  let imgActiveSize = scaleEven(toggleActiveBtnH * imgMultiplier, scale)
  return function() {
    let mapImgSize = showRadarOverMapW.get() ? imgSize : imgActiveSize
    let radarImgSize = showRadarOverMapW.get() ? imgActiveSize : imgSize
    return {
      watch = showRadarOverMapW
      flow = FLOW_VERTICAL
      gap = btnGap
      children = [
        {
          behavior = Behaviors.Button
          size = showRadarOverMapW.get() ? [btnW, btnH] : [activeBtnW, activeBtnH]
          valign = ALIGN_CENTER
          halign = ALIGN_CENTER
          function onClick() {
            unlockGuidedTargets(TRIGGER_GROUP_SPECIAL_GUN)
            radarState.showRadarOverMap.set(false)
          }
          children = {
            size = showRadarOverMapW.get() ? [btnW, btnH] : [activeBtnW, activeBtnH]
            valign = ALIGN_CENTER
            halign = ALIGN_CENTER
            rendObj = ROBJ_VECTOR_CANVAS
            lineWidth = 0
            fillColor = 0x80000000
            borderColor = 0x80000000
            commands = mkRadarBorderCommand(0, 0)
            children = mkImg(imgMap, mapImgSize).__update({ opacity = showRadarOverMapW.get() ? 0.5 : 1 })
          }
        }
        {
          behavior = Behaviors.Button
          size = showRadarOverMapW.get() ? [activeBtnW, activeBtnH] : [btnW, btnH]
          valign = ALIGN_CENTER
          halign = ALIGN_CENTER
          function onClick() {
            activateTargetLock(TRIGGER_GROUP_SPECIAL_GUN)
            radarState.showRadarOverMap.set(true)
          }
          children = {
            size = showRadarOverMapW.get() ? [activeBtnW, activeBtnH] : [btnW, btnH]
            valign = ALIGN_CENTER
            halign = ALIGN_CENTER
            rendObj = ROBJ_VECTOR_CANVAS
            lineWidth = 0
            fillColor = 0x80000000
            borderColor = 0x80000000
            commands = mkRadarBorderCommand(0, 0)
            children = mkImg(imgRadar, radarImgSize).__update({ opacity = showRadarOverMapW.get() ? 1 : 0.5 })
          }
        }
      ]
    }
  }
}

return {
  mkRadarToggleButton
  mkRadarToggleButtonEditView
}