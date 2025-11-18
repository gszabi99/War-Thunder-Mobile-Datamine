from "%globalsDarg/darg_library.nut" import *
let { fabs } = require("math")
let { get_time_msec } = require("dagor.time")
let { clearTimer, setInterval } = require("dagor.workcycle")
let { tabsGap } = require("%rGui/components/tabs.nut")
let { tabH, modW, modsWidth, modsGap, knobSize, knobGap, catsBlockHeight
} = require("%rGui/unitMods/unitModsConst.nut")
let { curBulletCategoryId, curModCategoryId, modsCategories, isOwn
} = require("%rGui/unitMods/unitModsState.nut")
let { choiceCount, bulletTotalSteps, choiceSecCount, bulletSecTotalSteps
} = require("%rGui/unitMods/unitBulletsState.nut")


let catsScrollHandler = ScrollHandler()
let carouselScrollHandler = ScrollHandler()

local carouselAnimScrollCfg = null
local catsAnimScrollCfg = null
let aTimeScroll = 0.5
let minScrollSpeed = hdpxi(1)

let catsHeight = Computed(function() {
  let blockH = tabH + tabsGap
  let calcCatsBlockHeight = modsCategories.get().len() * blockH
    + choiceCount.get() * (blockH + (bulletTotalSteps.get() <= 1 || !isOwn.get() ? 0 : (knobSize + knobGap * 2)))
    + choiceSecCount.get() * (blockH + (bulletSecTotalSteps.get() <= 1 || !isOwn.get() ? 0 : (knobSize + knobGap * 2)))
  return min(calcCatsBlockHeight - tabsGap, catsBlockHeight)
})

let getCarouselPosX = @(idx) idx * (modW + modsGap) - (modsWidth - modW) / 2
let getCatsPosY = @(idx, catsHeightV) idx * (tabH + tabsGap) - (catsHeightV - tabH) / 2

function updateCarouselAnimScroll() {
  if (carouselAnimScrollCfg == null) {
    clearTimer(updateCarouselAnimScroll)
    return
  }
  let { posX1, posX2, start, end, easing } = carouselAnimScrollCfg
  let time = get_time_msec()
  if (time >= end)
    clearTimer(updateCarouselAnimScroll)

  let t = clamp((get_time_msec() - start).tofloat() / (end - start), 0, 1)
  let v = easing(t)
  carouselScrollHandler.scrollToX(posX1 + (posX2 - posX1) * v)
}

function startCarouselAnimScroll(posX2Raw, scrollSpeed = minScrollSpeed) {
  let scrollWidth = (carouselScrollHandler.elem?.getContentWidth() ?? 0) - (carouselScrollHandler.elem?.getWidth() ?? 0)
  let posX2 = posX2Raw - scrollWidth
  let posX1 = carouselScrollHandler.elem?.getScrollOffsX() ?? 0
  let time = (1000 * min(aTimeScroll, max(fabs(posX1 - posX2), fabs(posX1 - posX2)) / max(fabs(scrollSpeed), minScrollSpeed)))
    .tointeger()
  if (time <= 0)
    return

  let start = get_time_msec()
  carouselAnimScrollCfg = { posX1, posX2, start, end = start + time,
    easing = @(t) 1.0 - (1.0 - t) * (1.0 - t)
  }
  clearTimer(updateCarouselAnimScroll)
  setInterval(0.01, updateCarouselAnimScroll)
}

function updateCatsAnimScroll() {
  if (catsAnimScrollCfg == null) {
    clearTimer(updateCatsAnimScroll)
    return
  }
  let { posY1, posY2, start, end, easing } = catsAnimScrollCfg
  let time = get_time_msec()
  if (time >= end)
    clearTimer(updateCatsAnimScroll)

  let t = clamp((get_time_msec() - start).tofloat() / (end - start), 0, 1)
  let v = easing(t)
  catsScrollHandler.scrollToY(posY1 + (posY2 - posY1) * v)
}

function startCatsAnimScroll(posY2, scrollSpeed = minScrollSpeed) {
  let posY1 = catsScrollHandler.elem?.getScrollOffsY() ?? 0
  let time = (1000 * min(aTimeScroll, max(fabs(posY1 - posY2), fabs(posY1 - posY2)) / max(fabs(scrollSpeed), minScrollSpeed)))
    .tointeger()
  if (time <= 0)
    return

  let start = get_time_msec()
  catsAnimScrollCfg = { posY1, posY2, start, end = start + time,
    easing = @(t) 1.0 - (1.0 - t) * (1.0 - t)
  }
  clearTimer(updateCatsAnimScroll)
  setInterval(0.01, updateCatsAnimScroll)
}

curBulletCategoryId.subscribe(function(idx) {
  if (idx == null)
    return
  startCatsAnimScroll(getCatsPosY(idx, catsHeight.get()))
})
curModCategoryId.subscribe(function(v) {
  if (v == null)
    return
  let idx = choiceCount.get() + (modsCategories.get().findindex(@(cat) cat == v) ?? 0)
  startCatsAnimScroll(getCatsPosY(idx, catsHeight.get()))
})

return {
  catsHeight

  catsScrollHandler
  carouselScrollHandler

  startCatsAnimScroll
  startCarouselAnimScroll

  getCarouselPosX
  getCatsPosY
}
