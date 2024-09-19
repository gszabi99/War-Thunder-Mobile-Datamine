from "%globalsDarg/darg_library.nut" import *

let { eventbus_subscribe } = require("eventbus")
let { defer } = require("dagor.workcycle")
let { activeOffer } = require("offerState.nut")
let { activeOfferByGoods } = require("offerByGoodsState.nut")
let { shopGoodsAllCampaigns } = require("shopState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { shopPurchaseInProgress, check_empty_offer, update_branch_offer } = require("%appGlobals/pServer/pServerApi.nut")
let { platformPurchaseInProgress } = require("platformGoods.nut")
let { openDownloadAddonsWnd } = require("%rGui/updater/updaterState.nut")
let { getUnitPkgs } = require("%appGlobals/updater/campaignAddons.nut")
let hasAddons = require("%appGlobals/updater/hasAddons.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { getBestUnitByGoods } = require("%rGui/shop/goodsUtils.nut")
let { isInMenuNoModals } = require("%rGui/mainMenu/mainMenuState.nut")

let GPT_UNIT = "unit"
let GPT_CURRENCY = "currency"
let GPT_PREMIUM = "premium"
let GPT_LOOTBOX = "lootbox"
let GPT_SLOTS = "slots"
let GPT_BLUEPRINT = "blueprint"

let openedUnitFromTree = mkWatched(persist, "openedUnitFromTree", null)
let openedGoodsId = mkWatched(persist, "openedGoodsId", null)
let closeGoodsPreview = @() openedGoodsId(null)
let openPreviewCount = Watched(openedGoodsId.get() == null ? 0 : 1)

let getPkgsByUnit = @(unit) unit == null ? [] : getUnitPkgs(unit.name, unit.mRank)

function getAddonsToShowGoods(goods, allUnits, excludeAddons) {
  let res = {}
  foreach (unitName in goods?.unitUpgrades ?? {})
    foreach (pkg in getPkgsByUnit(allUnits?[unitName]))
      res[pkg] <- true

  foreach (unitName in goods?.units ?? {})
    foreach (pkg in getPkgsByUnit(allUnits?[unitName]))
      res[pkg] <- true

  if (goods?.meta.previewUnit != null)
    foreach (pkg in getPkgsByUnit(allUnits?[goods?.meta.previewUnit]))
      res[pkg] <- true

  return res.keys().filter(@(a) !excludeAddons?[a])
}

let getPreviewGoods = @(id, activeOff, activeOffByGoods, shopGoods)
  activeOff?.id == id ? activeOff
    : activeOffByGoods?.id == id ? activeOffByGoods
    : shopGoods?[id]

function openGoodsPreview(id) {
  let goods = getPreviewGoods(id, activeOffer.get(), activeOfferByGoods.get(), shopGoodsAllCampaigns.get())
  let addons = getAddonsToShowGoods(goods, serverConfigs.get()?.allUnits, hasAddons.get())
  if (addons.len() != 0) {
    openDownloadAddonsWnd(addons, "openGoodsPreview", { id })
    return
  }

  openedGoodsId(id)
  openPreviewCount(openPreviewCount.value + 1)
}

function openGoodsPreviewInMenuOnly(id) {
  let goods = getPreviewGoods(id, activeOffer.get(), activeOfferByGoods.get(), shopGoodsAllCampaigns.get())
  let addons = getAddonsToShowGoods(goods, serverConfigs.get()?.allUnits, hasAddons.get())
  if (addons.len() != 0) {
    openDownloadAddonsWnd(addons, "openGoodsPreviewInMenuNoModals", { id })
    return
  }

  if (!isInMenuNoModals.get())
    return

  openedGoodsId(id)
  openPreviewCount(openPreviewCount.value + 1)
}

let previewGoods = Computed(@() getPreviewGoods(openedGoodsId.get(), activeOffer.get(),
  activeOfferByGoods.get(), shopGoodsAllCampaigns.get()))

let previewGoodsUnit = Computed(@() getBestUnitByGoods(previewGoods.get(), serverConfigs.get()))

let previewType = Computed(@() (previewGoods.get()?.slotsPreset ?? "") != "" ? GPT_SLOTS
  : (previewGoods.get()?.blueprints.len() ?? 0) > 0 ? GPT_BLUEPRINT
  : previewGoodsUnit.value != null ? GPT_UNIT
  : (previewGoods.get()?.lootboxes.len() ?? 0) > 0 ? GPT_LOOTBOX
  : (previewGoods.get()?.currencies.len() ?? 0) > 0 ? GPT_CURRENCY
  : (previewGoods.get()?.premiumDays ?? 0) > 0  ? GPT_PREMIUM
  : null)

let isPreviewGoodsPurchasing = Computed(@() previewGoods.value?.id != null
  && (previewGoods.value.id == shopPurchaseInProgress.value
    || previewGoods.value.id == platformPurchaseInProgress.value))

isPreviewGoodsPurchasing.subscribe(function(v) {
  if (v || previewGoods.get() == null)
    return
  let { id, limit = 0, dailyLimit = 0, oncePerSeason = "", slotsPreset = "" } = previewGoods.get()
  if (slotsPreset != "")
    return
  if (previewGoodsUnit.get() != null || activeOffer.get()?.id == id || limit > 0 || dailyLimit > 0 || oncePerSeason != "")
    closeGoodsPreview()
})

eventbus_subscribe("openGoodsPreview", @(msg) openGoodsPreview(msg.id))
eventbus_subscribe("openGoodsPreviewInMenuNoModals", @(msg) openGoodsPreviewInMenuOnly(msg.id))

let offerUnitName = keepref(Computed(@() activeOffer.value?.id == openedGoodsId.value ? previewGoodsUnit.value?.name
  : null))
local offerPrevUnitName = offerUnitName.value
offerUnitName.subscribe(function(v) {
  if (offerPrevUnitName != null && (v != null || activeOffer.value?.id == openedGoodsId.value))
    defer(closeGoodsPreview)
  offerPrevUnitName = v
})

servProfile.subscribe(function(v){
  let offersBlueprint = activeOffer.get()?.blueprints.findindex(@(_) true)
  if(!offersBlueprint)
    return
  if (offersBlueprint in myUnits.get()
      || v?.blueprints[offersBlueprint] == serverConfigs.get()?.allBlueprints?[offersBlueprint].targetCount)
    check_empty_offer(curCampaign.get())
})

myUnits.subscribe(function(list){
  if ((activeOffer.get()?.id ?? "") == "branch_offer")
    foreach (unitName in activeOffer.get().units)
      if (unitName in list) {
        update_branch_offer(curCampaign.get())
        break
      }
})

return {
  GPT_UNIT
  GPT_CURRENCY
  GPT_PREMIUM
  GPT_LOOTBOX
  GPT_SLOTS
  GPT_BLUEPRINT

  openGoodsPreview
  closeGoodsPreview
  openPreviewCount

  openedUnitFromTree
  openedGoodsId
  previewGoods
  previewGoodsUnit
  previewType
  isPreviewGoodsPurchasing
  openGoodsPreviewInMenuOnly
}