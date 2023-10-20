from "%globalsDarg/darg_library.nut" import *
let { send } = require("eventbus")
let { register_command } = require("console")
let { get_local_custom_settings_blk } = require("blkGetters")
let { isDataBlock, eachParam } = require("%sqstd/datablock.nut")
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { eventLootboxes, eventLootboxesRaw } = require("eventLootboxes.nut")
let { onSchRewardReceive, schRewards, schRewardsStatus } = require("%rGui/shop/schRewardsState.nut")
let { userstatStats } = require("%rGui/unlocks/userstat.nut")
let { balanceWarbond, balanceEventKey, EVENT_KEY, WARBOND } = require("%appGlobals/currenciesState.nut")
let lootboxPreviewWnd = require("%rGui/shop/lootboxPreviewWnd.nut")
let { doesLocTextExist } = require("dagor.localize")


let SEEN_LOOTBOXES = "seenLootboxes"
let LOOTBOXES_AVAILABILITY = "lootboxesAvailability"
let getSeasonPrefix = @(n) $"season_{n}"

let isEventWndOpen = mkWatched(persist, "isEventWndOpen", false)
let eventWndOpenCount = Watched(0)
let eventWndShowAnimation = Watched(true)
let curLootbox = Watched(null)
let curLootboxIndex = Computed(@() eventLootboxes.value?.findindex(@(v) v.name == curLootbox.value) ?? -1)

let eventRewards = Computed(@() schRewards.value
  .filter(@(v) v.lootboxes.findindex(@(_, key) key in eventLootboxesRaw.value))
  .map(@(v, key) v.__merge(schRewardsStatus.value?[key] ?? {})))

let showLootboxAds = @(id) onSchRewardReceive(eventRewards.value?[id])

let eventEndsAt = Computed(@() userstatStats.value?.stats.season["$endsAt"] ?? 0)
let eventSeason = Computed(@() getSeasonPrefix(userstatStats.value?.stats.season["$index"] ?? 1))
let eventSeasonName = Computed(function() {
  local locId = $"events/name/{eventSeason.value}"
  if (!doesLocTextExist(locId))
    locId = "events/name/default"
  return loc(locId)
})

let seenLootboxes = mkWatched(persist, SEEN_LOOTBOXES, {})
let lootboxesAvailability = mkWatched(persist, LOOTBOXES_AVAILABILITY, {})
let unseenLootboxes = Computed(@() eventLootboxesRaw.value.filter(@(_, id) id not in seenLootboxes.value?[eventSeason.value]))
let unseenLootboxesShowOnce = mkWatched(persist, "unseenLootboxesShowOnce", {})

let function saveSeenLootboxes(ids) {
  let season = eventSeason.value
  ids = ids.filter(@(id) id not in seenLootboxes.value?[season])
  if (ids.len() == 0)
    return
  seenLootboxes.mutate(function(v) {
    if (season not in v)
      v[season] <- {}
    foreach (id in ids)
      v[season][id] <- true
  })
  let sBlk = get_local_custom_settings_blk().addBlock(SEEN_LOOTBOXES)
  let blk = sBlk.addBlock(season)
  foreach (id, isSeen in seenLootboxes.value?[season] ?? {})
    if (isSeen)
      blk[id] = true
  send("saveProfile", {})
}

let function loadSeenLootboxes() {
  let blk = get_local_custom_settings_blk()
  let htBlk = blk?[SEEN_LOOTBOXES]
  if (!isDataBlock(htBlk)) {
    seenLootboxes({})
    return
  }
  let res = {}
  foreach (season, lootboxes in htBlk) {
    let seasonSeenLootboxes = {}
    eachParam(lootboxes, @(isSeen, id) seasonSeenLootboxes[id] <- isSeen)
    if (seasonSeenLootboxes.len() > 0)
      res[season] <- seasonSeenLootboxes
  }
  seenLootboxes(res)
}

