from "%globalsDarg/darg_library.nut" import *
let { visibleOffer, onOfferSceneAttach, onOfferSceneDetach, offerPurchasingState
} = require("offerState.nut")
let { mkOffer } = require("%rGui/shop/goodsView/offers.nut")
let { openGoodsPreview, previewType } = require("%rGui/shop/goodsPreviewState.nut")
let { showPriceOnBanner } = require("offerTests.nut")
let { buyPlatformGoods } = require("platformGoods.nut")
let { sendOfferBqEvent } = require("%appGlobals/pServer/bqClient.nut")

let function previewOffer() {
  if (visibleOffer.value == null)
    return

  openGoodsPreview(visibleOffer.value.id)
  if (previewType.value == null) { //no preview for such goods yet
    buyPlatformGoods(visibleOffer.value)
    sendOfferBqEvent("gotoPurchaseFromBanner", visibleOffer.value.campaign)
  }
  else
    sendOfferBqEvent("openInfoFromBanner", visibleOffer.value.campaign)
}

let promoKey = {}
let offerPromo = @() {
  watch = [visibleOffer, showPriceOnBanner]
  key = promoKey
  onAttach = @() onOfferSceneAttach(promoKey)
  onDetach = @() onOfferSceneDetach(promoKey)
  children = visibleOffer.value == null ? null
    : mkOffer(visibleOffer.value, previewOffer, offerPurchasingState, showPriceOnBanner.value)
}

return offerPromo
