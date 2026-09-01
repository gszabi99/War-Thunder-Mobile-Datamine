from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/config/eventSeasonPresentation.nut" import getEventPresentation
from "%appGlobals/userstats/serverTime.nut" import getServerTime
from "%rGui/components/unseenMark.nut" import priorityUnseenMark
from "%rGui/seasonScene/seasonSceneState.nut" import openEventShopWnd
from "%rGui/shop/eventShopState.nut" import getShopEventName
from "%rGui/shop/shopState.nut" import hasUnseenGoodsByShop, goodsByShop, soonGoodsByShop, soonPersonalGoodsByShop,
  personalGoodsByShop
from "%rGui/components/timerBlock.nut" import mkTimer


const eventShopBtnIconSize = hdpx(150)
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
  let eventName = Computed(@() getShopEventName(sId, goodsByShop.get(), soonGoodsByShop.get(), soonPersonalGoodsByShop.get(), personalGoodsByShop.get()))
  let eventCfg = Computed(function() {
    let time = getServerTime() 
    local eventIdCounts = {}
    local timeEndCounts = {}
    foreach(goodsList in goodsByShop.get()[sId])
      foreach(goods in goodsList) {
        inc(eventIdCounts, goods.meta?.event_id ?? "")
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
        inc(eventIdCounts, goods.meta?.event_id ?? "")
        if (goods.timeRanges.len() == 0)
          continue
        let { start = 0 } = goods.timeRanges.findvalue(@(tr) tr.start > time)
        if (start > 0)
          inc(timeEndCounts, start)
      }
    foreach (goodsList in soonPersonalGoodsByShop.get()[sId])
      foreach (goods in goodsList) {
        inc(eventIdCounts, goods.meta?.event_id ?? "")
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
  let timeEndW = Computed(@() eventCfg.get().timeEnd)
  return @() {
    watch = [eventButtonSF, isEventShopHasUnseen, eventCfg, eventName]
    behavior = Behaviors.Button
    onClick = @() openEventShopWnd(eventName.get())
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
        size = const [eventShopBtnIconSize, eventShopBtnIconSize]
        rendObj = ROBJ_IMAGE
        image = Picture($"{getEventPresentation(eventCfg.get().eventId).image }:{eventShopBtnIconSize}:{eventShopBtnIconSize}:P")
        fallbackImage = Picture($"ui/gameuiskin/icon_event_event_black_friday_shop.avif:{eventShopBtnIconSize}:{eventShopBtnIconSize}:P")
        keepAspect = true
      }
      mkTimer(timeEndW,
      {
        pos = const [0, eventShopBtnIconSize]
        halign = ALIGN_CENTER
      }, fontTinyAccentedShaded)
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
