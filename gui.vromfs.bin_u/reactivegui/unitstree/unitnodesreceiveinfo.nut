from "%globalsDarg/darg_library.nut" import *
from "%sqstd/underscore.nut" import prevIfEqual
from "%appGlobals/config/lootboxPresentation.nut" import getLootboxName
from "%appGlobals/currenciesState.nut" import WP, GOLD, PLATINUM
from "%appGlobals/pServer/campaign.nut" import campConfigs
from "%appGlobals/pServer/profile.nut" import campMyUnits
import "%appGlobals/pServer/unreleasedUnits.nut" as unreleasedUnits
from "%appGlobals/rewardType.nut" import unitRewardTypes, G_LOOTBOX
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%rGui/event/eventLootboxes.nut" import eventLootboxes
from "%rGui/event/eventState.nut" import MAIN_EVENT_ID
import "%rGui/event/shouldShowEventMechanics.nut" as shouldShowEventMechanics
from "%rGui/rewards/lootboxesRewards.nut" import UnitsSearcher
from "%rGui/seasonScene/seasonSceneState.nut" import openSeasonScene, LOOTBOX_TAB
from "%rGui/shop/goodsPreviewState.nut" import openGoodsPreview
from "%rGui/shop/goodsView/goodsLootbox.nut" import getLocNameLootbox
from "%rGui/shop/lootboxPreviewState.nut" import openEventWndLootbox
from "%rGui/shop/personalGoodsState.nut" import personalGoodsByShopCategory
from "%rGui/shop/shopState.nut" import goodsByCategory
from "%rGui/style/stdColors.nut" import markTextColor


const NP_SHOP_DIRECT = "shop_direct"
const NP_SHOP_PERSONAL = "shop_personal"
const NP_SHOP_LOOTBOX = "shop_lootbox"
const NP_EVENT_LOOTBOX = "event_lootbox"

const defCurrencyPriority = 10
let priorityByCurrency = {
  [PLATINUM] = 12,
  [GOLD] = 11,
  [WP] = 1,
  [""] = 0,
}

let openShopGoods = @(goods) openGoodsPreview(goods.id)

function mkGoodsTimeLeft(g) {
  let { timeRanges } = g
  if (timeRanges.len() == 0)
    return Watched(-1)
  return Computed(function() {
    let t = serverTime.get()
    foreach (tr in timeRanges) {
      let { start, end } = tr
      if (start <= t && end > t)
        return end - t
    }
    return 0
  })
}

let receiveTypeCfg = {
  [NP_SHOP_DIRECT] = {
    priority = @(g) 2000 + (priorityByCurrency?[g.price.currencyId] ?? defCurrencyPriority)
    receiveInfoLocId = "mainmenu/btnBuy"
    receiveInfoDesc = @(_) loc("canReceive/inShop")
    open = openShopGoods
    mkTimeLeft = mkGoodsTimeLeft
  },

  [NP_SHOP_PERSONAL] = {
    priority = @(g) 2000 + (priorityByCurrency?[g.price.currencyId] ?? defCurrencyPriority)
    receiveInfoLocId = "mainmenu/btnBuy"
    receiveInfoDesc = @(_) loc("canReceive/inShop")
    open = openShopGoods
    mkTimeLeft = @(p) Computed(@() max(0, p.endTime - serverTime.get()))
  },

  [NP_SHOP_LOOTBOX] = {
    priority = @(g) 1000 + (priorityByCurrency?[g.price.currencyId] ?? defCurrencyPriority)
    receiveInfoLocId = "msgbox/btn_browse"
    receiveInfoDesc = @(g) loc("canReceive/inShopLootbox",
      { name = colorize(markTextColor, getLocNameLootbox(g).replace(" ", nbsp)) })
    open = openShopGoods
    mkTimeLeft = mkGoodsTimeLeft
  },

  [NP_EVENT_LOOTBOX] = {
    priority = @(_) 1
    receiveInfoLocId = "msgbox/btn_browse"
    receiveInfoDesc = @(l) loc("canReceive/inShopLootbox",
      { name = colorize(markTextColor, getLootboxName(l.name).replace(" ", nbsp)) })
    function open(l) {
      openSeasonScene(l?.meta.event_id ?? MAIN_EVENT_ID, LOOTBOX_TAB)
      openEventWndLootbox(l.name)
    },
    function mkTimeLeft(l) {
      let { end } = l.timeRange
      return end == 0 ? Watched(-1)
        : Computed(@() max(0, end - serverTime.get()))
    }
  },
}

