from "%globalsDarg/darg_library.nut" import *
let { round } =  require("math")
let { curDebrTabId, isDebriefingAnimFinished } = require("%rGui/debriefing/debriefingState.nut")

let tabSize = hdpx(75).tointeger()
let tabGap = hdpx(30)
let tabLineGap = hdpx(0)
let tabLineH = hdpx(10)

let activeColor = 0xFFFFFFFF
let fadedColor = 0x80808080

function tabBase(info, debrData, sf, isSelected, isInAnim) {
  let isActive = isSelected || (sf & S_ACTIVE) != 0
  let isHovered = sf & S_HOVER
  let { id, timeShow, nextTabId, getIcon, iconScale } = info
  let iconSize = round(tabSize * iconScale).tointeger()
  return {
    size = [tabSize, tabSize + tabLineGap + tabLineH]
    children = [
      (!isInAnim || !isSelected) ? null : {
        rendObj = ROBJ_IMAGE
        size = [tabSize, tabSize]
        image = Picture($"ui/gameuiskin#hud_circle_animation.svg:{tabSize}:{tabSize}:P")
        color = activeColor
        opacity = 0
        key = $"splash_{id}"
        transform = {}
        animations = [
          { prop = AnimProp.scale, from = [0.5, 0.5], to = [2, 2], duration = 0.7, easing = OutQuad, play = true }
          { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.7, easing = OutQuad, play = true }
        ]
      }
      {
        size = [iconSize, iconSize]
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        rendObj = ROBJ_IMAGE
        image = Picture($"{getIcon(debrData)}:{iconSize}:{iconSize}:P")
        color = isActive || isHovered ? activeColor : fadedColor
        keepAspect = true
      }.__update((!isInAnim || !isSelected) ? {} : {
          key = $"icon_{id}"
          transform = {}
          animations = [{ prop = AnimProp.scale, from = [1, 1], to = [1.5, 1.5], easing = Blink, duration = 0.5, play = true }]
        })
      !isSelected ? null : {
        size = [tabSize, tabLineH]
        hplace = ALIGN_LEFT
        vplace = ALIGN_BOTTOM
        rendObj = ROBJ_SOLID
        color = activeColor
      }.__update(!isInAnim ? {} : {
          key = $"progress_{id}"
          transform = { pivot = [0, 0] }
          animations = [{
            prop = AnimProp.scale, from = [0, 1], duration = timeShow, play = true,
            onFinish = nextTabId != null ? @() curDebrTabId.set(nextTabId) : null
          }]
        })
    ]
  }
}

function mkTab(info, debrData) {
  let stateFlags = Watched(0)
  let { id } = info
  let isSelected = Computed(@() curDebrTabId.get() == id)
  return @() {
    watch = [stateFlags, isSelected, isDebriefingAnimFinished]
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags.set(sf)
    transform = { scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.9, 0.9] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.15, easing = Linear }]
    sound = { click  = "click" }
    function onClick() {
      isDebriefingAnimFinished.set(true)
      curDebrTabId.set(id)
    }
    children = tabBase(info, debrData, stateFlags.get(), isSelected.get(), !isDebriefingAnimFinished.get())
  }
}

let debriefingTabBar = @(debrData, debrTabsInfo) debrTabsInfo.len() == 0 ? null : {
  size = [SIZE_TO_CONTENT, tabSize + tabLineGap + tabLineH]
  flow = FLOW_HORIZONTAL
  gap = tabGap
  children = debrTabsInfo.map(@(v) mkTab(v, debrData))
}

return debriefingTabBar
