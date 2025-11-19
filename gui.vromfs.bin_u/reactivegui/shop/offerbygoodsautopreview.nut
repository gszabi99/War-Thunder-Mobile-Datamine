from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { abTests } = require("%appGlobals/pServer/campaign.nut")
let { activeOffersByGoods } = require("%rGui/shop/offerByGoodsState.nut")
let { isFitSeasonRewardsRequirements } = require("%rGui/event/eventState.nut")


let isDebugMode = hardPersistWatched("offerByGoodsAutoPreview.isDebugMode", false)

let showInRowBase = Computed(@() (abTests.get()?.autoShowOffersByGoodsInRow ?? "false") == "true")
let showInRow = Computed(@() showInRowBase.get() != isDebugMode.get())

let offersByGoodsToShow = Computed(@() !isFitSeasonRewardsRequirements.get() ? []
  : activeOffersByGoods.get().values() ?? [])

register_command(
  function() {
    isDebugMode.set(!isDebugMode.get())
    console_print($"showInRow = {showInRow.get()}") 
  },
  "debug.toggleAbTest.autoShowOffersByGoodsInRow")

return {
  offersByGoodsToShow
  showInRow
}