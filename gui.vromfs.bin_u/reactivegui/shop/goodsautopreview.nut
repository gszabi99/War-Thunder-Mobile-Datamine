from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/profile.nut" import campMyUnits
from "%appGlobals/rewardType.nut" import unitRewardTypes
from "%rGui/event/eventState.nut" import isFitSeasonRewardsRequirements
from "%rGui/shop/goodsPreviewState.nut" import getPreviewType
from "%rGui/shop/schRewardsState.nut" import actualSchRewards
from "%rGui/shop/shopCommon.nut" import getGoodsType
from "%rGui/shop/shopConst.nut" import SC_FEATURED, SGT_SLOTS, SGT_UNIT, SGT_LOOTBOX, SGT_UNIT_BUNDLE
from "%rGui/shop/shopState.nut" import shopSeenGoods, goodsByCategory, isUnseenGoods


let goodsCategories = [SC_FEATURED]
let orderByGoodType = [SGT_UNIT_BUNDLE, SGT_UNIT, SGT_LOOTBOX, SGT_SLOTS]
  .reduce(@(res, v, i) res.$rawset(v, i + 1), {})

let featureGoodsToShow = Computed(@() !isFitSeasonRewardsRequirements.get() ? []
  : goodsCategories
      .reduce(function(res, cat) {
          foreach (g in (goodsByCategory.get()?[cat] ?? [])) {
            if (getGoodsType(g) not in orderByGoodType
                || !isUnseenGoods(g.id, shopSeenGoods.get(), actualSchRewards.get())
                || g?.meta.autoPreviewAsOffer == "true"
                || getPreviewType(g) == null)
              continue
            local withUnits = false
            local hasNotReceived = false
            foreach (r in g.rewards)
              if (r.gType in unitRewardTypes) {
                withUnits = true
                hasNotReceived = hasNotReceived || r.id not in campMyUnits.get()
              }
            if (!withUnits || hasNotReceived)
              res.append(g)
          }
          return res
        }, [])
      .sort(@(a, b) (orderByGoodType?[getGoodsType(a)] ?? -1) <=> (orderByGoodType?[getGoodsType(b)] ?? -1)))

return {
  featureGoodsToShow
}