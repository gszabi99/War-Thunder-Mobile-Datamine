from "%globalsDarg/darg_library.nut" import *
let { platformPurchaseInProgress, isGoodsOnlyInternalPurchase } = require("platformGoods.nut")
let { shopPurchaseInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { shopGoods } = require("shopState.nut")
let { curCampaign, purchasesCount } = require("%appGlobals/pServer/campaign.nut")
let { PURCHASING, DELAYED } = require("goodsStates.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")


let activeOffersByGoods = Computed(function() {
  let campaign = curCampaign.get()
  let servProfileUnits = servProfile.get()?.units

  return shopGoods.get().reduce(function(res, g) {
    let { showAsOffer = null } = g?.meta
    if (showAsOffer != "" && showAsOffer != campaign)
      return res
    let { units, unitUpgrades, id } = g
    if (purchasesCount.get()?[id])
      return res
    foreach (unitName in units)
      if (unitName in servProfileUnits)
        return res
    foreach (unitName in unitUpgrades)
      if (servProfileUnits?[unitName].isUpgraded)
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