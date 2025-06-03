from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { isEqual } = require("%sqstd/underscore.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { platformOffer, platformPurchaseInProgress, isGoodsOnlyInternalPurchase } = require("platformGoods.nut")
let { check_new_offer, shopPurchaseInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { activeOffers, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { PURCHASING, DELAYED } = require("goodsStates.nut")
let { getGoodsType } = require("shopCommon.nut")


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
let prevIfEqual = @(prev, new) isEqual(prev, new) ? prev : new
let activeOffer = Computed(@(prev) prevIfEqual(prev,
  activeOffers.value == null ? null
    : isGoodsOnlyInternalPurchase(activeOffers.value) ? addGType(activeOffers.value)
    : addGType(platformOffer.value)))
let visibleOffer = Computed(@() isOfferOutdated.value ? null : activeOffer.value)

let checkNewOffer = @() check_new_offer(curCampaign.value)
function updateRequestTimer(info) {
  let { time, needRequestNow } = info
  let timeLeft = needRequestNow ? 0.01 : time - serverTime.value + 1
  if (timeLeft > 0)
    resetTimeout(timeLeft, checkNewOffer)
  else
    clearTimer(checkNewOffer) 
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

return {
  activeOffer 
  visibleOffer 
  offerPurchasingState

  onOfferSceneAttach = @(key) attachedOfferScenes.mutate(@(v) v.__update({ [key]  = true }))
  onOfferSceneDetach = @(key) key not in attachedOfferScenes.value ? null
    : attachedOfferScenes.mutate(@(v) v.$rawdelete(key))
}