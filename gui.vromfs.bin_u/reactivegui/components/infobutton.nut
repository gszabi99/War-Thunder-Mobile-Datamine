from "%globalsDarg/darg_library.nut" import *
let { hoverColor } = require("%rGui/style/stdColors.nut")
let { withTooltip, tooltipDetach } = require("%rGui/tooltip.nut")
let { defBorderGradient } = require("%rGui/components/buttonStyles.nut")
let { mkGradient }  = require("%rGui/components/textButton.nut")

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

let mkInfoButtonCtor = @(btnStyle) function(onClick, ovr = {}, textOvr = fontSmallAccented) {
  let size = ovr?.size ?? defSize
  let stateFlags = Watched(0)
  let { fillColor = null, color = null } = btnStyle
  return @() {
    watch = stateFlags
    size
    rendObj = ROBJ_BOX
    fillColor = 0xFFB9B9B9
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags.set(v)
    xmbNode = {}
    sound = { click  = "click" }
    onClick
    brightness = stateFlags.get() & S_HOVER ? 0.5 : 1
    children = {
      size = flex()
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = {
        size = flex()
        rendObj = ROBJ_BOX
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        fillColor
        clipChildren = true
        children = [
          mkGradient({ color })
          iText.__merge(textOvr)
        ]
      }
    }.__update(defBorderGradient)
    transform = { scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
  }.__update(ovr)
}

let mkInfoEllipseButtonCtor = @(btnStyle) function(onClick, ovr = {}, textOvr = fontSmallAccented) {
  let size = ovr?.size ?? defSizeMedium
  let stateFlags = Watched(0)
  let { fillColor = null, borderColor = null } = btnStyle
  return @() {
    watch = stateFlags
    size
    rendObj = ROBJ_VECTOR_CANVAS
    lineWidth = hdpxi(2)
    fillColor
    color = borderColor
    commands = [[VECTOR_ELLIPSE, 50, 50, 50, 50]]
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags.set(v)
    xmbNode = {}
    sound = { click  = "click" }
    onClick
    brightness = stateFlags.get() & S_HOVER ? 1.5 : 1
    children = iText.__merge(textOvr)
    transform = { scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
  }.__update(ovr)
}

let infoCommonButton = mkInfoButtonCtor({
  fillColor = 0xFF191616
  color = 0xFF57595B
})
let infoEllipseButton = mkInfoEllipseButtonCtor({
  fillColor = 0xFF070707
  borderColor = 0x80777777
})

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
  infoGreyButton
  infoCommonButton
  infoEllipseButton

  infoRhombButton
  infoTooltipButton
}