let function loadLootboxesAvailability() {
  let blk = get_local_custom_settings_blk()
  let htBlk = blk?[LOOTBOXES_AVAILABILITY]
  if (!isDataBlock(htBlk)) {
    lootboxesAvailability({})
    return
  }
  let res = {}
  eachParam(htBlk, @(canBuy, id) res[id] <- canBuy)
  lootboxesAvailability(res)
}

let function updateLootboxAvailability(lootboxes) {
  lootboxes = lootboxes.filter(@(canBuy, id) lootboxesAvailability.value?[id] != canBuy)
  if (lootboxes.len() == 0)
    return
  lootboxesAvailability.mutate(function(v) {
    foreach (id, canBuy in lootboxes)
      v[id] <- canBuy
  })
  let sBlk = get_local_custom_settings_blk()
  let blk = sBlk.addBlock(LOOTBOXES_AVAILABILITY)
  foreach (id, canBuy in lootboxesAvailability.value ?? {})
    blk[id] = canBuy
  send("saveProfile", {})
}

let function updateUnseenLootboxesShowOnce(lootboxes) {
  lootboxes = lootboxes.filter(@(showMark, id) unseenLootboxesShowOnce.value?[id] != showMark)
  if (lootboxes.len() == 0)
    return
  unseenLootboxesShowOnce.mutate(function(v) {
    foreach (id, showMark in lootboxes)
      v[id] <- showMark
  })
}


if (seenLootboxes.value.len() == 0)
  loadSeenLootboxes()
if (lootboxesAvailability.value.len() == 0)
  loadLootboxesAvailability()

let function onCurrencyChange(currencyId, balance) {
  let showOnce = {}
  let availability = {}
  foreach (lootbox in eventLootboxes.value) {
    if (lootbox.currencyId != currencyId)
      continue
    let canBuy = balance >= lootbox.price
    if (canBuy && lootboxesAvailability.value?[lootbox.name] == false)
      showOnce[lootbox.name] <- true
    availability[lootbox.name] <- canBuy
  }
  updateUnseenLootboxesShowOnce(showOnce)
  updateLootboxAvailability(availability)
}

balanceEventKey.subscribe(@(balance) onCurrencyChange(EVENT_KEY, balance))
balanceWarbond.subscribe(@(balance) onCurrencyChange(WARBOND, balance))

let function openLootboxWnd(id) {
  curLootbox(id)
  saveSeenLootboxes([id])
  updateUnseenLootboxesShowOnce({ [id] = false })
}

let function openLootboxPreviewWnd(id) {
  lootboxPreviewWnd(id)
  saveSeenLootboxes([id])
  updateUnseenLootboxesShowOnce({ [id] = false })
}

let function openEventWnd() {
  if (isOfflineMenu) {
    openFMsgBox({ text = "Not supported in the offline mode" })
    return
  }
  eventWndOpenCount(eventWndOpenCount.value + 1)
  isEventWndOpen(true)
}

register_command(function() {
  seenLootboxes({})
  get_local_custom_settings_blk().removeBlock(SEEN_LOOTBOXES)
  send("saveProfile", {})
}, "debug.reset_seen_lootboxes")

register_command(function() {
  lootboxesAvailability({})
  get_local_custom_settings_blk().removeBlock(LOOTBOXES_AVAILABILITY)
  send("saveProfile", {})
}, "debug.reset_lootboxes_availability")

return {
  isEventWndOpen
  eventWndOpenCount
  openEventWnd
  closeEventWnd = @() isEventWndOpen(false)
  closeLootboxWnd = @() curLootbox(null)
  eventWndShowAnimation
  curLootbox
  curLootboxIndex
  openLootboxWnd
  openLootboxPreviewWnd
  showLootboxAds
  eventRewards
  eventEndsAt
  eventSeason
  eventSeasonName

  unseenLootboxes
  unseenLootboxesShowOnce
}