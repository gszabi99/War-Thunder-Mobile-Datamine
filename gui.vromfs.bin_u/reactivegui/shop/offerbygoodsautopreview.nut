from "%globalsDarg/darg_library.nut" import *
let { unitRewardTypes } = require("%appGlobals/rewardType.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { getGoodsType } = require("%rGui/shop/shopCommon.nut")
let { SGT_SLOTS, SGT_UNIT, SGT_UNIT_BUNDLE } = require("%rGui/shop/shopConst.nut")
let { shopGoods } = require("%rGui/shop/shopState.nut")
let { activeOffersByGoods } = require("%rGui/shop/offerByGoodsState.nut")
let { isFitSeasonRewardsRequirements } = require("%rGui/event/eventState.nut")


let orderByGoodType = [SGT_UNIT_BUNDLE, SGT_UNIT, SGT_SLOTS].reduce(@(res, v, i) res.$rawset(v, i + 1), {})

let offersByGoodsToShow = Computed(@() !isFitSeasonRewardsRequirements.get() ? []
  : [].extend(
        activeOffersByGoods.get().values(),
        shopGoods.get()
          .filter(function(g) {
            if (g?.meta.autoPreviewAsOffer != "true")
              return false
            local withUnits = false
            local hasNotReceived = false
            foreach (r in g.rewards)
              if (r.gType in unitRewardTypes) {
                withUnits = true
                hasNotReceived = hasNotReceived || r.id not in campMyUnits.get()
              }
            return !withUnits || hasNotReceived
          })
          .values()
      )
      .sort(@(a, b) (orderByGoodType?[getGoodsType(a)] ?? -1) <=> (orderByGoodType?[getGoodsType(b)] ?? -1))
)

return {
  offersByGoodsToShow
}