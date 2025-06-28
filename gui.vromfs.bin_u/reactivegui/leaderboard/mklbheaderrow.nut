from "%globalsDarg/darg_library.nut" import *
let { withTooltip, tooltipDetach } = require("%rGui/tooltip.nut")
let { hoverColor } = require("%rGui/style/stdColors.nut")

let headerIconHeight = evenPx(36)
let headerIconWidth = (1.5 * headerIconHeight).tointeger()

function headerIconButton(icon, contentCtor, hasHint) {
  if (!hasHint && icon == null)
    return null

  let stateFlags = Watched(0)
  let key = {}
  return @() {
    key
    watch = stateFlags
    behavior = Behaviors.Button
    xmbNode = {}
    onElemState = withTooltip(stateFlags, key, contentCtor)
    onDetach = tooltipDetach(stateFlags)

    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [
      icon == null ? null
        : {
            size = [headerIconWidth, headerIconHeight]
            rendObj = ROBJ_IMAGE
            image = Picture($"{icon}:{headerIconWidth}:{headerIconHeight}:P")
            color = stateFlags.value & S_HOVER ? hoverColor : 0xFFFFFFFF
            keepAspect = true
          }
      !hasHint ? null
        : {
            rendObj = ROBJ_VECTOR_CANVAS
            size = hdpx(40)
            lineWidth = hdpx(2)
            fillColor = 0
            color = stateFlags.value & S_HOVER ? hoverColor : 0xFFFFFFFF
            commands = [[VECTOR_ELLIPSE, 50, 50, 50, 50]]
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            children = {
              rendObj = ROBJ_TEXT
              text = "?"
              color = stateFlags.value & S_HOVER ? hoverColor : 0xFFFFFFFF
            }.__update(fontTinyAccented)
          }
    ]
    transform = { scale = stateFlags.value & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
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