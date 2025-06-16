from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { abTests } = require("%appGlobals/pServer/campaign.nut")
let { shopSeenGoods, goodsByCategory, isUnseenGoods } = require("%rGui/shop/shopState.nut")
let { SC_FEATURED, SGT_SLOTS, SGT_UNIT, SGT_LOOTBOX } = require("%rGui/shop/shopConst.nut")
let { actualSchRewards } = require("%rGui/shop/schRewardsState.nut")


let goodsTypes = {
  [SGT_SLOTS] = true,
  [SGT_UNIT] = true,
  [SGT_LOOTBOX] = true
}

let isDebugMode = hardPersistWatched("goodsAutoPreview.isDebugMode", false)

let hasAutoPreviewBase = Computed(@() (abTests.get()?.autoPreviewFeatured ?? "false") == "true")
let hasAutoPreview = Computed(@() hasAutoPreviewBase.get() != isDebugMode.get())

let featureGoodsToShow = Computed(@() !hasAutoPreview.get() ? []
  : goodsByCategory.get()?[SC_FEATURED].filter(
      @(v) goodsTypes?[v?.gtype] && isUnseenGoods(v.id, shopSeenGoods.get(), actualSchRewards.get())) ?? [])

register_command(
  function() {
    isDebugMode.set(!isDebugMode.get())
    console_print($"hasAutoPreview = {hasAutoPreview.get()}") 
  },
  "debug.toggleAbTest.autoPreviewFeatured")

return {
  featureGoodsToShow
}