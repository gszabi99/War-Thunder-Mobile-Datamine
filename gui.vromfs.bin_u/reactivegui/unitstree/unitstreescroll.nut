from "%globalsDarg/darg_library.nut" import *
let { fabs } = require("math")
let { get_time_msec } = require("dagor.time")
let { resetTimeout, defer, setInterval, clearTimer } = require("dagor.workcycle")
let { isUnitsTreeOpen, columnsCfg } = require("%rGui/unitsTree/unitsTreeState.nut")
let { unseenUnits } = require("%rGui/unit/unseenUnits.nut")
let { unseenSkins } = require("%rGui/unitSkins/unseenSkins.nut")
let { availableUnitsList } = require("%rGui/unit/unitsWndState.nut")
let { flagsWidth, blockSize, flagTreeOffset } = require("unitsTreeComps.nut")
let { isLvlUpAnimated } = require("%rGui/levelUp/levelUpState.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { mkScrollArrow, scrollArrowImageSmall } = require("%rGui/components/scrollArrows.nut")


let SCROLL_DELAY = 1.5

let scrollHandler = ScrollHandler()
let nodeToScroll = Watched(null)
let scrollPos = Computed(@() (scrollHandler.elem?.getScrollOffsX() ?? 0))

local animScrollCfg = null
let aTimeScroll = 0.5
let minScrollSpeed = hdpx(1000)


function updateAnimScroll() {
  if (animScrollCfg == null) {
    clearTimer(updateAnimScroll)
    return
  }
  let { pos1, pos2, start, end, easing } = animScrollCfg
  let time = get_time_msec()
  if (time >= end)
    clearTimer(updateAnimScroll)

  let t = clamp((get_time_msec() - start).tofloat() / (end - start), 0, 1)
  let v = easing(t)
  scrollHandler.scrollToX(pos1[0] + (pos2[0] - pos1[0]) * v)
  scrollHandler.scrollToY(pos1[1] + (pos2[1] - pos1[1]) * v)
}

function startAnimScroll(pos2) {
  let pos1 = [
    scrollHandler.elem?.getScrollOffsX() ?? 0
    scrollHandler.elem?.getScrollOffsY() ?? 0
  ]
  let time = (1000 * min(aTimeScroll, max(fabs(pos1[0] - pos2[0]), fabs(pos1[1] - pos2[1])) / minScrollSpeed))
    .tointeger()
  if (time <= 0)
    return

  if (animScrollCfg != null)
    clearTimer(updateAnimScroll)
  let start = get_time_msec()
  animScrollCfg = { pos1, pos2, start, end = start + time,
    easing = @(t) t < 0.5 ? 2.0 * t * t : (1.0 - 2 * (1.0 - t) * (1.0 - t))
  }
  setInterval(0.01, updateAnimScroll)
}

function interruptAnimScroll() {
  animScrollCfg = null
}

function scrollToRank(rank) {
  interruptAnimScroll()
  let scrollPosX = blockSize[0] * ((columnsCfg.value?[rank] ?? 0) + 1) - 0.5 * (saSize[0] - flagsWidth)
  scrollHandler.scrollToX(scrollPosX)
}

function scrollForward() {
  interruptAnimScroll()
  if (nodeToScroll.get() != null)
    resetTimeout(SCROLL_DELAY, @() defer(@() gui_scene.setXmbFocus(nodeToScroll.get())))
}
isLvlUpAnimated.subscribe(@(v) v ? scrollForward() : null)

let unseenUnitsIndex = Computed(function() {
  let res = {}
  if (!isUnitsTreeOpen.get() || (unseenUnits.get().len() == 0 && unseenSkins.get().len() == 0))
    return res
  foreach(unit in availableUnitsList.value) {
    if(unit.name in unseenUnits.get() || unit.name in unseenSkins.get())
      res[unit.name] <- columnsCfg.value[unit.rank]
  }
  return res
})

let needShowArrowL = Computed(function() {
  let offsetIdx = (scrollPos.get() - flagTreeOffset).tofloat() / blockSize[0] - 1
  return null != unseenUnitsIndex.get().findvalue(@(index) offsetIdx > index)
})

let needShowArrowR = Computed(function() {
  let offsetIdx = (scrollPos.get() + sw(100) - 2 * saBorders[0] - flagsWidth - flagTreeOffset).tofloat() / blockSize[0]
    - 1
  return null != unseenUnitsIndex.get().findvalue(@(index) offsetIdx < index)
})

let unseenArrowsBlockCtor = @(needShowL, needShowR, ovr = {}) {
  size = [flex(), SIZE_TO_CONTENT]
  pos = [0, hdpx(25)]
  children = [
    @() {
      watch = needShowL
      size = [flex(), SIZE_TO_CONTENT]
      pos = [-flagTreeOffset, 0]
      children = !needShowL.get() ? null : [
        {
          hplace = ALIGN_LEFT
          pos = [0, -hdpx(20)]
          children = priorityUnseenMark
        }
        mkScrollArrow(scrollHandler, MR_L, scrollArrowImageSmall)
      ]
    }
    @() {
      watch = needShowR
      size = [flex(), SIZE_TO_CONTENT]
      pos = [saBorders[0] * 0.5, 0]
      children = !needShowR.get() ? null : [
        {
          hplace = ALIGN_RIGHT
          pos = [0, -hdpx(20)]
          children = priorityUnseenMark
        }
        mkScrollArrow(scrollHandler, MR_R, scrollArrowImageSmall)
      ]
    }
  ]
}.__update(ovr)

let unseenArrowsBlock = @() unseenArrowsBlockCtor(needShowArrowL, needShowArrowR)

return {
  scrollHandler
  scrollPos
  nodeToScroll
  scrollToRank
  scrollForward
  unseenArrowsBlock
  unseenArrowsBlockCtor
  startAnimScroll
  interruptAnimScroll
}
