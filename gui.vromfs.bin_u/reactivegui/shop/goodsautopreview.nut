from "%globalsDarg/darg_library.nut" import *
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { unitRewardTypes } = require("%appGlobals/rewardType.nut")
let { shopSeenGoods, goodsByCategory, isUnseenGoods } = require("%rGui/shop/shopState.nut")
let { SC_FEATURED, SGT_SLOTS, SGT_UNIT, SGT_LOOTBOX, SC_EVENTS } = require("%rGui/shop/shopConst.nut")
let { actualSchRewards } = require("%rGui/shop/schRewardsState.nut")
let { getPreviewType } = require("%rGui/shop/goodsPreviewState.nut")
let { getBestUnitByGoods } = require("%rGui/shop/goodsUtils.nut")
let { isFitSeasonRewardsRequirements } = require("%rGui/event/eventState.nut")


let goodsCategories = [SC_FEATURED, SC_EVENTS]
let orderByGoodType = [SGT_UNIT, SGT_LOOTBOX, SGT_SLOTS]
  .reduce(@(res, v, i) res.$rawset(v, i + 1), {})

let featureGoodsToShow = Computed(@() !isFitSeasonRewardsRequirements.get() ? []
  : goodsCategories
      .reduce(function(res, cat) {
          foreach (g in (goodsByCategory.get()?[cat] ?? [])) {
            if (g?.gtype not in orderByGoodType
                || !isUnseenGoods(g.id, shopSeenGoods.get(), actualSchRewards.get())
                || getPreviewType(g, getBestUnitByGoods(g, serverConfigs.get())) == null)
              continue
            let { rewards = [], units = [], unitUpgrades = [] } = g
            if (null != rewards.findvalue(@(r) r.id in campMyUnits.get() && r.gType in unitRewardTypes))
              continue
            if (null != units.findvalue(@(u) u in campMyUnits.get()) 
                && null != unitUpgrades.findvalue(@(u) u in campMyUnits.get()))
              continue

            res.append(g)
          }
          return res
        }, [])
      .sort(@(a, b) (orderByGoodType?[a?.gtype] ?? -1) <=> (orderByGoodType?[b?.gtype] ?? -1)))

return {
  featureGoodsToShow
}