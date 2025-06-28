from "%globalsDarg/darg_library.nut" import *
let { fabs } = require("math")
let { get_time_msec } = require("dagor.time")
let { resetTimeout, defer, setInterval, clearTimer } = require("dagor.workcycle")
let { flagTreeOffset } = require("unitsTreeComps.nut")
let { isLvlUpAnimated } = require("%rGui/levelUp/levelUpState.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { mkScrollArrow, scrollArrowImageVerySmall } = require("%rGui/components/scrollArrows.nut")


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

function scrollForward() {
  interruptAnimScroll()
  if (nodeToScroll.get() != null)
    resetTimeout(SCROLL_DELAY, @() defer(@() gui_scene.setXmbFocus(nodeToScroll.get())))
}
isLvlUpAnimated.subscribe(@(v) v ? scrollForward() : null)

let unseenArrowsBlockCtor = @(needShowL, needShowR, ovr = {}) {
  size = FLEX_H
  pos = [0, hdpx(17)]
  children = [
    @() {
      watch = needShowL
      size = FLEX_H
      pos = [-flagTreeOffset, 0]
      children = !needShowL.get() ? null : [
        {
          hplace = ALIGN_LEFT
          pos = [0, -hdpx(20)]
          children = priorityUnseenMark
        }
        mkScrollArrow(scrollHandler, MR_L, scrollArrowImageVerySmall)
      ]
    }
    @() {
      watch = needShowR
      size = FLEX_H
      pos = [saBorders[0] * 0.5, 0]
      children = !needShowR.get() ? null : [
        {
          hplace = ALIGN_RIGHT
          pos = [0, -hdpx(20)]
          children = priorityUnseenMark
        }
        mkScrollArrow(scrollHandler, MR_R, scrollArrowImageVerySmall)
      ]
    }
  ]
}.__update(ovr)

return {
  scrollHandler
  scrollPos
  nodeToScroll
  scrollForward
  unseenArrowsBlockCtor
  startAnimScroll
  interruptAnimScroll
}
