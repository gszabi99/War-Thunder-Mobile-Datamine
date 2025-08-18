from "%globalsDarg/darg_library.nut" import *
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { previewGoods } = require("%rGui/shop/goodsPreviewState.nut")
let { visibleOffer } = require("%rGui/shop/offerState.nut")
let { hasSavedDeepLink } = require("%rGui/notifications/appsFlierDeepLink.nut")


let offerShowedTime = hardPersistWatched("offerAutoPreview.showedTime", {})

let offerToShow = Computed(@() !hasSavedDeepLink.get() ? visibleOffer.get() : null)

let isVisiblePreviewOpened = keepref(Computed(@() visibleOffer.get() != null
  && previewGoods.get()?.id == visibleOffer.get()?.id))

isVisiblePreviewOpened.subscribe(@(v) !v ? null
  : offerShowedTime.mutate(@(val) val[visibleOffer.get().campaign] <- visibleOffer.get().endTime))

return {
  offerToShow
  offerShowedTime
}
