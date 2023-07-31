from "%globalsDarg/darg_library.nut" import *
let { mkBitmapPicture } = require("%darg/helpers/bitmap.nut")
let { mkGradientCtorDoubleSideY, gradTexSize, mkGradientCtorRadial } = require("%rGui/style/gradients.nut")

let tabsGap = hdpx(10)
let selLineGap = hdpx(10)
let selLineWidth = hdpx(7)
let tabExtraWidth = selLineWidth + selLineGap

let bgColor = 0x990C1113
let activeBgColor = 0xFF52C4E4
let lineColor = 0xFF75D0E7
let transDuration = 0.3

let bgGradient = mkBitmapPicture(gradTexSize, gradTexSize / 4,
  mkGradientCtorRadial(activeBgColor, 0, gradTexSize / 4, gradTexSize * 6 / 16, gradTexSize * 3 / 16, gradTexSize * 3 / 8))
let lineGradient = mkBitmapPicture(4, gradTexSize, mkGradientCtorDoubleSideY(0, lineColor, 0.25))

let opacityTransition = [{ prop = AnimProp.opacity, duration = transDuration, easing = InOutQuad }]

let selectedLine = @(isActive) @() {
  watch = isActive
  size = [selLineWidth, flex()]
  rendObj = ROBJ_IMAGE
  image = lineGradient
  opacity = isActive.value ? 1 : 0
  transitions = opacityTransition
}

let mkTabContent = @(content, isActive, tabOverride, isHover) {
  size = [ flex(), SIZE_TO_CONTENT ]

  children = [
    @() {
      watch = isActive
      size = flex()
      rendObj = ROBJ_SOLID
      color = bgColor
      transitions = opacityTransition
    }
    @() {
      watch = [isActive, isHover]
      size = flex()
      rendObj = ROBJ_IMAGE
      image = bgGradient
      opacity = isActive.value ? 1
        : isHover.value ? 0.5
        : 0
      transitions = opacityTransition
    }
  ].append(content)
}.__merge(tabOverride)

let function mkTab(id, content, curTabId, tabOverride, onClick = null) {
  let stateFlags = Watched(0)
  let isActive = Computed (@() curTabId.value == id || (stateFlags.value & S_ACTIVE) != 0)
  let isHover = Computed (@() stateFlags.value & S_HOVER)

  return {
    size = [ flex(), SIZE_TO_CONTENT ]
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags(v)
    clickableInfo = loc("mainmenu/btnSelect")
    onClick = onClick ?? @() curTabId(id)
    sound = { click = "choose" }
    flow = FLOW_HORIZONTAL
    gap = selLineGap

    children = [
      selectedLine(isActive)
      mkTabContent(content, isActive, tabOverride, isHover)
    ]
  }
}

let tabsRoot = {
  size = [ flex(), SIZE_TO_CONTENT ]
  flow = FLOW_VERTICAL
  gap = tabsGap
}

let function mkTabs(tabsData, curTabId, ovr = {}, onClick = null) {
  let watch = tabsData.map(@(t) t?.isVisible).filter(@(v) v != null)
  if (watch.len() == 0)
    return tabsRoot.__merge(
      {
        children = tabsData.map(@(tab)
          mkTab(tab.id, tab.content, curTabId, tab?.override ?? {}, onClick ? @() onClick(tab.id) : null))
      },
      ovr)

  return @() tabsRoot.__merge(
    {
      watch
      children = tabsData
        .filter(@(tab) tab?.isVisible.value ?? true)
        .map(@(tab) mkTab(tab.id, tab.content, curTabId, tab?.override ?? {}, onClick ? @() onClick(tab.id) : null))
    },
    ovr)
}

return {
  tabExtraWidth
  mkTabs
  tabsGap
}
