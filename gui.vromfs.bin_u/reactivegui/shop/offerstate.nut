from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { platformOffer, platformPurchaseInProgress, isGoodsOnlyInternalPurchase } = require("platformGoods.nut")
let { check_new_offer, shopPurchaseInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { activeOffers, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { PURCHASING, DELAYED } = require("goodsStates.nut")
let { getGoodsType } = require("shopCommon.nut")
let { getUnitPkgs } = require("%appGlobals/updater/campaignAddons.nut")
let hasAddons = require("%appGlobals/updater/hasAddons.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")

let attachedOfferScenes = Watched({})
let isOfferAttached = Computed(@() attachedOfferScenes.value.len() > 0)
let isOfferOutdated = Watched(false)
let nextOfferRequestInfo = keepref(Computed(@() {
  needRequestNow = isOfferAttached.value && (activeOffers.value == null || isOfferOutdated.value)
  time = !isOfferAttached.value ? 0
    : (activeOffers.value?.endTime ?? 0)
}))

let markOfferOutdated = @() isOfferOutdated(true)
function updateOutdatedTimer(offer) {
  let leftTime = (offer?.endTime ?? 0) - serverTime.value
  isOfferOutdated(leftTime <= 0)
  if (leftTime <= 0)
    clearTimer(markOfferOutdated)
  else
    resetTimeout(leftTime, markOfferOutdated)
}
updateOutdatedTimer(activeOffers.value)
activeOffers.subscribe(updateOutdatedTimer)

let addGType = @(offer) offer == null ? null : offer.__merge({ gtype = getGoodsType(offer) })
let activeOffer = Computed(@() activeOffers.value == null ? null
  : isGoodsOnlyInternalPurchase(activeOffers.value) ? addGType(activeOffers.value)
  : addGType(platformOffer.value))
let visibleOffer = Computed(@() isOfferOutdated.value ? null : activeOffer.value)

let checkNewOffer = @() check_new_offer(curCampaign.value)
function updateRequestTimer(info) {
  let { time, needRequestNow } = info
  let timeLeft = needRequestNow ? 0.01 : time - serverTime.value + 1
  if (timeLeft > 0)
    resetTimeout(timeLeft, checkNewOffer)
  else
    clearTimer(checkNewOffer) //no need to request new offer when window not attached. To allow last chance offer purchase from full screen window.
}
updateRequestTimer(nextOfferRequestInfo.value)
nextOfferRequestInfo.subscribe(updateRequestTimer)

let offerPurchasingState = Computed(function() {
  local res = 0
  let goods = activeOffers.value
  if (goods == null)
    return 0
  let idInProgress = isGoodsOnlyInternalPurchase(goods) ? shopPurchaseInProgress.value
    : platformPurchaseInProgress.value
  if (idInProgress != null) {
    res = res | DELAYED
    if (idInProgress == goods.id)
      res = res | PURCHASING
  }
  return res
})

let reqAddonsToShowOffer = Computed(function() {
  let unit = serverConfigs.value?.allUnits[visibleOffer.value?.unitUpgrades[0] ?? visibleOffer.value?.units[0]]
  if (unit == null)
    return []
  return getUnitPkgs(unit.name, unit.mRank).filter(@(a) !hasAddons.value?[a])
})

return {
  activeOffer //otdated offer can be here. Need to not leave preview on time left
  visibleOffer //only active by timer offer here. banner hides for outdated offer
  offerPurchasingState
  reqAddonsToShowOffer

  onOfferSceneAttach = @(key) attachedOfferScenes.mutate(@(v) v.__update({ [key]  = true }))
  onOfferSceneDetach = @(key) key not in attachedOfferScenes.value ? null
    : attachedOfferScenes.mutate(@(v) v.$rawdelete(key))
}