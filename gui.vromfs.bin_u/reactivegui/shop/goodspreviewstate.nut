from "%globalsDarg/darg_library.nut" import *

let { eventbus_subscribe } = require("eventbus")
let { defer } = require("dagor.workcycle")
let { activeOffer } = require("offerState.nut")
let { activeOffersByGoods } = require("offerByGoodsState.nut")
let { shopGoodsAllCampaigns, saveSeenGoods, discountsToApply } = require("shopState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { shopPurchaseInProgress, validate_active_offer } = require("%appGlobals/pServer/pServerApi.nut")
let { platformPurchaseInProgress } = require("platformGoods.nut")
let { openDownloadAddonsWnd } = require("%rGui/updater/updaterState.nut")
let { getUnitPkgs } = require("%appGlobals/updater/campaignAddons.nut")
let { hasAddons } = require("%appGlobals/updater/addonsState.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { getBestUnitByGoods } = require("%rGui/shop/goodsUtils.nut")
let { isInMenuNoModals } = require("%rGui/mainMenu/mainMenuState.nut")
let { specialEventsLootboxesState } = require("%rGui/event/eventState.nut")
let { questsBySection } = require("%rGui/quests/questsState.nut")

let GPT_UNIT = "unit"
let GPT_CURRENCY = "currency"
let GPT_PREMIUM = "premium"
let GPT_LOOTBOX = "lootbox"
let GPT_SLOTS = "slots"
let GPT_BLUEPRINT = "blueprint"

let HIDE_PREVIEW_MODALS_ID = "goodsPreviewAnim"

let openedUnitFromTree = mkWatched(persist, "openedUnitFromTree", null)
let openedGoodsId = mkWatched(persist, "openedGoodsId", null)
let closeGoodsPreview = @() openedGoodsId(null)
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

  openedGoodsId(id)
  openPreviewCount(openPreviewCount.value + 1)
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

  openedGoodsId(id)
  openPreviewCount(openPreviewCount.value + 1)
  saveSeenGoods([id])
  return true
}

let previewGoods = Computed(@() getPreviewGoods(openedGoodsId.get(), activeOffer.get(),
  activeOffersByGoods.get(), shopGoodsAllCampaigns.get()))

let userstatRewards = Computed(@() serverConfigs.get()?.userstatRewards)
let personalDiscountsByGoodsId = keepref(Computed(@() serverConfigs.get()?.personalDiscounts[previewGoods.get()?.id]))
let availableDiscounts = Computed(@() personalDiscountsByGoodsId.get()?.filter(@(v)
  v.goodsId not in discountsToApply.get() || v.price < discountsToApply.get()[v.goodsId]))

let availableDiscountRewards = Computed(function() {
  if (availableDiscounts.get() == null || availableDiscounts.get().len() == 0)
    return null

  let res = {}
  foreach (key, rewards in userstatRewards.get())
    if (rewards.findvalue(@(g) g.gType == "discount" && availableDiscounts.get().findindex(@(v) v.id == g.id) != null) != null)
      res[key] <- true

  if (res.len() == 0)
    return null
  return res
})

let eventIdByPersonalDiscount = Computed(function() {
  let { withoutLootboxes = {} } = specialEventsLootboxesState.get()
  let discountRewards = availableDiscountRewards.get()
  local res = null

  if (!discountRewards || withoutLootboxes.len() == 0)
    return res

  foreach (eventName, eventState in withoutLootboxes)
    foreach (quest in questsBySection.get()?[eventName] ?? {}) {
      if (quest?.stages.findindex(@(v) v?.rewards.findindex(@(_, id) id in discountRewards) != null) != null) {
        res = eventState.eventId
        break
      }
    }

  return res
})

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
  eventIdByPersonalDiscount

  openSubsPreview = @(id) openedSubsId.set(id)
  closeSubsPreview = @() openedSubsId.set(null)
  openedSubsId
}