from "%globalsDarg/darg_library.nut" import *

let patternSize = hdpxi(110)
let pattern = {
  size = flex()
  clipChildren = true
  children = {
    size = [patternSize, patternSize]
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#button_pattern.svg:{patternSize}:{patternSize}")
    color = 0x23000000
  }
}

let gradientCommon = {
  size = flex()
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#gradient_button.svg")
  color = 0xFF848484
}

let gradientPrimary = gradientCommon.__merge({ color = 0xFF16B2E9 })

let iText = {
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  text = "i"
  fontFx = FFT_GLOW
  fontFxFactor = hdpx(64)
  fontFxColor = 0xFF000000
}

let defSize = [evenPx(70), evenPx(70)]
let mkInfoButtonCtor = @(bgColor, gradient) function(onClick, ovr = {}, textOvr = fontSmallAccented) {
  let size = ovr?.size ?? defSize
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    size
    rendObj = ROBJ_SOLID
    color = bgColor
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags(v)
    xmbNode = {}
    sound = { click  = "click" }
    onClick
    brightness = stateFlags.value & S_HOVER ? 1.5 : 1
    children = [
      pattern
      gradient
      iText.__merge(textOvr)
    ]

    transform = { scale = (stateFlags.value & S_ACTIVE) != 0 ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
  }.__update(ovr)
}

let infoBlueButton = mkInfoButtonCtor(0xFF0593AD, gradientPrimary)
let infoCommonButton = mkInfoButtonCtor(0xFF646464, gradientCommon)

let function infoGreyButton(onClick, ovr = {}, textOvr = fontSmallAccented) {
  let size = ovr?.size ?? defSize
  return @() {
    size
    rendObj = ROBJ_SOLID
    behavior = Behaviors.Button
    onClick
    color = 0x28262626
    children = [
      {
        size = flex()
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#gradient_button.svg")
        color = 0x0A262626
      }
      iText.__merge(textOvr)
    ]
  }.__update(ovr)
}

return {
  infoBlueButton
  infoGreyButton
  infoCommonButton
}
