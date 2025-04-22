from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { register_command } = require("console")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isLoggedIn, isReadyToFullLoad } = require("%appGlobals/loginState.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { curCampaign, abTests } = require("%appGlobals/pServer/campaign.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { hasAddons } = require("%appGlobals/updater/addonsState.nut")
let { shopSeenGoods, goodsByCategory, isUnseenGoods } = require("%rGui/shop/shopState.nut")
let { SC_FEATURED, SGT_SLOTS, SGT_UNIT, SGT_LOOTBOX } = require("%rGui/shop/shopConst.nut")
let { actualSchRewards } = require("%rGui/shop/schRewardsState.nut")
let { openGoodsPreviewInMenuOnly, getAddonsToShowGoods } = require("%rGui/shop/goodsPreviewState.nut")
let { isInMenuNoModals } = require("%rGui/mainMenu/mainMenuState.nut")
let { registerAutoDownloadAddons } = require("%rGui/updater/updaterState.nut")
let { onlineBattlesCountForSession } = require("%rGui/onlineBattleCountState.nut")


let goodsTypes = {
  [SGT_SLOTS] = true,
  [SGT_UNIT] = true,
  [SGT_LOOTBOX] = true
}

let lastOpenedGoodsCount = hardPersistWatched("goodsAutoPreview.lastOpenedGoodsCount", {})
let isDebugMode = hardPersistWatched("goodsAutoPreview.isDebugMode", false)

let hasAutoPreviewBase = Computed(@() (abTests.get()?.autoPreviewFeatured ?? "false") == "true")
let hasAutoPreview = Computed(@() hasAutoPreviewBase.get() != isDebugMode.get())

let goodsToOpen = Computed(@() !hasAutoPreview.get() ? null
  : goodsByCategory.get()?[SC_FEATURED].findvalue(
      @(v) goodsTypes?[v?.gtype] && isUnseenGoods(v.id, shopSeenGoods.get(), actualSchRewards.get())))
let onlineBattlesCount = Computed(@() !hasAutoPreview.get() ? 0
  : (onlineBattlesCountForSession.get()?[curCampaign.get()] ?? 0))

let reqAddonsToShowGoods = Computed(@() !isReadyToFullLoad.get() || goodsToOpen.get() == null ? []
  : getAddonsToShowGoods(goodsToOpen.get(), serverConfigs.get()?.allUnits, hasAddons.get()))

let canShow = Computed(@() !isInBattle.get()
  && isInMenuNoModals.get()
  && goodsToOpen.get() != null)
let needShow = keepref(Computed(@() canShow.get()
  && reqAddonsToShowGoods.get().len() == 0
  && (onlineBattlesCount.get() % 2) == 1
  && (lastOpenedGoodsCount.get()?[curCampaign.get()] ?? 0) != onlineBattlesCount.get()))

function openGoodsPreview() {
  if (!needShow.get())
    return
  let hasOpened = openGoodsPreviewInMenuOnly(goodsToOpen.get().id)
  if (!hasOpened)
    return
  lastOpenedGoodsCount.set(lastOpenedGoodsCount.get().__merge({
    [curCampaign.get()] = onlineBattlesCount.get()
  }))
}

let openGoodsPreviewDelayed = @() resetTimeout(0.3, openGoodsPreview)
openGoodsPreviewDelayed()
needShow.subscribe(@(need) need ? openGoodsPreviewDelayed() : null)

isLoggedIn.subscribe(@(v) !v ? lastOpenedGoodsCount.set({}) : null)

registerAutoDownloadAddons(reqAddonsToShowGoods)

register_command(
  function() {
    isDebugMode.set(!isDebugMode.get())
    console_print($"hasAutoPreview = {hasAutoPreview.get()}") 
  },
  "debug.toggleAbTest.autoPreviewFeatured")
