from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout, clearTimer
from "dagor.time" import get_time_msec
from "math" import fabs
from "%rGui/debriefing/debriefingState.nut" import curDebrTabId, isDebriefingAnimFinished, DEBR_TAB_SCORES, stopDebriefingAnimation,
  showReleaseToContinueBtn


local pointer = null
let doubleTapDifTime = 500
let posDif = sh(4)

let showReleaseToContinueClue = @() showReleaseToContinueBtn.set(true)

let tapListener = @(debrTabsInfo) {
  behavior = Behaviors.ProcessPointingInput
  function onPointerPress(evt) {
    let { x, y, pointerId } = evt
    if ((evt.accumRes & R_PROCESSED) != 0
        || (pointer != null && pointer.id != evt.pointerId))
      return 0
    local { doubleTapCount = 0, firstTouchTime = 0 } = pointer
    if (!isDebriefingAnimFinished.get()) {
      anim_pause($"progress_anim_{curDebrTabId.get()}", true)
      resetTimeout(0.3, showReleaseToContinueClue)
    }

    let currentTime = get_time_msec()
    if (doubleTapCount == 0
        || (currentTime - firstTouchTime > doubleTapDifTime)
        || fabs(pointer.x - x) > posDif
        || fabs(pointer.y - y) > posDif) {
      firstTouchTime = currentTime
      doubleTapCount = 1
    }
    else
      doubleTapCount++

    pointer = { id = pointerId, x, y, doubleTapCount, firstTouchTime }

    return R_PROCESSED
  }
  function onPointerRelease(evt) {
    let { pointerId } = evt
    if (pointer == null || pointer.id != pointerId)
      return
    if (!isDebriefingAnimFinished.get()) {
      anim_pause($"progress_anim_{curDebrTabId.get()}", false)
      if (showReleaseToContinueBtn.get())
        showReleaseToContinueBtn.set(false)
      else
        clearTimer(showReleaseToContinueClue)
    }

    if (fabs(pointer.x - evt.x) > posDif || fabs(pointer.y - evt.y) > posDif) {
      pointer = null
      return
    }

    let { doubleTapCount, firstTouchTime } = pointer
    if (doubleTapCount == 2) {
      let currentTime = get_time_msec()
      let releaseDif = currentTime - firstTouchTime
      if (releaseDif < doubleTapDifTime) {
        let curTabIdx = debrTabsInfo.findindex(@(v) v.id == curDebrTabId.get()) ?? DEBR_TAB_SCORES
        let nextTabIdx = curTabIdx + (evt.x > sw(100) / 2 ? 1 : -1)
        if (nextTabIdx < curTabIdx)
          stopDebriefingAnimation()
        let nextTabId = debrTabsInfo?[nextTabIdx].id
        if (nextTabId)
          curDebrTabId.set(nextTabId)
      }

      pointer = null
    }
  }
}

return tapListener