from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import defer
from "eventbus" import eventbus_subscribe
from "%appGlobals/pServer/bqClient.nut" import sendUiBqEvent
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/pServer/pServerApi.nut" import shopPurchaseInProgress, personalGoodsInProgress, validate_active_offer
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/rewardType.nut" import unitRewardTypes, G_UNIT, G_UNIT_UPGRADE, G_BLUEPRINT, G_CURRENCY, G_LOOTBOX,
  G_PREMIUM, G_SKIN
from "%appGlobals/updater/addonsState.nut" import unitSizes
from "%rGui/mainMenu/mainMenuState.nut" import isInMenuNoModals
from "%rGui/shop/goodsUtils.nut" import getBestUnitByGoods
from "%rGui/shop/offerByGoodsState.nut" import activeOffersByGoods
from "%rGui/shop/offerState.nut" import activeOffer
from "%rGui/shop/personalGoodsState.nut" import activePersonalGoods
from "%rGui/shop/platformGoods.nut" import platformPurchaseInProgress
from "%rGui/shop/rewardsToShopGoods.nut" import personalGoodsToShopGoods
from "%rGui/shop/shopState.nut" import shopGoodsAllCampaigns, saveSeenGoods
from "%rGui/updater/updaterState.nut" import openDownloadAddonsWnd


const GPT_UNIT = "unit"
const GPT_CURRENCY = "currency"
const GPT_PREMIUM = "premium"
const GPT_LOOTBOX = "lootbox"
const GPT_SLOTS = "slots"
const GPT_BLUEPRINT = "blueprint"
const GPT_SKIN = "skin"

const HIDE_PREVIEW_MODALS_ID = "goodsPreviewAnim"

let openedUnitFromTree = mkWatched(persist, "openedUnitFromTree", null)
let openedGoodsId = mkWatched(persist, "openedGoodsId", null)
let closeGoodsPreview = @() openedGoodsId.set(null)
let openPreviewCount = Watched(openedGoodsId.get() == null ? 0 : 1)
let openedSubsId = mkWatched(persist, "openedSubsId", null)


function getAllTagsUnitsToShowGoods(goods) {
  let res = {}
  if (goods?.meta.previewUnit != null)
    res[goods.meta.previewUnit] <- true
  foreach (r in goods.rewards)
    if (r.gType in unitRewardTypes)
      res[r.id] <- true
  return res
}

let getNotLoadedTagsUnitsToShowGoods = @(goods, uSizes)
  getAllTagsUnitsToShowGoods(goods).filter(@(_, u) (uSizes?[u] ?? -1) != 0)

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

  let reqUnits = getNotLoadedTagsUnitsToShowGoods(goods, unitSizes.get())
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

  let reqUnits = getNotLoadedTagsUnitsToShowGoods(goods, unitSizes.get())
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

function openSubsPreview(id, bqSourceId) {
  openedSubsId.set(id)
  if(bqSourceId)
    sendUiBqEvent("open_subscription_window", {id = bqSourceId})
}

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

  openSubsPreview
  closeSubsPreview = @() openedSubsId.set(null)
  openedSubsId
}