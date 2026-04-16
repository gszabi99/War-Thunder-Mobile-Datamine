from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/rewardType.nut" import G_DISCOUNT, unitRewardTypes
from "%appGlobals/unitPresentation.nut" import getUnitName
from "%appGlobals/config/eventSeasonPresentation.nut" import getEventPresentation
from "%rGui/shop/shopState.nut" import isDisabledGoods
from "%rGui/rewards/rewardViewInfo.nut" import getUnlockRewardsViewInfo

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
    ? defaultLoc.subst({ name = getUnitName(rewardUnitName, loc).replace(" ", nbsp) })
    : defaultLoc
}

return {
  getSpecialEventLocName
  getSpecialEventRewardUnitName
}
