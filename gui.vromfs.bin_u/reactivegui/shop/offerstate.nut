from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, clearTimer, deferOnce } = require("dagor.workcycle")
let { get_time_msec } = require("dagor.time")
let { isEqual } = require("%sqstd/underscore.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isServerTimeValid, getServerTime } = require("%appGlobals/userstats/serverTime.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { platformOffer, platformPurchaseInProgress, isGoodsOnlyInternalPurchase } = require("platformGoods.nut")
let { check_new_offer, shopPurchaseInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { activeOffers, curCampaign, isAnyCampaignSelected } = require("%appGlobals/pServer/campaign.nut")
let { PURCHASING, DELAYED } = require("goodsStates.nut")
let { getGoodsType } = require("shopCommon.nut")


const REQUEST_TIMEOUT_MSEC = 300000 

let attachedOfferPromo = Watched({})
let blockRequestMsec = hardPersistWatched("offerState.lastOfferRequest", {})
let isOfferPromoAttached = Computed(@() attachedOfferPromo.value.len() > 0)
let isOfferOutdated = Watched(false)
let nextOfferRequestInfo = keepref(Computed(function() {
  let campaign = isAnyCampaignSelected.get() ? curCampaign.get() : ""
  return {
    campaign
    needRequestNow = campaign != ""
      && campaign not in blockRequestMsec.get()
      && isOfferPromoAttached.get()
      && (activeOffers.get() == null || isOfferOutdated.get())
  }
}))

function updateOutdatedOffer() {
  if (!isServerTimeValid.get() || activeOffers.get() == null) {
    isOfferOutdated.set(false)
    return
  }
  let leftTime = (activeOffers.get()?.endTime ?? 0) - getServerTime()
  isOfferOutdated.set(leftTime <= 0)
  if (leftTime <= 0)
    clearTimer(updateOutdatedOffer)
  else
    resetTimeout(leftTime, updateOutdatedOffer)
}
updateOutdatedOffer()
activeOffers.subscribe(@(_) updateOutdatedOffer())
isServerTimeValid.subscribe(@(_) updateOutdatedOffer())

function checkNewOfferIfNeed() {
  let { campaign, needRequestNow } = nextOfferRequestInfo.get()
  if (!needRequestNow)
    return
  blockRequestMsec.mutate(@(v) v[campaign] <- get_time_msec() + REQUEST_TIMEOUT_MSEC)
  check_new_offer(campaign)
}
deferOnce(checkNewOfferIfNeed)
nextOfferRequestInfo.subscribe(@(_) deferOnce(checkNewOfferIfNeed))

isInBattle.subscribe(@(v) v ? null : blockRequestMsec.set({}))
isLoggedIn.subscribe(@(v) v ? null : blockRequestMsec.set({}))

function updateBlockRequestTimer() {
  let timerCount = blockRequestMsec.get().len()
  if (timerCount == 0)
    return
  let time = get_time_msec()
  let activeTimers = blockRequestMsec.get().filter(@(v) v > time)
  if (activeTimers.len() != timerCount)
    blockRequestMsec.set(activeTimers)

  local nextTime = (activeTimers.reduce(@(a, b) min(a, b)) ?? 0) - time
  if (nextTime > 0)
    resetTimeout(nextTime * 0.001, updateBlockRequestTimer)
}
updateBlockRequestTimer()
blockRequestMsec.subscribe(@(_) deferOnce(updateBlockRequestTimer))

let addGType = @(offer) offer == null ? null : offer.__merge({ gtype = getGoodsType(offer) })
let prevIfEqual = @(prev, new) isEqual(prev, new) ? prev : new
let activeOffer = Computed(@(prev) prevIfEqual(prev,
  activeOffers.value == null ? null
    : isGoodsOnlyInternalPurchase(activeOffers.value) ? addGType(activeOffers.value)
    : addGType(platformOffer.value)))
let visibleOffer = Computed(@() isOfferOutdated.value ? null : activeOffer.value)

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

  onOfferPromoAttach = @(key) attachedOfferPromo.mutate(@(v) v.__update({ [key]  = true }))
  onOfferPromoDetach = @(key) key not in attachedOfferPromo.value ? null
    : attachedOfferPromo.mutate(@(v) v.$rawdelete(key))
}