from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/rewardType.nut" import G_DISCOUNT, unitRewardTypes
from "%appGlobals/unitPresentation.nut" import getUnitName
from "%appGlobals/config/eventSeasonPresentation.nut" import getEventPresentation
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%rGui/shop/shopState.nut" import isDisabledGoods
from "%rGui/rewards/rewardViewInfo.nut" import getUnlockRewardsViewInfo
from "%rGui/event/eventState.nut" import curEvent, eventSeason, allSpecialEvents, MAIN_EVENT_ID
from "%rGui/battlePass/operationPassState.nut" import OP_EVENT_ID, opSeasonName
from "%rGui/quests/questsState.nut" import progressUnlockByTab
from "%rGui/shop/shopState.nut" import allShopGoods


function getSpecialEventRewardUnitName(stages, servConfigs, allGoods) {
  foreach (stage in stages) {
    let reward = getUnlockRewardsViewInfo(stage, servConfigs)
      .findvalue(@(r) r.rType == G_DISCOUNT && !isDisabledGoods(r, allGoods, servConfigs))
    if (reward == null)
      continue
    let goodsId = servConfigs?.personalDiscounts.findindex(@(list) list.findindex(@(v) v.id == reward.id) != null)
    return allGoods?[goodsId].rewards.findvalue(@(r) r.gType in unitRewardTypes).id ?? ""
  }
  return ""
}

function getSpecialEventLocName(eventName, rewardUnitName) {
  let defaultLoc = loc(getEventPresentation(eventName).locId)
  return defaultLoc.contains("{name}") 
    ? defaultLoc.subst({ name = getUnitName(rewardUnitName).replace(" ", nbsp) })
    : defaultLoc
}


let getMainEventLoc = @(eSeason) eSeason == "" ? loc("events/name/default")
  : loc($"events/name/{eSeason}")

let getEventLocFull = @(eventId, eventSeasonV, allSpecialEventsV, progressUnlockByTabV, serverConfigsV, allShopGoodsV, opName)
  eventId == MAIN_EVENT_ID ? getMainEventLoc(eventSeasonV)
    : eventId == OP_EVENT_ID ? opName
    : eventId == "" ? loc("quests/achievements")
    : eventId not in allSpecialEventsV ? loc(getEventPresentation(eventId).locId)
    : getSpecialEventLocName(allSpecialEventsV[eventId].eventName,
        getSpecialEventRewardUnitName(progressUnlockByTabV?[eventId].stages ?? [],
           serverConfigsV, allShopGoodsV))

let mkEventLocComp = @(eventId) Computed(@() getEventLocFull(eventId.get(), eventSeason.get(),
  allSpecialEvents.get(), progressUnlockByTab.get(), serverConfigs.get(), allShopGoods.get(),
  opSeasonName.get()))

let curEventLoc = mkEventLocComp(curEvent)

return {
  getSpecialEventLocName
  getSpecialEventRewardUnitName

  getMainEventLoc
  mkEventLocComp
  curEventLoc
}
