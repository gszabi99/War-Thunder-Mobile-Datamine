from "%globalsDarg/darg_library.nut" import *
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { shopSeenGoods, goodsByCategory, isUnseenGoods } = require("%rGui/shop/shopState.nut")
let { SC_FEATURED, SGT_SLOTS, SGT_UNIT, SGT_LOOTBOX, SC_EVENTS } = require("%rGui/shop/shopConst.nut")
let { actualSchRewards } = require("%rGui/shop/schRewardsState.nut")
let { getPreviewType } = require("%rGui/shop/goodsPreviewState.nut")
let { getBestUnitByGoods } = require("%rGui/shop/goodsUtils.nut")
let { isFitSeasonRewardsRequirements } = require("%rGui/event/eventState.nut")


let goodsCategories = [SC_FEATURED, SC_EVENTS]
let goodsTypeOrder = [SGT_UNIT, SGT_LOOTBOX, SGT_SLOTS]
let orderByGoodType = goodsTypeOrder.reduce(@(res, v, i) res.$rawset(v, i + 1), {})

let featureGoodsToShow = Computed(@() !isFitSeasonRewardsRequirements.get() ? []
  : goodsCategories
      .reduce(function(res, cat) {
          foreach (g in (goodsByCategory.get()?[cat] ?? []))
            if (null == (g?.units ?? []).findvalue(@(u) u in campMyUnits.get())
                && null == (g?.unitUpgrades ?? []).findvalue(@(u) u in campMyUnits.get())
                && g?.gtype in orderByGoodType
                && isUnseenGoods(g.id, shopSeenGoods.get(), actualSchRewards.get())
                && getPreviewType(g, getBestUnitByGoods(g, serverConfigs.get())) != null)
              res.append(g)
          return res
        }, [])
      .sort(@(a, b) (orderByGoodType?[a] ?? -1) <=> (orderByGoodType?[b] ?? -1)))

return {
  featureGoodsToShow
}