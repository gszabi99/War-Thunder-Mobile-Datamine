from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/campaign.nut" import curCampaign, purchasesCount, todayPurchasesCount
from "%appGlobals/pServer/pServerApi.nut" import shopPurchaseInProgress
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/rewardType.nut" import unitRewardTypes
from "%appGlobals/userstats/serverTimeDay.nut" import serverTimeDay, getDay, dayOffset
from "%rGui/rewards/rewardViewInfo.nut" import isEmptyByRType
from "%rGui/shop/goodsStates.nut" import PURCHASING, DELAYED
from "%rGui/shop/platformGoods.nut" import platformPurchaseInProgress, isGoodsOnlyInternalPurchase
from "%rGui/shop/shopState.nut" import shopGoods


let activeOffersByGoods = Computed(function() {
  let campaign = curCampaign.get()
  let configs = serverConfigs.get()

  return shopGoods.get().reduce(function(res, g) {
    let { showAsOffer = null } = g?.meta
    if (showAsOffer != "" && showAsOffer != campaign)
      return res
    let { id, rewards, limit, dailyLimit } = g
    if (limit > 0 && limit <= (purchasesCount.get()?[id].count ?? 0))
      return res
    if (dailyLimit > 0) {
      let { lastTime = 0, count = 0 } = todayPurchasesCount.get()?[id]
      let today = getDay(lastTime, dayOffset.get()) == serverTimeDay.get() ? count : 0
      if (dailyLimit <= today)
        return res
    }

    let profile = servProfile.get()
    foreach(r in rewards)
      if (r.gType in unitRewardTypes
          && (isEmptyByRType?[r.gType](r.id, r.subId, profile, configs) ?? false))
        return res
    res[id] <- g.__merge({ campaign, offerClass = "seasonal" })
    return res
  }, {})
})

let mkOfferByGoodsPurchasingState = @(id) Computed(function() {
  local res = 0
  let goods = activeOffersByGoods?[id].get()
  if (goods == null)
    return 0
  let idInProgress = isGoodsOnlyInternalPurchase(goods) ? shopPurchaseInProgress.get()
    : platformPurchaseInProgress.get()
  if (idInProgress != null) {
    res = res | DELAYED
    if (idInProgress == goods.id)
      res = res | PURCHASING
  }
  return res
})

return {
  activeOffersByGoods
  mkOfferByGoodsPurchasingState
}