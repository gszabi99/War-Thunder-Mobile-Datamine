from "%globalsDarg/darg_library.nut" import *
let { hoverColor } = require("%rGui/style/stdColors.nut")

let iconBgWidth  = hdpx(115)
let translucentButtonsHeight = evenPx(95)
let iconSizeDefault  = evenPx(65)
let lineWidth = hdpx(2)
let maxTextWidth = hdpx(450)

let translucentButtonsVGap = hdpx(30)

let isActive = @(sf) (sf & S_ACTIVE) != 0

let textColor = 0xFFFFFFFF

let btnBg = {
  size  = flex()
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = lineWidth
  fillColor = 0x60000000
  commands = [[VECTOR_POLY, 0, 0, 82, 0, 100, 26, 100, 100, 0, 100, 0, 0]]
}

function translucentButton(icon, text, onClick, mkChild = null, ovr = {}) {
  let stateFlags = Watched(0)
  let iconSize = ovr?.iconSize ?? iconSizeDefault
  return @() {
    behavior = Behaviors.Button
    watch = stateFlags
    size = ovr?.size ?? [SIZE_TO_CONTENT, translucentButtonsHeight]
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = translucentButtonsVGap
    onElemState = @(v) stateFlags(v)
    sound = {
      click  = "click"
    }
    onClick
    transform = {
      scale = isActive(stateFlags.value) ? [0.95, 0.95] : [1, 1]
    }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = Linear }]
    children = [
      {
        size = ovr?.size ?? [ iconBgWidth, translucentButtonsHeight - lineWidth * 2 ]
        children = [
          btnBg.__merge({ color = stateFlags.value & S_HOVER ? hoverColor : 0xFFA0A0A0 })
          {
            rendObj = ROBJ_IMAGE
            size = [ iconSize, iconSize ]
            hplace = ALIGN_CENTER
            vplace = ALIGN_CENTER
            color = stateFlags.value & S_HOVER ? hoverColor : textColor
            image = Picture($"{icon}:{iconSize}:{iconSize}:P")
            keepAspect = KEEP_ASPECT_FIT
          }
          mkChild?(stateFlags.value)
        ]
      }
      text == "" ? null : {
        size = [SIZE_TO_CONTENT, flex()]
        maxWidth = maxTextWidth
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        valign = ALIGN_CENTER
        color = stateFlags.value & S_HOVER ? hoverColor : textColor
        text
        fontFx = FFT_GLOW
        fontFxFactor = 64
        fontFxColor = Color(0, 0, 0)
      }.__update(fontSmallAccented)
    ]
  }
}

function translucentIconButton(image, onClick, imageSize = iconSizeDefault, bgSize = [ iconBgWidth, translucentButtonsHeight ], mkChild = null) {
  let stateFlags = Watched(0)
  return @() btnBg.__merge({
    watch = stateFlags
    size = bgSize
    color = stateFlags.value & S_HOVER ? hoverColor : 0xFFA0A0A0
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags(v)
    sound = { click  = "click" }
    onClick
    children = [
      {
        rendObj = ROBJ_IMAGE
        size = [ imageSize, imageSize ]
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        color = stateFlags.value & S_HOVER ? hoverColor : textColor
        image = Picture($"{image}:{imageSize}:{imageSize}:P")
        keepAspect = true
      }
      mkChild?(stateFlags.value)
    ]
    transform = { scale = isActive(stateFlags.value) ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = Linear }]
  })
}

return {
  translucentButton
  translucentIconButton
  translucentButtonsVGap
  translucentButtonsHeight
}
