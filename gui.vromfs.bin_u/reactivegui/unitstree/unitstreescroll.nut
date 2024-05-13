from "%globalsDarg/darg_library.nut" import *
let { isUnitsTreeOpen, columnsCfg } = require("%rGui/unitsTree/unitsTreeState.nut")
let { unseenUnits } = require("%rGui/unit/unseenUnits.nut")
let { unseenSkins } = require("%rGui/unitSkins/unseenSkins.nut")
let { availableUnitsList } = require("%rGui/unit/unitsWndState.nut")
let { flagsWidth, blockSize, flagTreeOffset } = require("unitsTreeComps.nut")
let { abs } = require("math")
let { resetTimeout, defer } = require("dagor.workcycle")
let { isLvlUpAnimated } = require("%rGui/levelUp/levelUpState.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { mkScrollArrow, scrollArrowImageSmall } = require("%rGui/components/scrollArrows.nut")


let SCROLL_DELAY = 1.5

let scrollHandler = ScrollHandler()
let nodeToScroll = Watched(null)
let scrollPos = Computed(@() (scrollHandler.elem?.getScrollOffsX() ?? 0))

function scrollToUnit(name, xmbNode = null) {
  if (!name)
    return
  let selUnitIdx = availableUnitsList.value.findvalue(@(u) u.name == name)?.rank ?? 1
  let scrollPosX = blockSize[0] * (columnsCfg.value[selUnitIdx] + 1) - (0.4 * (saSize[0] - flagsWidth))
  if (abs(scrollPosX - scrollPos.value) > saSize[0] * 0.1)
    if (!xmbNode)
      scrollHandler.scrollToX(scrollPosX)
    else
      defer(@() gui_scene.setXmbFocus(xmbNode))
}

function scrollToRank(rank) {
  let scrollPosX = blockSize[0] * ((columnsCfg.value?[rank] ?? 0) + 1) - 0.5 * (saSize[0] - flagsWidth)
  scrollHandler.scrollToX(scrollPosX)
}

function scrollForward() {
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
  scrollToUnit
  scrollToRank
  scrollForward
  unseenArrowsBlock
  unseenArrowsBlockCtor
}
