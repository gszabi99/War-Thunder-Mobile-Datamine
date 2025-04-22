from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { openGoodsPreviewInMenuOnly, previewGoods } = require("%rGui/shop/goodsPreviewState.nut")
let { visibleOffer, reqAddonsToShowOffer } = require("offerState.nut")
let { isInMenuNoModals, isMainMenuAttached } = require("%rGui/mainMenu/mainMenuState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { sendOfferBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { hasSavedDeepLink } = require("%rGui/notifications/appsFlierDeepLink.nut")
let { registerAutoDownloadAddons } = require("%rGui/updater/updaterState.nut")


let showedTime = hardPersistWatched("offerAutoPreview.showedTime", {})
let enteredMenuTime = hardPersistWatched("offerAutoPreview.enteredMenuTime", {})
let canShow = Computed(@() visibleOffer.get() != null
  && !hasSavedDeepLink.get()
  && !isInBattle.get()
  && reqAddonsToShowOffer.get().len() == 0
  && isInMenuNoModals.get()
  && (visibleOffer.get()?.endTime ?? 0) > (showedTime.value?[visibleOffer.get()?.campaign] ?? 0))

let needShow = keepref(Computed(@() canShow.value
  && (showedTime.value?[visibleOffer.value?.campaign] ?? 0) == 0))

let isVisiblePreviewOpened = keepref(Computed(@() visibleOffer.value != null
  && previewGoods.value?.id == visibleOffer.value?.id))

isMainMenuAttached.subscribe(function(v) {
  if (!v || curCampaign.value == null)
    return
  let { campaign = curCampaign.value, endTime = 0 } = visibleOffer.value
  if (enteredMenuTime.value?[campaign] != endTime)
    enteredMenuTime.mutate(@(list) list[campaign] <- endTime)
})

function openOfferPreview() {
  if (!needShow.value)
    return
  openGoodsPreviewInMenuOnly(visibleOffer.value?.id)
  sendOfferBqEvent("openInfoAutomatically", visibleOffer.value.campaign)
}

needShow.subscribe(@(need) need ? resetTimeout(0.3, openOfferPreview) : null)

visibleOffer.subscribe(@(offer) offer ? showedTime.mutate(@(val) val.$rawdelete(offer.campaign)) : null)
isVisiblePreviewOpened.subscribe(function(v) {
  if (!v)
    return
  let { endTime, campaign } = visibleOffer.value
  showedTime.mutate(@(val) val[campaign] <- endTime)
})

isLoggedIn.subscribe(function(v) {
  if (v)
    return
  showedTime({})
  enteredMenuTime({})
})

registerAutoDownloadAddons(reqAddonsToShowOffer)