function chooseBestPurchInfo(list) {
  if (list.len() <= 1)
    return list?[0]
  local res = null
  local priority = 0
  foreach (r in list) {
    let p = receiveTypeCfg?[r.receiveType].priority(r.receiveData) ?? 0
    if (res == null || priority < p) {
      res = r
      priority = p
    }
  }
  return res
}

let getNodesReceiveInfo = kwarg(function getNodesReceiveInfoImpl(
    campConfigsV,
    campMyUnitsV,
    unreleasedUnitsV,
    goodsByCategoryV,
    personalGoodsByShopCategoryV,
    eventLootboxesV,
    shouldShowEventMechanicsV) {
  let { allUnits = {}, unitTreeNodes = {}, lootboxesCfg = {}, rewardsCfg = {} } = campConfigsV
  let unitsToSearch = unitTreeNodes.filter(@(v) v.name not in campMyUnitsV
    && v.name not in unreleasedUnitsV
    && (allUnits?[v.name].isHidden ?? false))
  if (unitsToSearch.len() == 0)
    return {}

  let resVariants = {}
  let searcher = UnitsSearcher(rewardsCfg, lootboxesCfg)
  function onFound(unitId, receiveType, receiveData) {
    if (unitId in unitsToSearch)
      getSubArray(resVariants, unitId).append({ receiveType, receiveData })
  }

  foreach (list in goodsByCategoryV)
    foreach (goods in list) {
      let { rewards } = goods
      
      foreach (r in rewards)
        if (r.gType in unitRewardTypes)
          onFound(r.id, NP_SHOP_DIRECT, goods)
        else if (r.gType == G_LOOTBOX)
          foreach (u, _ in searcher.getLootboxUnits(r.id))
            onFound(u, NP_SHOP_LOOTBOX, goods)
    }

  foreach (list in personalGoodsByShopCategoryV)
    foreach (p in list) {
      let { goods } = p
      
      foreach (r in goods)
        if (r.gType in unitRewardTypes)
          onFound(r.id, NP_SHOP_PERSONAL, p)
    }
  if (shouldShowEventMechanicsV)
    foreach (lootbox in eventLootboxesV)
      foreach (u, _ in searcher.getLootboxUnits(lootbox.name))
        onFound(u, NP_EVENT_LOOTBOX, lootbox)

  return resVariants.map(@(v, id) unitsToSearch[id].__merge(chooseBestPurchInfo(v)))
})


let mkNodesReceiveInfo = @() Computed(@(prev) prevIfEqual(prev, getNodesReceiveInfo({
  campConfigsV = campConfigs.get(),
  campMyUnitsV = campMyUnits.get(),
  unreleasedUnitsV = unreleasedUnits.get(),
  goodsByCategoryV = goodsByCategory.get(),
  personalGoodsByShopCategoryV = personalGoodsByShopCategory.get(),
  eventLootboxesV = eventLootboxes.get(),
  shouldShowEventMechanicsV = shouldShowEventMechanics.get()
})))

return {
  mkNodesReceiveInfo
  getNodesReceiveInfo
  getReceiveLocId = @(receiveType) receiveTypeCfg?[receiveType].receiveInfoLocId ?? "msgbox/btn_browse"
  goToReceive = @(receiveType, receiveData) receiveTypeCfg?[receiveType].open(receiveData)
  mkReceiveTimeLeft = @(receiveType, receiveData) receiveTypeCfg?[receiveType].mkTimeLeft(receiveData) ?? Watched(-1)
  getReceiveDesc = @(receiveType, receiveData) receiveTypeCfg?[receiveType].receiveInfoDesc(receiveData) ?? ""
}