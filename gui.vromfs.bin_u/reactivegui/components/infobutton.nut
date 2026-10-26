from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/buttonStyles.nut" import defBorderGradient
from "%rGui/components/textButton.nut" import mkGradient
from "%rGui/style/gradients.nut" import btnBorderGradient, btnCommonBgGradient
from "%rGui/style/stdColors.nut" import hoverColor
from "%rGui/style/stdAnimations.nut" import mkPressTransitionScale
from "%rGui/tooltip.nut" import withTooltip, tooltipDetach


let iText = {
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  text = "i"
}.__update(fontSmallAccentedShaded)

let defSize = [evenPx(70), evenPx(70)]
let defSizeSmall = [evenPx(50), evenPx(50)]
let defSizeMedium = evenPx(60)
const defTooltipSize = hdpx(40)
const borderWidth = hdpxi(2)

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
    sound = const { click  = "click" }
    onClick
    brightness = stateFlags.get() & S_HOVER ? 0.5 : 1
    children = {
      size = FLEX
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = {
        size = FLEX
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
      ...defBorderGradient
    }
    ...mkPressTransitionScale(stateFlags.get())
    ...ovr
  }
}

let mkInfoEllipseButtonCtor = @(borderImage, bgImage) function(onClick, ovr = {}, textOvr = fontSmallAccented) {
  let size = ovr?.size ?? defSizeMedium
  let ht = size?[1] ?? size
  let stateFlags = Watched(0)
  let children = [
    {
      size = ht - 2 * borderWidth
      rendObj = ROBJ_BOX
      borderColor = 0
      fillColor = 0xFFFFFFFF
      borderWidth = 0
      borderRadius = ht / 2 - borderWidth
      image = bgImage
    }
    iText.__merge(textOvr)
  ]
  return @() {
    watch = stateFlags
    size

    rendObj = ROBJ_BOX
    borderColor = 0
    fillColor = 0xFFFFFFFF
    borderWidth = 0
    borderRadius = ht / 2
    image = stateFlags.get() & S_HOVER ? null : borderImage

    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags.set(sf)
    onClick
    sound = const { click  = "click" }

    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children,
    ...mkPressTransitionScale(stateFlags.get())
    ...ovr
  }
}

let infoCommonButton = mkInfoButtonCtor({
  fillColor = 0xFF191616
  color = 0xFF57595B
})
let infoEllipseButton = mkInfoEllipseButtonCtor(btnBorderGradient, btnCommonBgGradient)

function infoGreyButton(onClick, ovr = {}, textOvr = fontSmallAccented) {
  let size = ovr?.size ?? defSize
  let stateFlags = Watched(0)
  let children = iText.__merge(textOvr)
  return @() {
    watch = stateFlags
    size
    rendObj = ROBJ_SOLID
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags.set(sf)
    onClick
    color = 0x28262626
    children,
    ...mkPressTransitionScale(stateFlags.get(), 0.8)
    ...ovr
  }
}

function infoRhombButton(onClick, ovr = {}, textOvr = fontSmallAccented) {
  let stateFlags = Watched(0)
  let size = ovr?.size ?? defSizeSmall
  let infoText = iText.__merge(textOvr)

  return @() {
    watch = stateFlags
    size
    behavior = Behaviors.Button
    onClick
    sound = const { click  = "click" }
    onElemState = @(sf) stateFlags.set(sf)
    children = [
      {
        size = FLEX
        rendObj = ROBJ_BOX
        fillColor = 0x70000000
        borderWidth = hdpx(1)
        borderColor = stateFlags.get() & S_ACTIVE ? hoverColor : 0xFFFFFFFF
        transform = const { rotate = 45 }
      }
      infoText
    ]
    ...mkPressTransitionScale(stateFlags.get())
    ...ovr
  }
}

function infoTooltipButton(contentCtor, tooltipOvr = {}, ovr = {}) {
  let stateFlags = Watched(0)
  let key = {}
  let onElemState = withTooltip(stateFlags, key, @() {
    content = contentCtor(),
    flow = FLOW_HORIZONTAL
  }.__update(tooltipOvr))
  let onDetach = tooltipDetach(stateFlags)
  return @() {
    key
    watch = stateFlags
    behavior = Behaviors.Button
    xmbNode = {}
    onElemState
    onDetach
    fillColor = 0
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    rendObj = ROBJ_VECTOR_CANVAS
    size = defTooltipSize
    lineWidth = hdpx(2)
    commands = const [
      [VECTOR_ELLIPSE, 50, 50, 50, 50],
    ]
    children = {
      rendObj = ROBJ_TEXT
      text = "?"
      halign = ALIGN_CENTER
    }.__update(fontTinyAccented)
    ...mkPressTransitionScale(stateFlags.get(), 0.9)
    ...ovr
  }
}

return {
  infoGreyButton
  infoCommonButton
  infoEllipseButton

  infoRhombButton
  infoTooltipButton
  defTooltipSize
}
