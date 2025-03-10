from "%globalsDarg/darg_library.nut" import *
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { gradTexSize, mkGradientCtorRadial } = require("%rGui/style/gradients.nut")
let { selectedLineVert, opacityTransition, selLineSize } = require("%rGui/components/selectedLine.nut")

let tabsGap = hdpx(10)
let selLineGap = hdpx(10)
let tabExtraWidth = selLineSize + selLineGap

let bgColor = 0x990C1113
let activeBgColor = 0xFF52C4E4

let bgGradient = mkBitmapPictureLazy(gradTexSize, gradTexSize / 4,
  mkGradientCtorRadial(activeBgColor, 0, gradTexSize / 4, gradTexSize * 6 / 16, gradTexSize * 3 / 16, gradTexSize * 3 / 8))

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
      image = bgGradient()
      opacity = isActive.value ? 1
        : isHover.value ? 0.5
        : 0
      transitions = opacityTransition
    }
  ].append(content)
}.__merge(tabOverride)

function mkTab(id, content, curTabId, tabOverride, onClick = null) {
  let stateFlags = Watched(0)
  let isActive = Computed (@() curTabId.value == id || (stateFlags.value & S_ACTIVE) != 0)
  let isHover = Computed (@() stateFlags.value & S_HOVER)

  return {
    size = [ flex(), SIZE_TO_CONTENT ]
    behavior = Behaviors.Button
    xmbNode = {}
    onElemState = @(v) stateFlags(v)
    clickableInfo = loc("mainmenu/btnSelect")
    onClick = onClick ?? @() curTabId(id)
    sound = { click = "choose" }
    flow = FLOW_HORIZONTAL
    gap = selLineGap

    children = [
      selectedLineVert(isActive)
      mkTabContent(content, isActive, tabOverride, isHover)
    ]
  }
}

let tabsRoot = {
  size = [ flex(), SIZE_TO_CONTENT ]
  flow = FLOW_VERTICAL
  gap = tabsGap
}

function mkTabs(tabsData, curTabId, ovr = {}, onClick = null) {
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
  bgColor
  selLineGap
  selLineSize
}
