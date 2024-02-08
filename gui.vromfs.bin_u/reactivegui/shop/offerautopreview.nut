from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { openGoodsPreview, previewGoods } = require("%rGui/shop/goodsPreviewState.nut")
let { visibleOffer, reqAddonsToShowOffer } = require("offerState.nut")
let { isInMenuNoModals, isMainMenuAttached } = require("%rGui/mainMenu/mainMenuState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { sendOfferBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")

let showedTime = hardPersistWatched("offerAutoPreview.showedTime", {})
let enteredMenuTime = hardPersistWatched("offerAutoPreview.enteredMenuTime", {})
let canShow = Computed(@() visibleOffer.value != null
  && !isInBattle.value
  && reqAddonsToShowOffer.value.len() == 0
  && isInMenuNoModals.value
  && (visibleOffer.value?.endTime ?? 0) > (showedTime.value?[visibleOffer.value?.campaign] ?? 0))

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
  openGoodsPreview(visibleOffer.value?.id)
  sendOfferBqEvent("openInfoAutomatically", visibleOffer.value.campaign)
}

needShow.subscribe(@(need) need ? resetTimeout(0.3, openOfferPreview) : null)

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
