from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isReadyToFullLoad, isLoggedIn } = require("%appGlobals/loginState.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { sendOfferBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { hasAddons } = require("%appGlobals/updater/addonsState.nut")
let { onlineBattlesCountForSession } = require("%rGui/onlineBattleCountState.nut")
let { registerAutoDownloadAddons } = require("%rGui/updater/updaterState.nut")
let { isInMenuNoModals } = require("%rGui/mainMenu/mainMenuState.nut")
let { openGoodsPreviewInMenuOnly, getAddonsToShowGoods } = require("%rGui/shop/goodsPreviewState.nut")
let { featureGoodsToShow } = require("goodsAutoPreview.nut")
let { offerToShow, offerShowedTime } = require("offerAutoPreview.nut")
let { offersByGoodsToShow, offersByGoodsShowedState, showInRow } = require("offerByGoodsAutoPreview.nut")


let goodsToShowCfgIdx = Watched(null)
let goodsToShow = Watched(null)
let nextGoodsToShow = Watched(null)
let commonOpenedAtBattleCountByCamp = hardPersistWatched("autoPreviewQueue.commonOpenedAtBattleCountByCamp", {})

let onlineBattlesCount = Computed(@() onlineBattlesCountForSession.get()?[curCampaign.get()] ?? 0)
let notOpenedBattlesCount = Computed(@()
  onlineBattlesCount.get() - (commonOpenedAtBattleCountByCamp.get()?[curCampaign.get()] ?? -1))

let previewCfg = [
  {
    priority = Computed(function() {
      let offersByGoods = offersByGoodsToShow.get()
      let { allUnits = null } = serverConfigs.get()
      return offersByGoods.len() == 0 ? -1
        : !isReadyToFullLoad.get() ? -1
        : (!showInRow.get() && notOpenedBattlesCount.get() < 1) ? -1
        : offersByGoods.findvalue(@(v) getAddonsToShowGoods(v, allUnits, hasAddons.get()).len() == 0) == null ? 2
        : 5
    }),
    getGoods = @() offersByGoodsToShow.get()
  },
  {
    cbOnPreview = @() sendOfferBqEvent("openInfoAutomatically", offerToShow.get().campaign),
    priority = Computed(function() {
      let offer = offerToShow.get()
      let { allUnits = null } = serverConfigs.get()
      return offer == null ? -1
        : !isReadyToFullLoad.get() ? -1
        : (!showInRow.get() && notOpenedBattlesCount.get() < 1) ? -1
        : (offer?.endTime ?? 0) <= (offerShowedTime.get()?[offer?.campaign] ?? 0) ? -1
        : getAddonsToShowGoods(offer, allUnits, hasAddons.get()).len() > 0 ? 1
        : 4
    }),
    getGoods = @() [offerToShow.get()]
  },
  {
    priority = Computed(function() {
      let featureGoods = featureGoodsToShow.get()
      let { allUnits = null } = serverConfigs.get()
      return featureGoods.len() == 0 ? -1
        : !isReadyToFullLoad.get() ? -1
        : (!showInRow.get() && notOpenedBattlesCount.get() < 1) ? -1
        : featureGoods.findvalue(@(v) getAddonsToShowGoods(v, allUnits, hasAddons.get()).len() == 0) == null ? 0
        : 3
    })
    getGoods = @() featureGoodsToShow.get()
  }
]

function findGoods() {
  local priority = -1
  local goods = null
  local cfgIdx = null
  foreach (idx, cfg in previewCfg) {
    let cfgPriority = cfg.priority.get()
    if (cfgPriority == -1 || cfgPriority < priority)
      continue
    let cfdGoods = cfg.getGoods().findvalue(@(_) true)
    if (cfdGoods == null)
      continue
    priority = cfgPriority
    goods = cfdGoods
    cfgIdx = idx
  }
  return { goods, cfgIdx }
}

function findNextGoods() {
  let curGoods = goodsToShow.get()
  if (curGoods == null)
    return null
  local priority = -1
  local nextGoods = null
  foreach (cfg in previewCfg) {
    let cfgPriority = cfg.priority.get()
    if (cfgPriority == -1 || cfgPriority < priority)
      continue
    let cfdGoods = cfg.getGoods().findvalue(@(v) v?.id != curGoods?.id)
    if (cfdGoods == null)
      continue
    priority = cfgPriority
    nextGoods = cfdGoods
  }
  return nextGoods
}

function assignGoodsToShow() {
  let { goods, cfgIdx } = findGoods()
  goodsToShowCfgIdx.set(cfgIdx)
  goodsToShow.set(goods)

  nextGoodsToShow.set(findNextGoods())
}

assignGoodsToShow()
foreach (w in [featureGoodsToShow, offerToShow, offersByGoodsToShow].extend(previewCfg.map(@(v) v.priority)))
  w.subscribe(@(_) assignGoodsToShow())

let reqAddonsToShowGoods = Computed(@() !isReadyToFullLoad.get() || goodsToShow.get() == null ? []
  : getAddonsToShowGoods(goodsToShow.get(), serverConfigs.get()?.allUnits, hasAddons.get()))
let nextAddonsToShowGoods = Computed(@() !isReadyToFullLoad.get() || goodsToShow.get() == null ? []
  : getAddonsToShowGoods(nextGoodsToShow.get(), serverConfigs.get()?.allUnits, hasAddons.get()))

let needShow = Computed(@() goodsToShow.get() != null
  && reqAddonsToShowGoods.get().len() == 0
  && !isInBattle.get()
  && isInMenuNoModals.get())

function openGoodsPreview() {
  if (!needShow.get())
    return
  let hasOpened = openGoodsPreviewInMenuOnly(goodsToShow.get()?.id)
  if (!hasOpened)
    return
  previewCfg?[goodsToShowCfgIdx.get()].cbOnPreview()
  commonOpenedAtBattleCountByCamp.mutate(@(v) v[curCampaign.get()] <- onlineBattlesCount.get())
  assignGoodsToShow()
}

isLoggedIn.subscribe(function(v) {
  if (v)
    return
  commonOpenedAtBattleCountByCamp.set({})
  offerShowedTime.set({})
  offersByGoodsShowedState.set({})
})

let openGoodsPreviewDelayed = @() resetTimeout(0.3, openGoodsPreview)
openGoodsPreviewDelayed()
needShow.subscribe(@(v) v ? openGoodsPreviewDelayed() : null)

registerAutoDownloadAddons(reqAddonsToShowGoods)
registerAutoDownloadAddons(nextAddonsToShowGoods)
