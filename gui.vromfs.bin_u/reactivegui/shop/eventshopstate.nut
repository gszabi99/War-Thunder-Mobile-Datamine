from "%globalsDarg/darg_library.nut" import *
from "%rGui/event/eventState.nut" import MAIN_EVENT_ID





function getShopIdForEventId(eventId, specialEventsV, goodsByShopV, soonGoodsByShopV, soonPersonalGoodsByShopV,
  personalGoodsByShopV
) {
  if (eventId == null || eventId == "" || eventId == MAIN_EVENT_ID)
    return null
  let eventName = specialEventsV?[eventId].eventName ?? eventId
  foreach (shopGoods in [goodsByShopV, soonGoodsByShopV, soonPersonalGoodsByShopV, personalGoodsByShopV])
    foreach (shopId, goodsByCat in shopGoods) {
      if (shopId == "common")
        continue
      foreach (goodsList in goodsByCat)
        foreach (goods in goodsList)
          if (goods.meta?.event_id == eventName || goods.meta?.event_id == eventId)
            return shopId
    }
  return null
}

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

function getShopEventName(sId, goodsByShopV, soonGoodsByShopV, soonPersonalGoodsByShopV, personalGoodsByShopV) {
  local eventIdCounts = {}
  foreach (goodsByCat in [goodsByShopV[sId], soonGoodsByShopV[sId], soonPersonalGoodsByShopV[sId], personalGoodsByShopV[sId]])
    foreach (goodsList in goodsByCat)
      foreach (goods in goodsList)
        inc(eventIdCounts, goods?.meta?.event_id ?? "")
  eventIdCounts.$rawdelete("")
  return bestKey(eventIdCounts) ?? ""
}

return {
  getShopIdForEventId
  getShopEventName
}
