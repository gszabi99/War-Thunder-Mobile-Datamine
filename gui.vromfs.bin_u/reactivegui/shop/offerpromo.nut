from "%globalsDarg/darg_library.nut" import *
let { visibleOffer, onOfferSceneAttach, onOfferSceneDetach, offerPurchasingState, reqAddonsToShowOffer
} = require("offerState.nut")
let { activeOfferByGoods, offerByGoodsPurchasingState, reqAddonsToShowOfferByGoods
} = require("offerByGoodsState.nut")
let { mkOffer } = require("%rGui/shop/goodsView/offers.nut")
let { openGoodsPreview, previewType } = require("%rGui/shop/goodsPreviewState.nut")
let { buyPlatformGoods } = require("platformGoods.nut")
let { sendOfferBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { openDownloadAddonsWnd } = require("%rGui/updater/updaterState.nut")
let { eventGift, eventGiftGap } = require("%rGui/event/eventGift.nut")


function previewOffer() {
  if (visibleOffer.get() == null)
    return

  if (reqAddonsToShowOffer.get().len() == 0) {
    openGoodsPreview(visibleOffer.get().id)
    if (previewType.get() == null) { //no preview for such goods yet
      buyPlatformGoods(visibleOffer.get())
      sendOfferBqEvent("gotoPurchaseFromBanner", visibleOffer.get().campaign)
    }
    else
      sendOfferBqEvent("openInfoFromBanner", visibleOffer.get().campaign)
    return
  }

  openDownloadAddonsWnd(reqAddonsToShowOffer.get(), "openGoodsPreview", { id = visibleOffer.get().id })
  sendOfferBqEvent("openInfoFromBanner", visibleOffer.get().campaign)
}


function previewOfferByGoods() {
  if (activeOfferByGoods.get() == null)
    return

  if (reqAddonsToShowOfferByGoods.get().len() == 0) {
    openGoodsPreview(activeOfferByGoods.get().id)
    if (previewType.get() == null) //no preview for such goods yet
      buyPlatformGoods(activeOfferByGoods.get())
    return
  }

  openDownloadAddonsWnd(reqAddonsToShowOfferByGoods.get(), "openGoodsPreview", { id = activeOfferByGoods.get().id })
}


let promoKey = {}
let offerPromo = @() {
  watch = [visibleOffer, activeOfferByGoods]
  key = promoKey
  onAttach = @() onOfferSceneAttach(promoKey)
  onDetach = @() onOfferSceneDetach(promoKey)
  flow = FLOW_HORIZONTAL
  halign = ALIGN_RIGHT
  gap = eventGiftGap
  children = [
    eventGift
    visibleOffer.get() == null && activeOfferByGoods.get() == null ? null
      : {
          flow = FLOW_VERTICAL
          gap = hdpx(5)
          children = [
            visibleOffer.get() == null ? null
              : mkOffer(visibleOffer.get(), previewOffer, offerPurchasingState)
            activeOfferByGoods.get() == null ? null
              : mkOffer(activeOfferByGoods.get(), previewOfferByGoods, offerByGoodsPurchasingState)
          ]
        }
  ]
}

return offerPromo
