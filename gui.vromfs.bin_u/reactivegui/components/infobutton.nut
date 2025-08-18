from "%globalsDarg/darg_library.nut" import *
let { hoverColor, premiumTextColor } = require("%rGui/style/stdColors.nut")
let { withTooltip, tooltipDetach } = require("%rGui/tooltip.nut")

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

let gradientPremium = gradientCommon.__merge({ color = premiumTextColor })
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
let defSizeSmall = [evenPx(50), evenPx(50)]
let defSizeMedium = [evenPx(60), evenPx(60)]

let mkInfoButtonCtor = @(bgColor, gradient) function(onClick, ovr = {}, textOvr = fontSmallAccented) {
  let size = ovr?.size ?? defSize
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    size
    rendObj = ROBJ_SOLID
    color = bgColor
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags.set(v)
    xmbNode = {}
    sound = { click  = "click" }
    onClick
    brightness = stateFlags.get() & S_HOVER ? 1.5 : 1
    children = [
      pattern
      gradient
      iText.__merge(textOvr)
    ]

    transform = { scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
  }.__update(ovr)
}

let mkInfoEllipseButtonCtor = @(borderColor, fillColor) function(onClick, ovr = {}, textOvr = fontSmallAccented) {
  let size = ovr?.size ?? defSizeMedium
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    size
    rendObj = ROBJ_VECTOR_CANVAS
    lineWidth = hdpxi(2)
    fillColor = fillColor
    color = borderColor
    commands = [[VECTOR_ELLIPSE, 50, 50, 50, 50]]
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags.set(v)
    xmbNode = {}
    sound = { click  = "click" }
    onClick
    brightness = stateFlags.get() & S_HOVER ? 1.5 : 1
    children = [
      iText.__merge(textOvr)
    ]

    transform = { scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
  }.__update(ovr)
}

let infoGoldButton = mkInfoButtonCtor(0xFFAA7305, gradientPremium)
let infoBlueButton = mkInfoButtonCtor(0xFF0593AD, gradientPrimary)
let infoCommonButton = mkInfoButtonCtor(0xFF646464, gradientCommon)
let infoEllipseButton = mkInfoEllipseButtonCtor( 0x80AAAAAA, 0x80000000)

function infoGreyButton(onClick, ovr = {}, textOvr = fontSmallAccented) {
  let size = ovr?.size ?? defSize
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    size
    rendObj = ROBJ_SOLID
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags.set(sf)
    onClick
    color = 0x28262626
    children = iText.__merge(textOvr)
    transform = { scale = stateFlags.get() & S_ACTIVE ? [0.8, 0.8] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.3, easing = Linear }]
  }.__update(ovr)
}

function infoRhombButton(onClick, ovr = {}, textOvr = fontSmallAccented) {
  let stateFlags = Watched(0)
  let size = ovr?.size ?? defSizeSmall

  return @() {
    watch = stateFlags
    size
    behavior = Behaviors.Button
    onClick
    sound = { click  = "click" }
    onElemState = @(sf) stateFlags.set(sf)
    transform = { scale = stateFlags.get() & S_ACTIVE ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
    children = [
      {
        size = flex()
        rendObj = ROBJ_BOX
        fillColor = 0x70000000
        borderWidth = hdpx(1)
        borderColor = stateFlags.get() & S_ACTIVE ? hoverColor : 0xFFFFFFFF
        transform = { rotate = 45 }
      }
      iText.__merge(textOvr)
    ]
  }.__update(ovr)
}

function infoTooltipButton(contentCtor, tooltipOvr = {}, ovr = {}) {
  let stateFlags = Watched(0)
  let key = {}
  return @() {
    key
    watch = stateFlags
    behavior = Behaviors.Button
    xmbNode = {}
    onElemState = withTooltip(stateFlags, key, @() {
        content = contentCtor(),
        flow = FLOW_HORIZONTAL
      }.__update(tooltipOvr))
    onDetach = tooltipDetach(stateFlags)
    fillColor = 0
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    rendObj = ROBJ_VECTOR_CANVAS
    size = hdpx(40)
    lineWidth = hdpx(2)
    commands = [
      [VECTOR_ELLIPSE, 50, 50, 50, 50],
    ]
    transform = { scale = stateFlags.get() & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
    children = [
      {
        rendObj = ROBJ_TEXT
        text = "?"
        halign = ALIGN_CENTER
      }.__update(fontTinyAccented)
    ]
  }.__update(ovr)
}

return {
  infoGoldButton
  infoBlueButton
  infoGreyButton
  infoCommonButton
  infoEllipseButton

  infoRhombButton
  infoTooltipButton
}
