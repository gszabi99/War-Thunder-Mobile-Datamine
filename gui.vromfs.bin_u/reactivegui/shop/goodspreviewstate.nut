from "%globalsDarg/darg_library.nut" import *
let { eventbus_subscribe } = require("eventbus")
let { defer } = require("dagor.workcycle")
let { has_missing_resources_for_units } = require("contentUpdater")
let { activeOffer } = require("offerState.nut")
let { activeOffersByGoods } = require("offerByGoodsState.nut")
let { shopGoodsAllCampaigns, saveSeenGoods } = require("shopState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { shopPurchaseInProgress, validate_active_offer } = require("%appGlobals/pServer/pServerApi.nut")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let { platformPurchaseInProgress } = require("platformGoods.nut")
let { openDownloadUnitsWnd } = require("%rGui/updater/updaterState.nut")
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
let closeGoodsPreview = @() openedGoodsId(null)
let openPreviewCount = Watched(openedGoodsId.get() == null ? 0 : 1)
let openedSubsId = mkWatched(persist, "openedSubsId", null)


function addTagsUnitsWithPlatoon(res, unitName, sConfigs) {
  res[getTagsUnitName(unitName)] <- true
  let { platoonUnits = [] } = sConfigs?.allUnits[unitName]
  foreach (p in platoonUnits)
    res[getTagsUnitName(p.name)] <- true
}

function getAllTagsUnitsToShowGoods(goods, sConfigs) {
  let res = {}
  foreach (u in goods?.unitUpgrades ?? [])
    addTagsUnitsWithPlatoon(res, u, sConfigs)
  foreach (u in goods?.units ?? [])
    addTagsUnitsWithPlatoon(res, u, sConfigs)
  foreach (u, _ in goods?.blueprints ?? {})
    addTagsUnitsWithPlatoon(res, u, sConfigs)
  if (goods?.meta.previewUnit != null)
    addTagsUnitsWithPlatoon(res, goods.meta.previewUnit, sConfigs)
  return res
}

let getPreviewGoods = @(id, activeOff, activeOffsByGoods, shopGoods)
  activeOff?.id == id ? activeOff
    : id in activeOffsByGoods ? activeOffsByGoods[id]
    : shopGoods?[id]

function openGoodsPreview(id) {
  let goods = getPreviewGoods(id, activeOffer.get(), activeOffersByGoods.get(), shopGoodsAllCampaigns.get())
  if (goods == null)
    return

  let reqUnits = getAllTagsUnitsToShowGoods(goods, serverConfigs.get())
  if (reqUnits.len() != 0 && has_missing_resources_for_units(reqUnits.keys(), true)) {
    openDownloadUnitsWnd(reqUnits.keys(), "openGoodsPreview", { paramStr1 = id }, "openGoodsPreview", { id })
    return
  }

  openedGoodsId(id)
  openPreviewCount(openPreviewCount.value + 1)
  saveSeenGoods([id])
}

function openGoodsPreviewInMenuOnly(id) {
  let goods = getPreviewGoods(id, activeOffer.get(), activeOffersByGoods.get(), shopGoodsAllCampaigns.get())
  if (goods == null)
    return

  let reqUnits = getAllTagsUnitsToShowGoods(goods, serverConfigs.get())
  if (reqUnits.len() != 0 && has_missing_resources_for_units(reqUnits.keys(), true)) {
    openDownloadUnitsWnd(reqUnits.keys(), "openGoodsPreview", { paramStr1 = id }, "openGoodsPreviewInMenuNoModals", { id })
    return false
  }

  if (!isInMenuNoModals.get())
    return false

  openedGoodsId(id)
  openPreviewCount(openPreviewCount.value + 1)
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
    defer(closeGoodsPreview)
})

eventbus_subscribe("openGoodsPreview", @(msg) openGoodsPreview(msg.id))
eventbus_subscribe("openGoodsPreviewInMenuNoModals", @(msg) openGoodsPreviewInMenuOnly(msg.id))

let offerUnitName = keepref(Computed(@() activeOffer.value?.id == openedGoodsId.value ? previewGoodsUnit.value?.name
  : previewGoods.get()?.skins.keys()[0]))
local offerPrevUnitName = offerUnitName.value
offerUnitName.subscribe(function(v) {
  if (offerPrevUnitName != null && (v != null || activeOffer.value?.id == openedGoodsId.value))
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
  getAllTagsUnitsToShowGoods
  getPreviewType

  openSubsPreview = @(id) openedSubsId.set(id)
  closeSubsPreview = @() openedSubsId.set(null)
  openedSubsId
}