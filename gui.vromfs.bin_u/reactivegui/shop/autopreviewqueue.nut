from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { resetTimeout, deferOnce } = require("dagor.workcycle")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { prevIfEqual } = require("%sqstd/underscore.nut")
let { isReadyToFullLoad, isLoggedIn } = require("%appGlobals/loginState.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { sendOfferBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { unitSizes } = require("%appGlobals/updater/addonsState.nut")
let { registerAutoDownloadUnits } = require("%rGui/updater/updaterState.nut")
let { isInMenuNoModals } = require("%rGui/mainMenu/mainMenuState.nut")
let { openGoodsPreviewInMenuOnly, getAllTagsUnitsToShowGoods, getNotLoadedTagsUnitsToShowGoods
} = require("%rGui/shop/goodsPreviewState.nut")
let { shopSeenGoods, isUnseenGoods } = require("%rGui/shop/shopState.nut")
let { actualSchRewards } = require("%rGui/shop/schRewardsState.nut")
let { featureGoodsToShow } = require("%rGui/shop/goodsAutoPreview.nut")
let { offerToShow, offerShowedTime } = require("%rGui/shop/offerAutoPreview.nut")
let { offersByGoodsToShow, showInRow } = require("%rGui/shop/offerByGoodsAutoPreview.nut")


let isDebugMode = hardPersistWatched("autoPreviewQueue.isDebugMode", true)

let goodsToShowInfo = hardPersistWatched("autoPreviewQueue.goodsToShowCfgIdx", null)
let goodsToShow = hardPersistWatched("autoPreviewQueue.goodsToShow", null)
let goodsToDownload = hardPersistWatched("autoPreviewQueue.goodsToDownload", null)

let hasSeenBetweenBattlesByCamp = hardPersistWatched("autoPreviewQueue.hasSeenBetweenBattles", {})
let seenInLoop = hardPersistWatched("autoPreviewQueue.seenInLoop", {})

let hasSeenBetweenBattles = Computed(@() hasSeenBetweenBattlesByCamp.get()?[curCampaign.get()])

let canShowScene = Computed(@() isDebugMode.get()
  && (showInRow.get() || !hasSeenBetweenBattles.get())
  && !isInBattle.get()
  && isInMenuNoModals.get())
let needShow = Computed(@() canShowScene.get() && goodsToShow.get() != null)

let isAllUnitsLoaded = @(goods, sConfigs, uSizes)
  null == getAllTagsUnitsToShowGoods(goods, sConfigs).findvalue(@(_, u) (uSizes?[u] ?? -1) != 0)

let isReadyToShowScene = @(v, seen, sCfg, uSizes) !seen?[v?.id] && isAllUnitsLoaded(v, sCfg, uSizes)

let previewCfg = [
  {
    priority = Computed(@() !isReadyToFullLoad.get() ? -1
      : offersByGoodsToShow.get().len() == 0 ? -1
      : null == offersByGoodsToShow.get().findvalue(@(v) isUnseenGoods(v.id, shopSeenGoods.get(), actualSchRewards.get())) ? 1
      : 4)
    allGoods = offersByGoodsToShow
    findByShopSeen = true
  },
  {
    priority = Computed(@() !isReadyToFullLoad.get() ? -1
      : offerToShow.get() == null ? -1
      : (offerToShow.get()?.endTime ?? 0) <= (offerShowedTime.get()?[offerToShow.get()?.campaign] ?? 0) ? -1
      : (offerToShow.get()?.hasSeen ?? true) ? 0
      : (offerToShow.get().id != "start_offer") ? 2
      : 5)
    allGoods = Computed(@() [offerToShow.get()].filter(@(v) v != null))
    isOffer = true
  },
  {
    priority = Computed(@() !isReadyToFullLoad.get() || featureGoodsToShow.get().len() == 0 ? -1 : 3)
    allGoods = featureGoodsToShow
  }
]

let findUnseenGoods = @(allSelectedGoods, seen, schRew) allSelectedGoods.findvalue(@(v) isUnseenGoods(v.id, seen, schRew))
  ?? allSelectedGoods.findvalue(@(_) true)

function assignGoods() {
  local previewGoods = null
  local previewPriority = -1
  local previewCfgIdx = null
  local loadGoods = null
  local loadPriority = -1
  foreach (idx, cfg in previewCfg) {
    let cfgPriority = cfg.priority.get()
    if (cfgPriority == -1)
      continue

    if (cfgPriority >= previewPriority) {
      let readyToShowGoods = cfg.allGoods.get().filter(@(v)
        isReadyToShowScene(v, seenInLoop.get(), serverConfigs.get(), unitSizes.get()))
      let cfgGoods = !cfg?.findByShopSeen ? readyToShowGoods.findvalue(@(_) true)
        : findUnseenGoods(readyToShowGoods, shopSeenGoods.get(), actualSchRewards.get())
      if (cfgGoods != null) {
        previewPriority = cfgPriority
        previewGoods = cfgGoods
        previewCfgIdx = idx
      }
    }

    if (cfgPriority >= loadPriority) {
      let readyToLoadGoods = cfg.allGoods.get()
        .filter(@(v) !isAllUnitsLoaded(v, serverConfigs.get(), unitSizes.get()))
      let cfgGoods = !cfg?.findByShopSeen ? readyToLoadGoods.findvalue(@(_) true)
        : findUnseenGoods(readyToLoadGoods, shopSeenGoods.get(), actualSchRewards.get())
      if (cfgGoods != null) {
        loadPriority = cfgPriority
        loadGoods = cfgGoods
      }
    }
  }

  goodsToShowInfo.set({ cfgIdx = previewCfgIdx, priority = previewPriority })
  goodsToShow.set(previewGoods)
  goodsToDownload.set(loadGoods)
}

assignGoods()

foreach (w in [serverConfigs, unitSizes, seenInLoop, shopSeenGoods, actualSchRewards].extend(
  previewCfg.map(@(cfg) cfg.priority), previewCfg.map(@(cfg) cfg.allGoods)
))
  w.subscribe(@(_) deferOnce(assignGoods))

let mkReqUnitsToShowGoods = @(goods) Computed(function(prev) {
  if (!isReadyToFullLoad.get() || goods.get() == null)
    return prevIfEqual(prev, {})
  let res = getNotLoadedTagsUnitsToShowGoods(goods.get(), serverConfigs.get(), unitSizes.get())
  return prevIfEqual(prev, res)
})

let nextUnitsToShowGoods = keepref(mkReqUnitsToShowGoods(goodsToDownload))

function openGoodsPreview() {
  if (!needShow.get())
    return

  let { id = null } = goodsToShow.get()
  if (id == null)
    return

  let hasOpened = openGoodsPreviewInMenuOnly(id)
  if (!hasOpened)
    return

  let { cfgIdx = null } = goodsToShowInfo.get()
  let { isOffer = false } = previewCfg?[cfgIdx]
  if (isOffer)
    sendOfferBqEvent("openInfoAutomatically", goodsToShow.get().campaign)
  else
    seenInLoop.mutate(@(v) v[id] <- true)

  hasSeenBetweenBattlesByCamp.mutate(@(v) v[curCampaign.get()] <- true)
  assignGoods()
}

let openGoodsPreviewDelayed = @() resetTimeout(0.3, openGoodsPreview)
openGoodsPreviewDelayed()
needShow.subscribe(@(v) v ? openGoodsPreviewDelayed() : null)
isInBattle.subscribe(@(v) v ? hasSeenBetweenBattlesByCamp.mutate(@(st) st[curCampaign.get()] <- false) : null)

isLoggedIn.subscribe(function(v) {
  if (v)
    return
  seenInLoop.set({})
  offerShowedTime.set({})
  hasSeenBetweenBattlesByCamp.set({})
})

registerAutoDownloadUnits(nextUnitsToShowGoods)

register_command(
  function() {
    isDebugMode.set(!isDebugMode.get())
    console_print($"hasAutoPreview = {isDebugMode.get()}") 
  },
  "debug.toggleAutoPreview")
register_command(@() seenInLoop.set({}), "debug.reset_auto_preview_seen")
register_command(@() console_print(seenInLoop.get()), "debug.log_auto_preview_seen") 
