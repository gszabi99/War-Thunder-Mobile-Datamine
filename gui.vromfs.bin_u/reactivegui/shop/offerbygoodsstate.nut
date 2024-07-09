from "%globalsDarg/darg_library.nut" import *
let { getUnitPkgs } = require("%appGlobals/updater/campaignAddons.nut")
let hasAddons = require("%appGlobals/updater/hasAddons.nut")
let { platformPurchaseInProgress, isGoodsOnlyInternalPurchase } = require("platformGoods.nut")
let { shopPurchaseInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { shopGoods } = require("shopState.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { PURCHASING, DELAYED } = require("goodsStates.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { isReadyToFullLoad } = require("%appGlobals/loginState.nut")


let activeOfferByGoods = Computed(function() {
  let campaign = curCampaign.get()
  let res = shopGoods.get()
    .findvalue(function(g) {
      let { showAsOffer = null } = g?.meta
      return showAsOffer == "" || showAsOffer == campaign
    })
  if (res == null)
    return null

  foreach (unitName in res.units)
    if (unitName in servProfile.get()?.units)
      return null
  foreach (unitName in res.unitUpgrades)
    if (servProfile.get()?.units[unitName].isUpgraded)
      return null

  return res.__merge({ campaign, offerClass = "seasonal" })
})

let offerByGoodsPurchasingState = Computed(function() {
  local res = 0
  let goods = activeOfferByGoods.get()
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

let reqAddonsToShowOfferByGoods = Computed(function() {
  let unit = serverConfigs.get()?.allUnits[activeOfferByGoods.get()?.unitUpgrades[0] ?? activeOfferByGoods.get()?.units[0]]
  if (unit == null || !isReadyToFullLoad.get())
    return []
  return getUnitPkgs(unit.name, unit.mRank).filter(@(a) !hasAddons.get()?[a])
})

return {
  activeOfferByGoods
  offerByGoodsPurchasingState
  reqAddonsToShowOfferByGoods
}