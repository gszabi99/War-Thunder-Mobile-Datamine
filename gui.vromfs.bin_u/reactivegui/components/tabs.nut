from "%globalsDarg/darg_library.nut" import *
let { mkLinearGradientImg } = require("%darg/helpers/mkGradientImg.nut")

let tabsGap = hdpx(10)
let selLineGap = hdpx(10)
let selLineWidth = hdpx(7)
let tabExtraWidth = selLineWidth + selLineGap

let bgColor = 0x80000000
let activeBgColor = 0x8052C4E4
let transDuration = 0.3

let bgGradTextureW = hdpx(100)
let bgGradTextureH = hdpx(50)
let lineGradTextureW = 4
let lineGradTextureH = bgGradTextureH

let bgGradient = mkLinearGradientImg({
  points = [{ offset = 0, color = colorArr(activeBgColor) }, { offset = 100, color = colorArr(bgColor) }]
  width = bgGradTextureW
  height = bgGradTextureH
  x1 = 0.25 * bgGradTextureW
  y1 = 0.35 * bgGradTextureH
  x2 = 0.75 * bgGradTextureW
  y2 = 0.20 * bgGradTextureH
})

let lineGradient = mkLinearGradientImg({
  points = [
    { offset = 0, color = colorArr(0) },
    { offset = 30, color = colorArr(activeBgColor) },
    { offset = 70, color = colorArr(activeBgColor) },
    { offset = 100, color = colorArr(0) }
  ]
  width = lineGradTextureW
  height = lineGradTextureH
  x1 = 0
  y1 = 0
  x2 = 0
  y2 = lineGradTextureH
})

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
      opacity = isActive.value ? 0 : 1
      transitions = opacityTransition
    }
    @() {
      watch = [isActive, isHover]
      size = flex()
      rendObj = ROBJ_IMAGE
      image = bgGradient
      opacity = isActive.value ? 0.5
        : isHover.value ? 0.35
        : 0
      transitions = opacityTransition
    }
  ].append(content)
}.__merge(tabOverride)

let function mkTab(id, content, curTabId, tabOverride) {
  let stateFlags = Watched(0)
  let isActive = Computed (@() curTabId.value == id || (stateFlags.value & S_ACTIVE) != 0)
  let isHover = Computed (@() stateFlags.value & S_HOVER)

  return {
    size = [ flex(), SIZE_TO_CONTENT ]
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags(v)
    clickableInfo = loc("mainmenu/btnSelect")
    onClick = @() curTabId(id)
    sound = { click = "choose" }
    flow = FLOW_HORIZONTAL
    gap = selLineGap

    children = [
      selectedLine(isActive)
      mkTabContent(content, isActive, tabOverride, isHover)
    ]
  }
}

let mkTabs = @(tabsData, curTabId) {
  size = [ flex(), SIZE_TO_CONTENT ]
  flow = FLOW_VERTICAL
  gap = tabsGap
  children = tabsData.map(@(tab)
    mkTab(tab.id, tab.content, curTabId, tab?.override ?? {}))
}

return {
  tabExtraWidth
  mkTabs
}
