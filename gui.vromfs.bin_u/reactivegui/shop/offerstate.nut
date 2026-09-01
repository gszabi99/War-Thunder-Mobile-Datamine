from "%globalsDarg/darg_library.nut" import *
from "dagor.time" import get_time_msec
from "dagor.workcycle" import deferOnce
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/underscore.nut" import isEqual
from "%appGlobals/clientState/clientState.nut" import isInBattle
from "%appGlobals/loginState.nut" import isLoggedIn
from "%appGlobals/pServer/campaign.nut" import activeOffers, curCampaign, isAnyCampaignSelected
from "%appGlobals/pServer/pServerApi.nut" import check_new_offer, shopPurchaseInProgress
from "%appGlobals/timeoutExt.nut" import resetExtTimeout, clearExtTimer
from "%appGlobals/userstats/serverTime.nut" import isServerTimeValid, getServerTime
from "%rGui/shop/goodsStates.nut" import PURCHASING, DELAYED
from "%rGui/shop/platformGoods.nut" import platformOffer, platformPurchaseInProgress, isGoodsOnlyInternalPurchase


const REQUEST_TIMEOUT_MSEC = 300000 

let attachedOfferPromo = Watched({})
let blockRequestMsec = hardPersistWatched("offerState.lastOfferRequest", {})
let isOfferPromoAttached = Computed(@() attachedOfferPromo.get().len() > 0)
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
    clearExtTimer(updateOutdatedOffer)
  else
    resetExtTimeout(leftTime, updateOutdatedOffer)
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
activeOffers.subscribe(@(_) blockRequestMsec.set({}))

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
    resetExtTimeout(nextTime * 0.001, updateBlockRequestTimer)
}
updateBlockRequestTimer()
blockRequestMsec.subscribe(@(_) deferOnce(updateBlockRequestTimer))

let prevIfEqual = @(prev, new) isEqual(prev, new) ? prev : new
let activeOffer = Computed(@(prev) prevIfEqual(prev,
  activeOffers.get() == null ? null
    : isGoodsOnlyInternalPurchase(activeOffers.get()) ? activeOffers.get()
    : platformOffer.get()))
let visibleOffer = Computed(@() isOfferOutdated.get() ? null : activeOffer.get())

let offerPurchasingState = Computed(function() {
  local res = 0
  let goods = activeOffers.get()
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
  activeOffer 
  visibleOffer 
  offerPurchasingState

  onOfferPromoAttach = @(key) attachedOfferPromo.mutate(@(v) v.__update({ [key]  = true }))
  onOfferPromoDetach = @(key) key not in attachedOfferPromo.get() ? null
    : attachedOfferPromo.mutate(@(v) v.$rawdelete(key))
}