from "%globalsDarg/darg_library.nut" import *
let { subscribe } = require("eventbus")
let { defer } = require("dagor.workcycle")
let { activeOffer } = require("offerState.nut")
let { shopGoods } = require("shopState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { shopPurchaseInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { platformPurchaseInProgress } = require("platformGoods.nut")
let { openDownloadAddonsWnd } = require("%rGui/updater/updaterState.nut")
let { getUnitPkgs } = require("%appGlobals/updater/campaignAddons.nut")
let hasAddons = require("%appGlobals/updater/hasAddons.nut")

let GPT_UNIT = "unit"
let GPT_CURRENCY = "currency"
let GPT_PREMIUM = "premium"

let openedGoodsId = mkWatched(persist, "openedGoodsId", null)
let closeGoodsPreview = @() openedGoodsId(null)
let openPreviewCount = Watched(0)

let function getAddonsToShowGoods(goods) {
  let unit = serverConfigs.value?.allUnits[goods?.unitUpgrades[0] ?? goods?.units[0]]
  if (unit == null)
    return []
  return getUnitPkgs(unit.name, unit.mRank).filter(@(a) !hasAddons.value?[a])
}

let function openGoodsPreview(id) {
  let addons = getAddonsToShowGoods(shopGoods.value?[id])
  if (addons.len() != 0) {
    openDownloadAddonsWnd(addons, "openGoodsPreview", { id })
    return
  }

  openedGoodsId(id)
  openPreviewCount(openPreviewCount.value + 1)
}

let previewGoods = Computed(@()
  activeOffer.value?.id == openedGoodsId.value ? activeOffer.value : shopGoods.value?[openedGoodsId.value])

let previewGoodsUnit = Computed(function() {
  let unit = serverConfigs.value?.allUnits[previewGoods.value?.unitUpgrades[0]]
  if (unit != null) {
    let { upgradeUnitBonus = {} } = serverConfigs.value?.gameProfile
    return unit.__merge({ isUpgraded = true }, upgradeUnitBonus)
  }

  return serverConfigs.value?.allUnits[previewGoods.value?.units[0]]
})

let previewType = Computed(@() previewGoodsUnit.value != null ? GPT_UNIT
  : (previewGoods.value?.wp ?? 0) > 0 || (previewGoods.value?.gold ?? 0) > 0 ? GPT_CURRENCY
  : (previewGoods.value?.premiumDays ?? 0) > 0  ? GPT_PREMIUM
  : null)

let isPreviewGoodsPurchasing = Computed(@() previewGoods.value?.id != null
  && (previewGoods.value.id == shopPurchaseInProgress.value
    || previewGoods.value.id == platformPurchaseInProgress.value))

isPreviewGoodsPurchasing.subscribe(@(v) v ? null : closeGoodsPreview())

subscribe("openGoodsPreview", @(msg) openGoodsPreview(msg.id))

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

  openGoodsPreview
  closeGoodsPreview
  openPreviewCount

  previewGoods
  previewGoodsUnit
  previewType
  isPreviewGoodsPurchasing
}