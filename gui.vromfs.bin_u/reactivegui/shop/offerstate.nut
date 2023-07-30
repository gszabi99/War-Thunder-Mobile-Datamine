from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { platformOffer, platformPurchaseInProgress } = require("platformGoods.nut")
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
let function updateOutdatedTimer(offer) {
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
  : (activeOffers.value?.purchaseGuid ?? "") == "" ? addGType(activeOffers.value)
  : addGType(platformOffer.value))
let visibleOffer = Computed(@() isOfferOutdated.value ? null : activeOffer.value)

let checkNewOffer = @() check_new_offer(curCampaign.value)
let function updateRequestTimer(info) {
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
  let idInProgress = (goods?.purchaseGuid ?? "") == "" ? shopPurchaseInProgress.value
    : platformPurchaseInProgress.value
  if (idInProgress != null) {
    res = res | DELAYED
    if (idInProgress == goods.id)
      res = res | PURCHASING
  }
  return res
})

return {
  activeOffer //otdated offer can be here. Need to not leave preview on time left
  visibleOffer //only active by timer offer here. banner hides for outdated offer
  offerPurchasingState

  onOfferSceneAttach = @(key) attachedOfferScenes.mutate(@(v) v.__update({ [key]  = true }))
  onOfferSceneDetach = @(key) key not in attachedOfferScenes.value ? null
    : attachedOfferScenes.mutate(@(v) delete v[key])
}