from "%globalsDarg/darg_library.nut" import *
let { defer } = require("dagor.workcycle")
let { isHcRender, shouldShowHc, isHcUnitHit, hcUnitType, hcFadeTime, hcResult, hcRelativeHealth
} = require("%rGui/hud/hitCamera/hitCameraState.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { hitCameraRenderSize, hitResultStyle } = require("%rGui/hud/hitCamera/hitCameraConfig.nut")
let hitCameraDmgPanel = require("hitCameraDmgPanel.nut")
let hitCameraDebuffs = require("hitCameraDebuffs.nut")
let { hitCameraResultPlate, hitResultPlateHeight } = require("hitCameraResultPlate.nut")
let { gradCircularSqCorners, gradCircCornerOffset, simpleHorGrad } = require("%rGui/style/gradients.nut")
let { borderColor } = require("%rGui/hud/hudTouchButtonStyle.nut")

let maxResultTextWidth = hdpx(330)
let needShow = Watched(shouldShowHc.value)
//delay need to correct play animation on show by transition
//transition need to correct count opacity when hide before appear is finished
shouldShowHc.subscribe(@(v) v ? defer(@() needShow(shouldShowHc.value)) : needShow(v))

let needShowImage = Computed(@() hcUnitType.value != "tank" || isHcUnitHit.value)
let useHitResultPlate = Computed(@() hcUnitType.value == "tank")

let hitCamBgColor = {
  ship = 0x44000000
  tank = 0xFF706E62
}

let resultBgHeight = evenPx(36)
function resultText() {
  let res = { watch = hcResult }
  let { locId = "", styleId = ""  } = hcResult.value
  let style = hitResultStyle?[styleId]
  if (style == null)
    return res
  return res.__update(
    {
      size = [SIZE_TO_CONTENT, resultBgHeight]
      hplace = ALIGN_RIGHT
      rendObj = ROBJ_9RECT
      image = gradCircularSqCorners
      texOffs = [gradCircCornerOffset, gradCircCornerOffset]
      screenOffs = array(2, resultBgHeight / 2)
      color = 0x40000000
      padding = [hdpx(4), hdpx(10)]

      children = {
        maxWidth = maxResultTextWidth
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        halign = ALIGN_RIGHT
        text = utf8ToUpper(loc(locId))
      }.__update(fontVeryTiny, style?.text ?? {}),
    }
    style?.bg ?? {})
}

let mkHealthGrad = @(isLeft, color, part) {
  rendObj = ROBJ_IMAGE
  size = [pw(50 * part), flex()]
  flipX = isLeft
  image = simpleHorGrad
  color
  opacity = part
  hplace = isLeft ? ALIGN_LEFT : ALIGN_RIGHT
}

function healthHiglight() {
  let color = hcRelativeHealth.value >= 0.8 ? 0
    : hcRelativeHealth.value >= 0.3 ? 0x80806000
    : 0XA0A03030
  let part = (0.8 - hcRelativeHealth.value) / 0.8
  return {
    watch = hcRelativeHealth
    size = flex()
    children = color == 0 ? null
      : [
          mkHealthGrad(true, color, part)
          mkHealthGrad(false, color, part)
        ]
  }
}

let imageBlock = @() {
  watch = hcUnitType
  size = hitCameraRenderSize
  rendObj = ROBJ_SOLID
  color = hitCamBgColor?[hcUnitType.value] ?? hitCamBgColor.ship
  children = [
    healthHiglight
    {
      size = flex()
      flow = FLOW_VERTICAL
      children = [
        {
          size = flex()
          rendObj = ROBJ_HIT_CAMERA
          children = [
            useHitResultPlate.value ? null : resultText
            hitCameraDebuffs
          ]
        }
        hitCameraDmgPanel
      ]
    }
  ]
}

let hitCameraBlock = @() {
  watch = [ needShow, needShowImage, useHitResultPlate ]
  key = "hit_camera"
  opacity = needShow.value ? 1.0 : 0.0
  children = {
    flow = FLOW_VERTICAL
    children = [
      needShowImage.value
        ? imageBlock
        : { size = hitCameraRenderSize }
      useHitResultPlate.value ? hitCameraResultPlate : null
    ]
  }

  //no need to subscribe on hcFadeTime, to not made this logic more complex - appear and fade animations always have same time
  transitions = [{ prop = AnimProp.opacity, duration = hcFadeTime.value }]
}

let hitCamera = @() {
  watch = isHcRender
  children = isHcRender.value ? hitCameraBlock : null
}

let hitCameraEditView = {
  rendObj = ROBJ_BOX
  borderWidth = hdpx(3)
  borderColor
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text = loc("options/xray_kill")
  }.__update(fontSmall)
}

let hitCameraCommonEditView = hitCameraEditView.__merge({ size = hitCameraRenderSize })
let hitCameraTankEditView = hitCameraEditView.__merge(
  { size = [hitCameraRenderSize[0], hitCameraRenderSize[1] + hitResultPlateHeight] })

return {
  hitCamera
  hitCameraCommonEditView
  hitCameraTankEditView
}