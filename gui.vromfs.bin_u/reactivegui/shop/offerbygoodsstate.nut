from "%globalsDarg/darg_library.nut" import *
let { shopPurchaseInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { curCampaign, purchasesCount, todayPurchasesCount } = require("%appGlobals/pServer/campaign.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { unitRewardTypes } = require("%appGlobals/rewardType.nut")
let { serverTimeDay, getDay, dayOffset } = require("%appGlobals/userstats/serverTimeDay.nut")
let { platformPurchaseInProgress, isGoodsOnlyInternalPurchase } = require("%rGui/shop/platformGoods.nut")
let { shopGoods } = require("%rGui/shop/shopState.nut")
let { PURCHASING, DELAYED } = require("%rGui/shop/goodsStates.nut")
let { isEmptyByRType } = require("%rGui/rewards/rewardViewInfo.nut")


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