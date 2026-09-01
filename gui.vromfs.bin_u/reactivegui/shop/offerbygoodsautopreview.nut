from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/profile.nut" import campMyUnits
from "%appGlobals/rewardType.nut" import unitRewardTypes
from "%rGui/event/eventState.nut" import isFitSeasonRewardsRequirements
from "%rGui/shop/offerByGoodsState.nut" import activeOffersByGoods
from "%rGui/shop/shopCommon.nut" import getGoodsType
from "%rGui/shop/shopConst.nut" import SGT_SLOTS, SGT_UNIT, SGT_UNIT_BUNDLE
from "%rGui/shop/shopState.nut" import shopGoods


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