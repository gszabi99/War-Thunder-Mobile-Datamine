from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { abTests } = require("%appGlobals/pServer/campaign.nut")
let { previewGoods } = require("%rGui/shop/goodsPreviewState.nut")
let { activeOffersByGoods } = require("%rGui/shop/offerByGoodsState.nut")
let { isFitSeasonRewardsRequirements } = require("%rGui/event/eventState.nut")


let offersByGoodsShowedState = hardPersistWatched("offerByGoodsAutoPreview.offersByGoodsShowedState", {})

let isDebugMode = hardPersistWatched("offerByGoodsAutoPreview.isDebugMode", false)

let showInRowBase = Computed(@() (abTests.get()?.autoShowOffersByGoodsInRow ?? "false") == "true")
let showInRow = Computed(@() showInRowBase.get() != isDebugMode.get())

let offersByGoodsToShow = Computed(@() !isFitSeasonRewardsRequirements.get() ? []
  : activeOffersByGoods.get().values().filter(@(v) !offersByGoodsShowedState.get()?[v?.campaign][v?.id]) ?? [])

let isVisiblePreviewOpened = keepref(Computed(@() activeOffersByGoods.get().len() > 0
  && null != activeOffersByGoods.get()?[previewGoods.get()?.id]))

isVisiblePreviewOpened.subscribe(@(v) !v ? null
  : offersByGoodsShowedState.mutate(function(val) {
      if (!val?[previewGoods.get().campaign])
        val[previewGoods.get().campaign] <- {}
      val[previewGoods.get().campaign][previewGoods.get().id] <- true
    }))

register_command(
  function() {
    isDebugMode.set(!isDebugMode.get())
    console_print($"showInRow = {showInRow.get()}") 
  },
  "debug.toggleAbTest.autoShowOffersByGoodsInRow")

return {
  offersByGoodsToShow
  offersByGoodsShowedState
  showInRow
}