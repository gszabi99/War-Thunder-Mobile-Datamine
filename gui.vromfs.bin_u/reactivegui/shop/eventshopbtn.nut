from "%globalsDarg/darg_library.nut" import *
let { serverTime, getServerTime } = require("%appGlobals/userstats/serverTime.nut")
let { getEventPresentation } = require("%appGlobals/config/eventSeasonPresentation.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { openShopWnd, hasUnseenGoodsByShop, goodsByShop, soonGoodsByShop,
  soonPersonalGoodsByShop,
} = require("%rGui/shop/shopState.nut")


let eventShopBtnIconSize = hdpx(150)

let inc = @(tbl, id) tbl.$rawset(id, (tbl?[id] ?? 0) + 1)

function bestKey(tbl) {
  local res = null
  local resV = null
  foreach (key, value in tbl)
    if (res == null || value > resV) {
      res = key
      resV = value
    }
  return res
}

function mkBtn(sId) {
  let eventButtonSF = Watched(0)
  let isEventShopHasUnseen = Computed(@() hasUnseenGoodsByShop.get()?[sId].findvalue(@(c) c) ?? false)
  let eventCfg = Computed(function() {
    let time = getServerTime() 
    local eventIdCounts = {}
    local timeEndCounts = {}
    foreach(goodsList in goodsByShop.get()[sId])
      foreach(goods in goodsList) {
        inc(eventIdCounts, goods.meta?.eventId ?? "")
        local timeEnd = 0
        if (goods.timeRanges.len() == 0)
          timeEnd = -1
        else
          foreach(tRange in goods.timeRanges)
            if (tRange.start <= time) {
              if (tRange.end == -1) {
                timeEnd = -1
                break
              }
              if (tRange.end < time)
                continue
              timeEnd = max(timeEnd, tRange.end)
              break
            }
        inc(timeEndCounts, timeEnd)
      }
    foreach(goodsList in soonGoodsByShop.get()[sId])
      foreach(goods in goodsList) {
        inc(eventIdCounts, goods.meta?.eventId ?? "")
        if (goods.timeRanges.len() == 0)
          continue
        let { start = 0 } = goods.timeRanges.findvalue(@(tr) tr.start > time)
        if (start > 0)
          inc(timeEndCounts, start)
      }
    foreach (goodsList in soonPersonalGoodsByShop.get()[sId])
      foreach (goods in goodsList) {
        inc(eventIdCounts, goods.meta?.eventId ?? "")
        let { start = 0 } = goods.timeRange
        if (start > 0)
          inc(timeEndCounts, start)
      }

    eventIdCounts.$rawdelete("")
    return {
      timeEnd = bestKey(timeEndCounts) ?? 0
      eventId = bestKey(eventIdCounts) ?? ""
    }
  })

  return @() {
    watch = [eventButtonSF, isEventShopHasUnseen, eventCfg]
    behavior = Behaviors.Button
    onClick = @() openShopWnd(null, null, sId)
    sound = { click = "click" }
    onElemState = @(v) eventButtonSF.set(v)

    transform = {
      scale = eventButtonSF.get() & S_ACTIVE ? [0.95, 0.95]
        : eventButtonSF.get() & S_HOVER ? [1.05, 1.05]
        : [1, 1]
    }
    children = [
      @() {
        watch = eventCfg
        size = [eventShopBtnIconSize, eventShopBtnIconSize]
        rendObj = ROBJ_IMAGE
        image = Picture($"{getEventPresentation(eventCfg.get().eventId).image }:{eventShopBtnIconSize}:{eventShopBtnIconSize}:P")
        fallbackImage = Picture($"ui/gameuiskin/icon_event_event_black_friday_shop.avif:{eventShopBtnIconSize}:{eventShopBtnIconSize}:P")
        keepAspect = true
      }
      @() {
        watch = [eventCfg, serverTime]
        size = FLEX_H
        rendObj = ROBJ_TEXT
        text = secondsToHoursLoc(eventCfg.get().timeEnd - serverTime.get())
        pos = [0, eventShopBtnIconSize]
        halign = ALIGN_CENTER
      }.__update(fontVeryTinyAccentedShaded)
      !isEventShopHasUnseen.get() ? null : priorityUnseenMark.__merge({ hplace = ALIGN_RIGHT, vplace = ALIGN_TOP})
    ]
  }
}

function mkEventShopBtn () {
  let isEventShopBtnVisible = Computed(@() goodsByShop.get().events.len()
    + soonGoodsByShop.get().events.len()
    + soonPersonalGoodsByShop.get().events.len() > 0)

  let isEventShop2BtnVisible = Computed(@() goodsByShop.get().events2.len()
    + soonGoodsByShop.get().events2.len()
    + soonPersonalGoodsByShop.get().events2.len() > 0)

  return @() {
    watch = [isEventShopBtnVisible, isEventShop2BtnVisible]
    flow = FLOW_HORIZONTAL
    gap = hdpx(20)
    children = [
      !isEventShopBtnVisible.get() ? null : mkBtn("events")
      !isEventShop2BtnVisible.get() ? null : mkBtn("events2")
    ]
  }
}


return mkEventShopBtn
