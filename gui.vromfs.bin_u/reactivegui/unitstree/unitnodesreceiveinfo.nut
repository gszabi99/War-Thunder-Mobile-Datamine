from "%globalsDarg/darg_library.nut" import *
from "%sqstd/underscore.nut" import prevIfEqual
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let unreleasedUnits = require("%appGlobals/pServer/unreleasedUnits.nut")
let { unitRewardTypes, G_LOOTBOX } = require("%appGlobals/rewardType.nut")
let { WP, GOLD, PLATINUM } = require("%appGlobals/currenciesState.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { getLootboxName } = require("%appGlobals/config/lootboxPresentation.nut")
let { goodsByCategory } = require("%rGui/shop/shopState.nut")
let { personalGoodsByShopCategory } = require("%rGui/shop/personalGoodsState.nut")
let { UnitsSearcher } = require("%rGui/rewards/lootboxesRewards.nut")
let { openGoodsPreview } = require("%rGui/shop/goodsPreviewState.nut")
let { openEventWndLootbox } = require("%rGui/shop/lootboxPreviewState.nut")
let { getLocNameLootbox } = require("%rGui/shop/goodsView/goodsLootbox.nut")
let { eventLootboxes } = require("%rGui/event/eventLootboxes.nut")
let { MAIN_EVENT_ID, shouldShowEventMechanics } = require("%rGui/event/eventState.nut")
let { openSeasonScene, LOOTBOX_TAB } = require("%rGui/seasonScene/seasonSceneState.nut")
let { markTextColor } = require("%rGui/style/stdColors.nut")


let NP_SHOP_DIRECT = "shop_direct"
let NP_SHOP_PERSONAL = "shop_personal"
let NP_SHOP_LOOTBOX = "shop_lootbox"
let NP_EVENT_LOOTBOX = "event_lootbox"

let defCurrencyPriority = 10
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