from "%globalsDarg/darg_library.nut" import *
let { activeOffersByGoods } = require("%rGui/shop/offerByGoodsState.nut")
let { isFitSeasonRewardsRequirements } = require("%rGui/event/eventState.nut")


let offersByGoodsToShow = Computed(@() !isFitSeasonRewardsRequirements.get() ? []
  : activeOffersByGoods.get().values() ?? [])

return {
  offersByGoodsToShow
}