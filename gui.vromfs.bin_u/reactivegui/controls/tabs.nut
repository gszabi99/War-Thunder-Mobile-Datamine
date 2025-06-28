from "%globalsDarg/darg_library.nut" import *
let { hoverColor } = require("%rGui/style/stdColors.nut")

function mkTab(cfg, isSelected, onClick) {
  let { icon, locId } = cfg
  let iconSize = hdpxi(60)
  let stateFlags = Watched(0)
  let color = Computed(@() isSelected ? 0xFFFFFFFF
    : stateFlags.value & S_HOVER ? hoverColor
    : 0xFFC0C0C0)
  let isPushed = Computed(@() !isSelected && (stateFlags.value & S_ACTIVE) != 0)

  let content = @() {
    watch = color
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    valign = ALIGN_BOTTOM
    children = [
      {
        size = [iconSize, iconSize]
        rendObj = ROBJ_IMAGE
        image = Picture($"{icon}:{iconSize}:{iconSize}:P")
        color = color.value
        keepAspect = true
        imageValign = ALIGN_BOTTOM
      }
      {
        rendObj = ROBJ_TEXT
        text = loc(locId)
        color = color.value
      }.__update(fontSmall)
    ]
  }

  let underline = @() {
    watch = stateFlags
    size = const [flex(), hdpx(5)]
    rendObj = ROBJ_SOLID
    color = isSelected ? 0xFFFFFFFF
      : stateFlags.value & S_HOVER ? hoverColor
      : 0
  }

  return @() {
    watch = isPushed

    behavior = Behaviors.Button
    sound = { click  = "click" }
    onElemState = @(sf) stateFlags(sf)
    onClick

    flow = FLOW_VERTICAL
    gap = hdpx(10)
    children = [
      content
      underline
    ]
    transform = { scale = isPushed.value ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]
  }
}

return {
  mkTab
}