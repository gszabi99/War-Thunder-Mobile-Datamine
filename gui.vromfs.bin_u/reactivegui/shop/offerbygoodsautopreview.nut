from "%globalsDarg/darg_library.nut" import *
let { abTests } = require("%appGlobals/pServer/campaign.nut")
let { activeOffersByGoods } = require("%rGui/shop/offerByGoodsState.nut")
let { isFitSeasonRewardsRequirements } = require("%rGui/event/eventState.nut")


let showInRow = Computed(@() (abTests.get()?.autoShowOffersByGoodsInRow ?? "false") == "true")

let offersByGoodsToShow = Computed(@() !isFitSeasonRewardsRequirements.get() ? []
  : activeOffersByGoods.get().values() ?? [])

return {
  offersByGoodsToShow
  showInRow
}