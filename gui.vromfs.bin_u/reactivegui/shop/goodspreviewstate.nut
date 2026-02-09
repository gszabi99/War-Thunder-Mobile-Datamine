from "%globalsDarg/darg_library.nut" import *
let { eventbus_subscribe } = require("eventbus")
let { defer } = require("dagor.workcycle")
let { unitSizes } = require("%appGlobals/updater/addonsState.nut")
let { unitRewardTypes, G_UNIT, G_UNIT_UPGRADE, G_BLUEPRINT, G_CURRENCY, G_LOOTBOX, G_PREMIUM, G_SKIN
} = require("%appGlobals/rewardType.nut")
let { activeOffer } = require("%rGui/shop/offerState.nut")
let { activeOffersByGoods } = require("%rGui/shop/offerByGoodsState.nut")
let { shopGoodsAllCampaigns, saveSeenGoods } = require("%rGui/shop/shopState.nut")
let { personalGoodsToShopGoods } = require("%rGui/shop/rewardsToShopGoods.nut")
let { activePersonalGoods } = require("%rGui/shop/personalGoodsState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { shopPurchaseInProgress, personalGoodsInProgress, validate_active_offer
} = require("%appGlobals/pServer/pServerApi.nut")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let { platformPurchaseInProgress } = require("%rGui/shop/platformGoods.nut")
let { openDownloadAddonsWnd } = require("%rGui/updater/updaterState.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
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


function addTagsUnitsWithPlatoon(res, unitName, sConfigs) {
  res[getTagsUnitName(unitName)] <- true
  let { platoonUnits = [] } = sConfigs?.allUnits[unitName]
  foreach (p in platoonUnits)
    res[getTagsUnitName(p.name)] <- true
}

function getAllTagsUnitsToShowGoods(goods, sConfigs) {
  let res = {}
  if (goods?.meta.previewUnit != null)
    addTagsUnitsWithPlatoon(res, goods.meta.previewUnit, sConfigs)
  foreach (r in goods.rewards)
    if (r.gType in unitRewardTypes)
      addTagsUnitsWithPlatoon(res, r.id, sConfigs)
  return res
}

let getNotLoadedTagsUnitsToShowGoods = @(goods, sConfigs, uSizes)
  getAllTagsUnitsToShowGoods(goods, sConfigs).filter(@(_, u) (uSizes?[u] ?? -1) != 0)

let getPreviewGoods = @(id, activeOff, activeOffsByGoods, shopGoods, persGoods)
  activeOff?.id == id ? activeOff
    : id in activeOffsByGoods ? activeOffsByGoods[id]
    : id in persGoods ? personalGoodsToShopGoods(persGoods[id])
    : shopGoods?[id]

function openGoodsPreview(id) {
  let goods = getPreviewGoods(id, activeOffer.get(), activeOffersByGoods.get(),
    shopGoodsAllCampaigns.get(), activePersonalGoods.get())
  if (goods == null)
    return

  let reqUnits = getNotLoadedTagsUnitsToShowGoods(goods, serverConfigs.get(), unitSizes.get())
  if (reqUnits.len() != 0) {
    openDownloadAddonsWnd([], reqUnits.keys(), "openGoodsPreview", { paramStr1 = id }, "openGoodsPreview", { id })
    return
  }

  openedGoodsId.set(id)
  openPreviewCount.set(openPreviewCount.get() + 1)
  saveSeenGoods([id])
}

function openGoodsPreviewInMenuOnly(id) {
  let goods = getPreviewGoods(id, activeOffer.get(), activeOffersByGoods.get(),
    shopGoodsAllCampaigns.get(), activePersonalGoods.get())
  if (goods == null)
    return

  let reqUnits = getNotLoadedTagsUnitsToShowGoods(goods, serverConfigs.get(), unitSizes.get())
  if (reqUnits.len() != 0) {
    openDownloadAddonsWnd([], reqUnits.keys(), "openGoodsPreview", { paramStr1 = id }, "openGoodsPreviewInMenuNoModals", { id })
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
  activeOffersByGoods.get(), shopGoodsAllCampaigns.get(), activePersonalGoods.get()))

let previewGoodsUnit = Computed(@() getBestUnitByGoods(previewGoods.get(), serverConfigs.get()))

let previewTypeByGType = {
  [G_BLUEPRINT] = GPT_BLUEPRINT,
  [G_UNIT] = GPT_UNIT,
  [G_UNIT_UPGRADE] = GPT_UNIT,
  [G_SKIN] = GPT_SKIN,
  [G_LOOTBOX] = GPT_LOOTBOX,
  [G_CURRENCY] = GPT_CURRENCY,
  [G_PREMIUM] = GPT_PREMIUM,
}

let getPreviewType = @(goods) (goods?.slotsPreset ?? "") != "" ? GPT_SLOTS
  : previewTypeByGType?[goods?.rewards[0].gType]
let previewType = Computed(@() getPreviewType(previewGoods.get()))

let isPreviewGoodsPurchasing = Computed(@() previewGoods.get()?.id != null
  && (previewGoods.get().id == shopPurchaseInProgress.get()
    || previewGoods.get().id == platformPurchaseInProgress.get()
    || previewGoods.get().id == personalGoodsInProgress.get()))

isPreviewGoodsPurchasing.subscribe(function(v) {
  if (v || previewGoods.get() == null)
    return
  let { id, limit = 0, dailyLimit = 0, oncePerSeason = "", slotsPreset = "", rewards = [] } = previewGoods.get()
  if (slotsPreset != "")
    return
  if (previewGoodsUnit.get() != null
      || activeOffer.get()?.id == id
      || limit > 0
      || dailyLimit > 0
      || oncePerSeason != ""
      || rewards.findvalue(@(r) r.gType == G_SKIN) != null)
    defer(closeGoodsPreview)
})

eventbus_subscribe("openGoodsPreview", @(msg) openGoodsPreview(msg.id))
eventbus_subscribe("openGoodsPreviewInMenuNoModals", @(msg) openGoodsPreviewInMenuOnly(msg.id))

let offerUnitName = keepref(Computed(@() activeOffer.get()?.id == openedGoodsId.get() ? previewGoodsUnit.get()?.name
  : previewGoods.get()?.skins.keys()[0]))
local offerPrevUnitName = offerUnitName.get()
offerUnitName.subscribe(function(v) {
  if (offerPrevUnitName != null && (v != null || activeOffer.get()?.id == openedGoodsId.get()))
    defer(closeGoodsPreview)
  offerPrevUnitName = v
})

let needValidate = {
  [G_UNIT] = @(r, profile, _) r.id in profile?.units,
  [G_UNIT_UPGRADE] = @(r, profile, _) profile?.units[r.id].isUpgraded ?? false,
  [G_BLUEPRINT] = @(r, profile, configs) r.id in profile?.units
    || (profile?.blueprints[r.id] ?? 0) + r.count > (configs?.allBlueprints[r.id].targetCount ?? 0),
}

servProfile.subscribe(function(servProfileV){
  if (activeOffer.get() == null)
    return

  let { rewards } = activeOffer.get()
  foreach (r in rewards)
    if (needValidate?[r.gType](r, servProfileV, serverConfigs.get()))
      return validate_active_offer(curCampaign.get())
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
  getNotLoadedTagsUnitsToShowGoods
  getPreviewType

  openSubsPreview = @(id) openedSubsId.set(id)
  closeSubsPreview = @() openedSubsId.set(null)
  openedSubsId
}