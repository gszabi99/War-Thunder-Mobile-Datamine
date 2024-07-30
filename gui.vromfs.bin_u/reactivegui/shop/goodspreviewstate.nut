from "%globalsDarg/darg_library.nut" import *

let { eventbus_subscribe } = require("eventbus")
let { defer } = require("dagor.workcycle")
let { activeOffer } = require("offerState.nut")
let { activeOfferByGoods } = require("offerByGoodsState.nut")
let { shopGoods } = require("shopState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { shopPurchaseInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { platformPurchaseInProgress } = require("platformGoods.nut")
let { openDownloadAddonsWnd } = require("%rGui/updater/updaterState.nut")
let { getUnitPkgs } = require("%appGlobals/updater/campaignAddons.nut")
let { allFakeGoods } = require("%rGui/shop/fakeGoodsState.nut")
let hasAddons = require("%appGlobals/updater/hasAddons.nut")

let GPT_UNIT = "unit"
let GPT_CURRENCY = "currency"
let GPT_PREMIUM = "premium"
let GPT_LOOTBOX = "lootbox"
let GPT_SLOTS = "slots"

let openedGoodsId = mkWatched(persist, "openedGoodsId", null)
let closeGoodsPreview = @() openedGoodsId(null)
let openPreviewCount = Watched(openedGoodsId.get() == null ? 0 : 1)

function getAddonsToShowGoods(goods) {
  let unit = serverConfigs.get()?.allUnits[goods?.unitUpgrades[0] ?? goods?.units[0] ?? goods?.meta.previewUnit]
  if (unit == null)
    return []
  return getUnitPkgs(unit.name, unit.mRank).filter(@(a) !hasAddons.value?[a])
}

function openGoodsPreview(id) {
  let addons = getAddonsToShowGoods(shopGoods.value?[id])
  if (addons.len() != 0) {
    openDownloadAddonsWnd(addons, "openGoodsPreview", { id })
    return
  }

  openedGoodsId(id)
  openPreviewCount(openPreviewCount.value + 1)
}

let previewGoods = Computed(@()
  activeOffer.get()?.id == openedGoodsId.value ? activeOffer.get()
    : activeOfferByGoods.get()?.id == openedGoodsId.value ? activeOfferByGoods.get()
    : shopGoods.get()?[openedGoodsId.get()] ?? allFakeGoods.get()?[openedGoodsId.get()])

let previewGoodsUnit = Computed(function() {
  let unit = serverConfigs.value?.allUnits[previewGoods.value?.unitUpgrades[0]]
  if (unit != null) {
    let { upgradeUnitBonus = {} } = serverConfigs.value?.gameProfile
    return unit.__merge({ isUpgraded = true }, upgradeUnitBonus)
  }

  return serverConfigs.get()?.allUnits[previewGoods.get()?.units[0] ?? previewGoods.get()?.meta.previewUnit]
})

let previewType = Computed(@() (previewGoods.get()?.slotsPreset ?? "") != "" ? GPT_SLOTS
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

let offerUnitName = keepref(Computed(@() activeOffer.value?.id == openedGoodsId.value ? previewGoodsUnit.value?.name
  : null))
local offerPrevUnitName = offerUnitName.value
offerUnitName.subscribe(function(v) {
  if (offerPrevUnitName != null && (v != null || activeOffer.value?.id == openedGoodsId.value))
    defer(closeGoodsPreview)
  offerPrevUnitName = v
})

return {
  GPT_UNIT
  GPT_CURRENCY
  GPT_PREMIUM
  GPT_LOOTBOX
  GPT_SLOTS

  openGoodsPreview
  closeGoodsPreview
  openPreviewCount

  previewGoods
  previewGoodsUnit
  previewType
  isPreviewGoodsPurchasing
}