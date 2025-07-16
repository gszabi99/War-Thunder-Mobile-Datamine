from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { abTests } = require("%appGlobals/pServer/campaign.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { shopSeenGoods, goodsByCategory, isUnseenGoods } = require("%rGui/shop/shopState.nut")
let { SC_FEATURED, SGT_SLOTS, SGT_UNIT, SGT_LOOTBOX, SC_EVENTS } = require("%rGui/shop/shopConst.nut")
let { actualSchRewards } = require("%rGui/shop/schRewardsState.nut")
let { getPreviewType } = require("%rGui/shop/goodsPreviewState.nut")
let { getBestUnitByGoods } = require("%rGui/shop/goodsUtils.nut")


let goodsCategories = [SC_FEATURED, SC_EVENTS]
let goodsTypes = {
  [SGT_SLOTS] = true,
  [SGT_UNIT] = true,
  [SGT_LOOTBOX] = true
}

let isDebugMode = hardPersistWatched("goodsAutoPreview.isDebugMode", false)

let hasAutoPreviewBase = Computed(@() (abTests.get()?.autoPreviewFeaturedV2 ?? "false") == "true")
let hasAutoPreview = Computed(@() hasAutoPreviewBase.get() != isDebugMode.get())

let featureGoodsToShow = Computed(@() !hasAutoPreview.get() ? []
  : goodsCategories.reduce(function(res, cat) {
      foreach (g in (goodsByCategory.get()?[cat] ?? []))
        if (goodsTypes?[g?.gtype]
            && isUnseenGoods(g.id, shopSeenGoods.get(), actualSchRewards.get())
            && getPreviewType(g, getBestUnitByGoods(g, serverConfigs.get())) != null)
          res.append(g)
      return res
    }, []))

register_command(
  function() {
    isDebugMode.set(!isDebugMode.get())
    console_print($"hasAutoPreview = {hasAutoPreview.get()}") 
  },
  "debug.toggleAbTest.autoPreviewFeatured")

return {
  featureGoodsToShow
}