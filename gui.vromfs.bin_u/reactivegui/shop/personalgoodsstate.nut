from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { isDataBlock, eachParam } = require("%sqstd/datablock.nut")
let { prevIfEqual } = require("%sqstd/underscore.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { check_new_personal_goods, personalGoodsInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { isLoggedIn, isSettingsAvailable } = require("%appGlobals/loginState.nut")
let { isServerTimeValid, getServerTime } = require("%appGlobals/userstats/serverTime.nut")
let { isInMenu } = require("%appGlobals/clientState/clientState.nut")
let { resetExtTimeout, clearExtTimer } = require("%appGlobals/timeoutExt.nut")
let { SC_FEATURED, SC_SPECIAL } = require("%rGui/shop/shopConst.nut")


let SEEN_PERSONAL_GOODS = "seenPersonalGoods"
let seenPerosnalGoods = mkWatched(persist, "seenPersonalGoods", {})

let personalGoodsCfg = Computed(@() serverConfigs.get()?.personalGoodsCfg ?? {})
let personalGoods = Computed(@() servProfile.get()?.personalGoods ?? {})
let pGoodsRelevance = Watched({})
let pGoodsSoon = Watched({})
let pGoodsOffsetIdx = Watched(0)
let pGoodsSoonSeen = Watched({})

let getPersonalGoodsFullId = @(goodsId, idx) idx == 0 ? goodsId : $"{goodsId}&{idx}"
let getPersonalGoodsBaseId = memoize(function getPersonalGoodsBaseIdImpl(fullId) {
  let idx = fullId.indexof("&")
  return idx == null ? fullId : fullId.slice(0, idx)
})

let needRefresh = Computed(function() {
  if (!isServerTimeValid.get() || !isLoggedIn.get())
    return false
  let byBaseId = {}
  foreach (fullId, v in pGoodsRelevance.get()) {
    let id = getPersonalGoodsBaseId(fullId)
    byBaseId[id] <- (byBaseId?[id] ?? false) || v
  }
  return null != byBaseId.findindex(@(r) !r)
})
let shouldRefreshRequest = keepref(Computed(@() needRefresh.get() && isInMenu.get()))

function updateRelevance() {
  if (!isServerTimeValid.get()) {
    pGoodsRelevance.set({})
    pGoodsSoon.set({})
    return
  }

  let time = getServerTime()
  let relevance = {}
  let soon = {}
  local nextTime = 0
  foreach (baseId, cfg in personalGoodsCfg.get()) {
    let { timeRange, showTimeBeforeActivate } = cfg
    let { start, end } = timeRange
    if (showTimeBeforeActivate > 0) {
      if (start - showTimeBeforeActivate > time) {
        nextTime = min(nextTime, start - showTimeBeforeActivate)
        continue
      }
      else if (time < start)
        soon[baseId] <- true
    }

    if (time < start || (end > 0 && time >= end))
      continue

    for (local i = 0; i < cfg.slots; i++) {
      let fullId = getPersonalGoodsFullId(baseId, i)
      let { endTime = 0 } = personalGoods.get()?[fullId]
      relevance[fullId] <- endTime > time
      if (endTime > time && (nextTime == 0 || endTime < nextTime))
        nextTime = endTime
    }
  }
  pGoodsSoon.set(soon)
  pGoodsRelevance.set(relevance)

  let timeToUpdate = nextTime - time
  if (timeToUpdate <= 0)
    clearExtTimer(updateRelevance)
  else
    resetExtTimeout(timeToUpdate, updateRelevance)
}
pGoodsRelevance.whiteListMutatorClosure(updateRelevance)
updateRelevance()

foreach (w in [isServerTimeValid, personalGoodsCfg, personalGoods])
  w.subscribe(@(_) updateRelevance())

let activePersonalGoods = Computed(function(prev) {
  let res = {}
  let campaign = curCampaign.get()
  foreach (baseId, cfg in personalGoodsCfg.get()) {
    if ((cfg.meta?.campaign ?? campaign) != campaign)
      continue
    for (local i = 0; i < cfg.slots; i++) {
      let fullId = getPersonalGoodsFullId(baseId, i)
      if (!(pGoodsRelevance.get()?[fullId] ?? false))
        continue
      let cur = personalGoods.get()?[fullId]
      if (cur == null)
        continue
      let { groupId, varId } = cur
      let groupCfg = cfg.groups?[groupId]
      if (groupCfg == null)
        continue
      let { price, discountInPercent, variants, lifeTime } = groupCfg
      let { goods = null, discountInPercentOvr = null } = variants?[varId]
      if (goods == null)
        continue
      let discount = discountInPercentOvr ? discountInPercentOvr : discountInPercent
      res[fullId] <- cur.__merge({ id = fullId, goods, price, discountInPercent = discount,
        lifeTime, meta = cfg.meta
      })
    }
  }

  return prevIfEqual(prev, res)
})

let soonPersonalGoods = Computed(function(prev) {
  let res = {}
  let campaign = curCampaign.get()
  foreach (baseId, cfg in personalGoodsCfg.get()) {
    if ((cfg.meta?.campaign ?? campaign) != campaign)
      continue
    if (!(pGoodsSoon.get()?[baseId] ?? false))
      continue
    foreach (groupId, groupCfg in cfg.groups) {
      let { price, discountInPercent, variants, lifeTime } = groupCfg
      foreach (varId, variant in variants) {
        let { goods, discountInPercentOvr } = variant
        res[$"{groupId}&{varId}"] <- {
          groupId, varId, baseId, id = $"{groupId}&{varId}", goods, price, slots = cfg.slots,
          discountInPercent = discountInPercentOvr ? discountInPercentOvr : discountInPercent,
          lifeTime, meta = cfg.meta, endTime = cfg.timeRange.start, timeRange = cfg.timeRange,
        }
      }
    }
  }

  return prevIfEqual(prev, res)
})

let mkPGoodsByShopCategory = @(activeGoods) Computed(function() {
  let res = {}
  foreach (g in activeGoods.get())
    getSubArray(res, "eventId" in g.meta ? SC_SPECIAL : SC_FEATURED).append(g)
  res.each(@(l) l.sort(@(a, b)
    a.lifeTime <=> b.lifeTime
      || a.endTime <=> b.endTime
      || a.id <=> b.id))
  return res
})

let personalGoodsByShopCategory = mkPGoodsByShopCategory(activePersonalGoods)
let personalGoodsSoonByShopCategory = mkPGoodsByShopCategory(soonPersonalGoods)

let personalGoodsUnseenIds = Computed(function() {
  let unseenIds = {}
  foreach (goods in activePersonalGoods.get())
    if ((seenPerosnalGoods.get()?[goods.id] ?? 0) < goods.endTime)
      unseenIds[goods.id] <- true

  return unseenIds
})

function markPersonalGoodsSeen(ids) {
  if (!isSettingsAvailable.get())
    return
  let seen = {}
  foreach(id in ids)
    if (id in personalGoodsUnseenIds.get() && id in activePersonalGoods.get())
      seen[id] <- activePersonalGoods.get()[id].endTime

  if (seen.len() == 0)
    return

  let pBlk = get_local_custom_settings_blk().addBlock(SEEN_PERSONAL_GOODS)
  foreach(id, endTime in seen)
    pBlk[id] <- endTime

  seenPerosnalGoods.set(seenPerosnalGoods.get().__merge(seen))
  eventbus_send("saveProfile", {})
}

function resetSeenPersonalGoods() {
  seenPerosnalGoods.set({})
  get_local_custom_settings_blk().removeBlock(SEEN_PERSONAL_GOODS)
  eventbus_send("saveProfile", {})
}

function loadSeenPersonalGoods() {
  if (!isSettingsAvailable.get())
    return seenPerosnalGoods.set({})
  let blk = get_local_custom_settings_blk()
  let seenBlk = blk?[SEEN_PERSONAL_GOODS]
  let seen = {}
  if (isDataBlock(seenBlk))
    eachParam(seenBlk, @(endTime, id) seen[id] <- endTime)
  seenPerosnalGoods.set(seen)
}

if (seenPerosnalGoods.get().len() == 0)
  loadSeenPersonalGoods()
isSettingsAvailable.subscribe(@(_) loadSeenPersonalGoods())

shouldRefreshRequest.subscribe(@(v) v ? check_new_personal_goods() : null)
if (shouldRefreshRequest.get() && personalGoodsInProgress.get() == null)
  check_new_personal_goods()


return {
  pGoodsSoonSeen
  pGoodsOffsetIdx
  personalGoodsCfg
  activePersonalGoods
  personalGoodsByShopCategory
  personalGoodsSoonByShopCategory
  getPersonalGoodsBaseId
  personalGoodsUnseenIds
  markPersonalGoodsSeen
  resetSeenPersonalGoods
}