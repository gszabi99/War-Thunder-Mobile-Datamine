from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "dagor.random" import rnd_int
from "dagor.workcycle" import resetTimeout, deferOnce
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/underscore.nut" import prevIfEqual
from "%appGlobals/clientState/clientState.nut" import isInBattle
from "%appGlobals/loginState.nut" import isReadyToFullLoad, isLoggedIn
from "%appGlobals/pServer/bqClient.nut" import sendOfferBqEvent
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/updater/addonsState.nut" import unitSizes
from "%rGui/mainMenu/mainMenuState.nut" import isInMenuNoModals
from "%rGui/shop/goodsAutoPreview.nut" import featureGoodsToShow
from "%rGui/shop/goodsPreviewState.nut" import openGoodsPreviewInMenuOnly, getAllTagsUnitsToShowGoods,
  getNotLoadedTagsUnitsToShowGoods
from "%rGui/shop/offerAutoPreview.nut" import offerToShow, offerShowedTime
from "%rGui/shop/offerByGoodsAutoPreview.nut" import offersByGoodsToShow
from "%rGui/shop/schRewardsState.nut" import actualSchRewards
from "%rGui/shop/shopState.nut" import shopSeenGoods, isUnseenGoods
from "%rGui/unlocks/loginAwardState.nut" import hasLoginReward
from "%rGui/unlocks/userstat.nut" import isUserstatMissingData
from "%rGui/updater/updaterState.nut" import registerAutoDownloadUnits


let isDebugMode = hardPersistWatched("autoPreviewQueue.isDebugMode", true)

let goodsToShowInfo = hardPersistWatched("autoPreviewQueue.goodsToShowCfgIdx", null)
let goodsToShow = hardPersistWatched("autoPreviewQueue.goodsToShow", null)
let goodsToDownload = hardPersistWatched("autoPreviewQueue.goodsToDownload", null)

let hasSeenBetweenBattlesByCamp = hardPersistWatched("autoPreviewQueue.hasSeenBetweenBattles", {})
let seenInLoop = hardPersistWatched("autoPreviewQueue.seenInLoop", {})

let hasSeenBetweenBattles = Computed(@() hasSeenBetweenBattlesByCamp.get()?[curCampaign.get()])

let canShowScene = Computed(@() isDebugMode.get()
  && !hasSeenBetweenBattles.get()
  && !isInBattle.get()
  && isInMenuNoModals.get()
  && !hasLoginReward.get()
  && !isUserstatMissingData.get())
let needShow = Computed(@() canShowScene.get() && goodsToShow.get() != null)

let isAllUnitsLoaded = @(goods, uSizes)
  null == getAllTagsUnitsToShowGoods(goods).findvalue(@(_, u) (uSizes?[u] ?? -1) != 0)

let isReadyToShowScene = @(v, seen, uSizes) !seen?[v?.id] && isAllUnitsLoaded(v, uSizes)

let findUnseenGoods = @(allSelectedGoods, seen, schRew) allSelectedGoods.findvalue(@(v) isUnseenGoods(v.id, seen, schRew))

let previewCfg = [
  {
    priority = Computed(@() !isReadyToFullLoad.get() ? -1
      : offersByGoodsToShow.get().len() == 0 ? -1
      : null == findUnseenGoods(offersByGoodsToShow.get(), shopSeenGoods.get(), actualSchRewards.get()) ? 1
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
        isReadyToShowScene(v, seenInLoop.get(), unitSizes.get()))
      let cfgGoods = !cfg?.findByShopSeen ? readyToShowGoods.findvalue(@(_) true)
        : findUnseenGoods(readyToShowGoods, shopSeenGoods.get(), actualSchRewards.get())
            ?? readyToShowGoods?[rnd_int(0, readyToShowGoods.len() - 1)]
      if (cfgGoods != null) {
        previewPriority = cfgPriority
        previewGoods = cfgGoods
        previewCfgIdx = idx
      }
    }

    if (cfgPriority >= loadPriority) {
      let readyToLoadGoods = cfg.allGoods.get()
        .filter(@(v) !isAllUnitsLoaded(v, unitSizes.get()))
      let cfgGoods = !cfg?.findByShopSeen ? readyToLoadGoods.findvalue(@(_) true)
        : findUnseenGoods(readyToLoadGoods, shopSeenGoods.get(), actualSchRewards.get())
            ?? readyToLoadGoods.findvalue(@(_) true)
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
  let res = getNotLoadedTagsUnitsToShowGoods(goods.get(), unitSizes.get())
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
register_command(@() hasSeenBetweenBattlesByCamp.set({}), "debug.showNextAutopreview")
