from "%globalsDarg/darg_library.nut" import *
let { selectedLineVertSolid, opacityTransition, selLineSize } = require("%rGui/components/selectedLine.nut")
let { selectColor } = require("%rGui/style/stdColors.nut")
let { simpleHorGradInv } = require("%rGui/style/gradients.nut")

let tabsGap = hdpx(10)
let tabExtraWidth = selLineSize

let bgColor = 0x990C1113

let mkTabContent = @(content, isActive, tabOverride, isHover) {
  size = FLEX_H

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
      image = simpleHorGradInv
      color = selectColor
      opacity = isActive.get() ? 0.9
        : isHover.get() ? 0.5
        : 0
      transitions = opacityTransition
    }
  ].append(content)
}.__merge(tabOverride)

function mkTab(id, content, curTabId, tabOverride, onClick = null, extraContent = null) {
  let stateFlags = Watched(0)
  let isActive = Computed(@() curTabId.get() == id || (stateFlags.get() & S_ACTIVE) != 0)
  let isHover = Computed(@() stateFlags.get() & S_HOVER)

  let mainBlock = {
    size = FLEX_H
    behavior = Behaviors.Button
    xmbNode = {}
    onElemState = @(v) stateFlags.set(v)
    clickableInfo = loc("mainmenu/btnSelect")
    onClick = onClick ?? @() curTabId.set(id)
    sound = { click = "choose" }
    flow = FLOW_HORIZONTAL

    children = [
      selectedLineVertSolid(isActive)
      mkTabContent(content, isActive, tabOverride, isHover)
    ]
  }

  return extraContent == null ? mainBlock
    : {
        size = FLEX_H
        flow = FLOW_VERTICAL
        children = [
          mainBlock
          extraContent
        ]
      }
}

let tabsRoot = {
  size = FLEX_H
  flow = FLOW_VERTICAL
  gap = tabsGap
}

function mkTabs(tabsData, curTabId, ovr = {}, onClick = null) {
  let watch = tabsData.map(@(t) t?.isVisible).filter(@(v) v != null)
  if (watch.len() == 0)
    return tabsRoot.__merge(
      {
        children = tabsData.map(@(tab)
          mkTab(tab.id, tab.content, curTabId, tab?.override ?? {}, onClick ? @() onClick(tab.id) : null, tab?.extraContent))
      },
      ovr)

  return @() tabsRoot.__merge(
    {
      watch
      children = tabsData
        .filter(@(tab) tab?.isVisible.get() ?? true)
        .map(@(tab) mkTab(tab.id, tab.content, curTabId, tab?.override ?? {}, onClick ? @() onClick(tab.id) : null, tab?.extraContent))
    },
    ovr)
}

return {
  tabExtraWidth
  mkTabs
  tabsGap
  bgColor
  selLineSize
}
