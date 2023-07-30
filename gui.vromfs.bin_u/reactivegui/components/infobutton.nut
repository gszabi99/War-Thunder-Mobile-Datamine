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

let gradient = {
  size = flex()
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#gradient_button.svg")
  color = 0xFF16B2E9
}

let iText = {
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  text = "i"
  fontFx = FFT_GLOW
  fontFxFactor = hdpx(64)
  fontFxColor = 0xFF000000
}.__update(fontSmallAccented)

let defSize = [evenPx(70), evenPx(70)]
let function infoBlueButton(onClick, ovr = {}) {
  let size = ovr?.size ?? defSize
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    size
    rendObj = ROBJ_SOLID
    color = 0xFF0593AD
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags(v)
    sound = { click  = "click" }
    onClick
    brightness = stateFlags.value & S_HOVER ? 1.5 : 1
    children = [
      pattern
      gradient
      iText
    ]

    transform = { scale = (stateFlags.value & S_ACTIVE) != 0 ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
  }.__update(ovr)
}

let function infoGreyButton(onClick, ovr = {}) {
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
      iText
    ]
  }.__update(ovr)
}

return {
  infoBlueButton
  infoGreyButton
}
