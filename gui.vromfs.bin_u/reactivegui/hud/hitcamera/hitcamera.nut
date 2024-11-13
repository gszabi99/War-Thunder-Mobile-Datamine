from "%globalsDarg/darg_library.nut" import *
let { defer } = require("dagor.workcycle")
let { scaleArr } = require("%globalsDarg/screenMath.nut")
let { getScaledFont } = require("%globalsDarg/fontScale.nut")
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
function resultText(scale) {
  let font = getScaledFont(fontVeryTiny, scale)
  let height = scaleEven(resultBgHeight, scale)
  let padding = scaleArr([hdpx(4), hdpx(10)], scale)
  return function() {
    let res = { watch = hcResult }
    let { locId = "", styleId = ""  } = hcResult.value
    let style = hitResultStyle?[styleId]
    if (style == null)
      return res
    return res.__update(
      {
        size = [SIZE_TO_CONTENT, height]
        hplace = ALIGN_RIGHT
        rendObj = ROBJ_9RECT
        image = gradCircularSqCorners
        texOffs = [gradCircCornerOffset, gradCircCornerOffset]
        screenOffs = array(2, height / 2)
        color = 0x40000000
        padding

        children = {
          maxWidth = maxResultTextWidth
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          halign = ALIGN_RIGHT
          text = utf8ToUpper(loc(locId))
        }.__update(font, style?.text ?? {}),
      }
      style?.bg ?? {})
  }
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

function imageBlock(needResultText, size, scale) {
  let overCamera = [
    needResultText ? resultText(scale) : null
    hitCameraDebuffs(scale)
  ]
  let dmgPanel = hitCameraDmgPanel(scale)
  return @() {
    watch = hcUnitType
    size
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
            children = overCamera
          }
          dmgPanel
        ]
      }
    ]
  }
}

function hitCameraBlock(scale) {
  let size = scaleArr(hitCameraRenderSize, scale)
  return @() {
    watch = [ needShow, needShowImage, useHitResultPlate ]
    key = "hit_camera"
    opacity = needShow.value ? 1.0 : 0.0
    children = {
      flow = FLOW_VERTICAL
      children = [
        needShowImage.get() ? imageBlock(!useHitResultPlate.get(), size, scale) : { size }
        useHitResultPlate.get() ? hitCameraResultPlate(scale) : null
      ]
    }

    //no need to subscribe on hcFadeTime, to not made this logic more complex - appear and fade animations always have same time
    transitions = [{ prop = AnimProp.opacity, duration = hcFadeTime.value }]
  }
}

let hitCamera = @(scale) @() {
  watch = isHcRender
  children = isHcRender.get() ? hitCameraBlock(scale) : null
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