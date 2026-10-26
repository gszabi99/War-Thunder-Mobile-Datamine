from "%globalsDarg/darg_library.nut" import *
from "%rGui/style/stdColors.nut" import hoverColor
from "%rGui/style/stdAnimations.nut" import mkPressTransitionScale
from "%rGui/tooltip.nut" import withTooltip, tooltipDetach


let headerIconHeight = evenPx(36)
let headerIconWidth = (1.5 * headerIconHeight).tointeger()

function headerIconButton(icon, contentCtor, hasHint) {
  if (!hasHint && icon == null)
    return null

  let stateFlags = Watched(0)
  let key = {}
  let onElemState = withTooltip(stateFlags, key, contentCtor)
  let onDetach = tooltipDetach(stateFlags)
  let iconImage = icon == null ? null : Picture($"{icon}:{headerIconWidth}:{headerIconHeight}:P")
  return @() {
    key
    watch = stateFlags
    behavior = Behaviors.Button
    xmbNode = {}
    onElemState
    onDetach

    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [
      icon == null ? null
        : {
            size = [headerIconWidth, headerIconHeight]
            rendObj = ROBJ_IMAGE
            image = iconImage
            color = stateFlags.get() & S_HOVER ? hoverColor : 0xFFFFFFFF
            keepAspect = true
          }
      !hasHint ? null
        : {
            rendObj = ROBJ_VECTOR_CANVAS
            size = hdpx(40)
            lineWidth = hdpx(2)
            fillColor = 0
            color = stateFlags.get() & S_HOVER ? hoverColor : 0xFFFFFFFF
            commands = const [[VECTOR_ELLIPSE, 50, 50, 50, 50]]
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            children = {
              rendObj = ROBJ_TEXT
              text = "?"
              color = stateFlags.get() & S_HOVER ? hoverColor : 0xFFFFFFFF
              ...fontTinyAccented
            }
          }
    ]
    ...mkPressTransitionScale(stateFlags.get(), 0.9)
  }
}

let mkLbHeaderRow = @(categories, styleByCategory = {}) categories.map(function(c) {
  let { locId, hintLocId, relWidth, icon } = c
  let hintCtor = @() hintLocId != ""
    ? {
        flow = FLOW_HORIZONTAL
        halign = ALIGN_RIGHT
        content = "\n".concat(loc(locId), loc(hintLocId))
      }
    : {
        flow = FLOW_VERTICAL
        valign = ALIGN_TOP
        content = loc(locId)
      }
  return {
    size = [flex(relWidth), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    children = headerIconButton(icon, hintCtor, hintLocId != "")
  }.__update(styleByCategory?[c] ?? {})
})

return {
  mkLbHeaderRow
  headerIconHeight
}