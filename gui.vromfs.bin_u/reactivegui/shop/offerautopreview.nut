from "%globalsDarg/darg_library.nut" import *
from "%sqstd/globalState.nut" import hardPersistWatched
from "%rGui/notifications/appsFlierDeepLink.nut" import hasSavedDeepLink
from "%rGui/shop/goodsPreviewState.nut" import previewGoods
from "%rGui/shop/offerState.nut" import visibleOffer


let offerShowedTime = hardPersistWatched("offerAutoPreview.showedTime", {})

let offerToShow = Computed(@() !hasSavedDeepLink.get() ? visibleOffer.get() : null)

let isVisiblePreviewOpened = keepref(Computed(@() visibleOffer.get() != null
  && previewGoods.get()?.id == visibleOffer.get()?.id))

isVisiblePreviewOpened.subscribe(@(v) !v || visibleOffer.get() == null ? null
  : offerShowedTime.mutate(@(val) val[visibleOffer.get().campaign] <- visibleOffer.get().endTime))

return {
  offerToShow
  offerShowedTime
}
