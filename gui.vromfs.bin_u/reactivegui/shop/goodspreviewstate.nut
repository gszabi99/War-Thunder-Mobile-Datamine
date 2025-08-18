from "%globalsDarg/darg_library.nut" import *

let { eventbus_subscribe } = require("eventbus")
let { defer } = require("dagor.workcycle")
let { activeOffer } = require("%rGui/shop/offerState.nut")
let { activeOffersByGoods } = require("%rGui/shop/offerByGoodsState.nut")
let { shopGoodsAllCampaigns, saveSeenGoods } = require("%rGui/shop/shopState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { shopPurchaseInProgress, validate_active_offer } = require("%appGlobals/pServer/pServerApi.nut")
let { platformPurchaseInProgress } = require("%rGui/shop/platformGoods.nut")
let { openDownloadAddonsWnd } = require("%rGui/updater/updaterState.nut")
let { getUnitPkgs } = require("%appGlobals/updater/campaignAddons.nut")
let { hasAddons } = require("%appGlobals/updater/addonsState.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { getBestUnitByGoods } = require("%rGui/shop/goodsUtils.nut")
let { isInMenuNoModals } = require("%rGui/mainMenu/mainMenuState.nut")

let GPT_UNIT = "unit"
let GPT_CURRENCY = "currency"
let GPT_PREMIUM = "premium"
let GPT_LOOTBOX = "lootbox"
let GPT_SLOTS = "slots"
let GPT_BLUEPRINT = "blueprint"
let GPT_SKIN = "skin"

let HIDE_PREVIEW_MODALS_ID = "goodsPreviewAnim"

let openedUnitFromTree = mkWatched(persist, "openedUnitFromTree", null)
let openedGoodsId = mkWatched(persist, "openedGoodsId", null)
let closeGoodsPreview = @() openedGoodsId.set(null)
let openPreviewCount = Watched(openedGoodsId.get() == null ? 0 : 1)
let openedSubsId = mkWatched(persist, "openedSubsId", null)


function tryAddPkgs(res, unit) {
  if (unit != null)
    foreach (pkg in getUnitPkgs(unit.name, unit.mRank))
      res[pkg] <- true
}

function getAddonsToShowGoods(goods, allUnits, excludeAddons) {
  let res = {}
  foreach (unitName in goods?.unitUpgrades ?? [])
    tryAddPkgs(res, allUnits?[unitName])

  foreach (unitName in goods?.units ?? [])
    tryAddPkgs(res, allUnits?[unitName])

  foreach (unitName, _ in goods?.blueprints ?? {})
    tryAddPkgs(res, allUnits?[unitName])

  if (goods?.meta.previewUnit != null)
    tryAddPkgs(res, allUnits?[goods?.meta.previewUnit])

  return res.keys().filter(@(a) !excludeAddons?[a])
}

let getPreviewGoods = @(id, activeOff, activeOffsByGoods, shopGoods)
  activeOff?.id == id ? activeOff
    : id in activeOffsByGoods ? activeOffsByGoods[id]
    : shopGoods?[id]

function openGoodsPreview(id) {
  let goods = getPreviewGoods(id, activeOffer.get(), activeOffersByGoods.get(), shopGoodsAllCampaigns.get())
  let addons = getAddonsToShowGoods(goods, serverConfigs.get()?.allUnits, hasAddons.get())
  if (addons.len() != 0) {
    openDownloadAddonsWnd(addons, "openGoodsPreview", { paramStr1 = id }, "openGoodsPreview", { id })
    return
  }

  openedGoodsId.set(id)
  openPreviewCount.set(openPreviewCount.get() + 1)
  saveSeenGoods([id])
}

function openGoodsPreviewInMenuOnly(id) {
  let goods = getPreviewGoods(id, activeOffer.get(), activeOffersByGoods.get(), shopGoodsAllCampaigns.get())
  let addons = getAddonsToShowGoods(goods, serverConfigs.get()?.allUnits, hasAddons.get())
  if (addons.len() != 0) {
    openDownloadAddonsWnd(addons, "openGoodsPreview", { paramStr1 = id }, "openGoodsPreviewInMenuNoModals", { id })
    return false
  }

  if (!isInMenuNoModals.get())
    return false

  openedGoodsId.set(id)
  openPreviewCount.set(openPreviewCount.get() + 1)
  saveSeenGoods([id])
  return true
}

let previewGoods = Computed(@() getPreviewGoods(openedGoodsId.get(), activeOffer.get(),
  activeOffersByGoods.get(), shopGoodsAllCampaigns.get()))

let previewGoodsUnit = Computed(@() getBestUnitByGoods(previewGoods.get(), serverConfigs.get()))

let getPreviewType = @(goods, goodsUnit) (goods?.slotsPreset ?? "") != "" ? GPT_SLOTS
  : (goods?.blueprints.len() ?? 0) > 0 ? GPT_BLUEPRINT
  : goodsUnit != null ? GPT_UNIT
  : (goods?.skins.len() ?? 0) > 0  ? GPT_SKIN
  : (goods?.lootboxes.len() ?? 0) > 0 ? GPT_LOOTBOX
  : (goods?.currencies.len() ?? 0) > 0 ? GPT_CURRENCY
  : (goods?.premiumDays ?? 0) > 0  ? GPT_PREMIUM
  : null
let previewType = Computed(@() getPreviewType(previewGoods.get(), previewGoodsUnit.get()))

let isPreviewGoodsPurchasing = Computed(@() previewGoods.get()?.id != null
  && (previewGoods.get().id == shopPurchaseInProgress.get()
    || previewGoods.get().id == platformPurchaseInProgress.get()))

isPreviewGoodsPurchasing.subscribe(function(v) {
  if (v || previewGoods.get() == null)
    return
  let { id, limit = 0, dailyLimit = 0, oncePerSeason = "", slotsPreset = "" } = previewGoods.get()
  if (slotsPreset != "")
    return
  if (previewGoodsUnit.get() != null || activeOffer.get()?.id == id || limit > 0 || dailyLimit > 0 || oncePerSeason != "")
    defer(closeGoodsPreview)
})

eventbus_subscribe("openGoodsPreview", @(msg) openGoodsPreview(msg.id))
eventbus_subscribe("openGoodsPreviewInMenuNoModals", @(msg) openGoodsPreviewInMenuOnly(msg.id))

let offerUnitName = keepref(Computed(@() activeOffer.get()?.id == openedGoodsId.get() ? previewGoodsUnit.get()?.name
  : previewGoods.get()?.skins.keys()[0]))
local offerPrevUnitName = offerUnitName.value
offerUnitName.subscribe(function(v) {
  if (offerPrevUnitName != null && (v != null || activeOffer.get()?.id == openedGoodsId.get()))
    defer(closeGoodsPreview)
  offerPrevUnitName = v
})

servProfile.subscribe(function(servProfileV){
  if (activeOffer.get() == null)
    return

  let { blueprints = {}, unitUpgrades = [], units = [] } = activeOffer.get()

  foreach (unitName, count in blueprints)
    if (unitName in campMyUnits.get()
      || (servProfileV?.blueprints[unitName] ?? 0) + count > (serverConfigs.get()?.allBlueprints?[unitName].targetCount ?? 0))
      return validate_active_offer(curCampaign.get())

  foreach (unitName in unitUpgrades)
    if (campMyUnits.get()?[unitName].isUpgraded)
      return validate_active_offer(curCampaign.get())

  foreach (unitName in units)
    if (unitName in campMyUnits.get()) {
      return validate_active_offer(curCampaign.get())
    }
})

return {
  GPT_UNIT
  GPT_CURRENCY
  GPT_PREMIUM
  GPT_LOOTBOX
  GPT_SLOTS
  GPT_BLUEPRINT
  GPT_SKIN

  HIDE_PREVIEW_MODALS_ID

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
  getAddonsToShowGoods
  getPreviewType

  openSubsPreview = @(id) openedSubsId.set(id)
  closeSubsPreview = @() openedSubsId.set(null)
  openedSubsId
}