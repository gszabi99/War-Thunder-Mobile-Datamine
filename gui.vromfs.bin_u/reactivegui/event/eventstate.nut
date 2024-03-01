from "%globalsDarg/darg_library.nut" import *
let logE = log_with_prefix("[EVENTS] ")
let { eventbus_send } = require("eventbus")
let { register_command } = require("console")
let { get_local_custom_settings_blk } = require("blkGetters")
let { isDataBlock, eachParam } = require("%sqstd/datablock.nut")
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { eventLootboxesRaw, orderLootboxesBySlot } = require("eventLootboxes.nut")
let { userstatStats } = require("%rGui/unlocks/userstat.nut")
let { balance } = require("%appGlobals/currenciesState.nut")
let { doesLocTextExist } = require("dagor.localize")
let { unlockTables, activeUnlocks } = require("%rGui/unlocks/unlocks.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { closeLootboxPreview } = require("%rGui/shop/lootboxPreviewState.nut")

let SEEN_LOOTBOXES = "seenLootboxes"
let LOOTBOXES_AVAILABILITY = "lootboxesAvailability"
let MAIN_EVENT_ID = "main"
let getSeasonPrefix = @(n) $"season_{n}"
let SEASON_EMPTY = getSeasonPrefix(0)
let getSpecialEventName = @(n) $"special_event_{n}"

let openEventInfo = mkWatched(persist, "openEventInfo")
let curEvent = Computed(@() openEventInfo.get()?.eventName)
let eventWndOpenCounter = Computed(@() openEventInfo.get()?.counter ?? 0)

eventWndOpenCounter.subscribe(function(v) {
  if (v == 0)
    closeLootboxPreview()
})

let eventEndsAt = Computed(@() userstatStats.value?.stats.season["$endsAt"] ?? 0)
let eventSeason = Computed(@() getSeasonPrefix(userstatStats.value?.stats.season["$index"] ?? 0))
let isEventActive = Computed(@() unlockTables.value?.season == true)

let miniEventSeasonName = loc("mini_event_quest_2024_operation_grenade_germany_kill")
let miniEventEndsAt = Computed(@() userstatStats.value?.stats.mini_event_season["$endsAt"] ?? 0)
let isMiniEventActive = Computed(@() unlockTables.value?.mini_event_season == true)

let seenLootboxes = mkWatched(persist, SEEN_LOOTBOXES, {})
let lootboxesAvailability = mkWatched(persist, LOOTBOXES_AVAILABILITY, {})
let unseenLootboxes = Computed(function() {
  let res = {}
  let lootboxes = eventLootboxesRaw.get()
    .filter(@(v) v.name not in seenLootboxes.value?[v.meta.event_id])
  foreach (lootbox in lootboxes) {
    let eventId = lootbox.meta.event_id
    if (eventId not in res)
      res[eventId] <- {}
    res[eventId].rawset(lootbox.name, true)
  }
  return res
})
let unseenLootboxesShowOnce = mkWatched(persist, "unseenLootboxesShowOnce", {})

let bestCampLevel = Computed(@() servProfile.value?.levelInfo.reduce(@(a, b) max(a?.level ?? 0, b?.level ?? 0)) ?? 1)

let specialEvents = Computed(function() {
  let res = {}
  let specialEventsList = eventLootboxesRaw.value.reduce(function(acc, e) {
    let id = e?.meta.event_id
    if (id != null && acc.findindex(@(v) v == id) == null && id != MAIN_EVENT_ID)
      acc.append(id)
    return acc
  }, [])

  foreach (idx, eventName in specialEventsList) {
    let tableId = activeUnlocks.value
      .filter(@(u) u?.meta.event_id == eventName)
      .findvalue(@(v) v.table != "")?.table
    if (!unlockTables.value?[tableId])
      continue
    let endsAt = userstatStats.value?.stats[tableId]["$endsAt"] ?? 0
    let season = userstatStats.value?.stats[tableId]["$index"] ?? 1
    let eventId = getSpecialEventName(idx + 1)

    res[eventId] <- {
      eventName
      eventId
      endsAt
      season
    }
  }
  return res
})

let getEventBg = @(eventId, eSeason, sEvents, bgFallback) !eventId ? bgFallback
  : $"ui/images/event_bg_{eventId == MAIN_EVENT_ID ? eSeason : sEvents?[eventId].eventName}.avif"
let eventBgFallback = "ui/images/event_bg.avif"
let curEventBg = Computed(@() getEventBg(curEvent.get(), eventSeason.get(), specialEvents.get(), eventBgFallback))

function getEventLoc(eventId, eSeason, sEvents) {
  local locId = eventId == MAIN_EVENT_ID
      ? $"events/name/{eSeason}"
    : "".concat("events/name/", sEvents?[eventId].eventName)
  if (!doesLocTextExist(locId))
    locId = "events/name/default"
  return loc(locId)
}
let curEventLoc = Computed(@() getEventLoc(curEvent.get(), eventSeason.get(), specialEvents.get()))

let curEventSeason = Computed(@() curEvent.value == MAIN_EVENT_ID
    ? (userstatStats.value?.stats.season["$index"] ?? 0)
  : specialEvents.value?[curEvent.value].season)

let curEventEndsAt = Computed(@() curEvent.value == MAIN_EVENT_ID
    ? eventEndsAt.value
  : (specialEvents.value?[curEvent.value].endsAt ?? 0))

let curEventName = Computed(@() curEvent.value == MAIN_EVENT_ID
    ? curEvent.value
  : specialEvents.value?[curEvent.value].eventName)

let isCurEventActive = Computed(@() curEvent.get() == MAIN_EVENT_ID
    ? isEventActive.get()
  : isMiniEventActive.get())

let curEventLootboxes = Computed(@()
  orderLootboxesBySlot(eventLootboxesRaw.value.filter(@(v) v?.meta.event_id == curEventName.value)))

let curEventCurrencies = Computed(@() curEventLootboxes.value.reduce(function(res, l) {
  let currencyId = l?.currencyId
  if (currencyId != null && res.findindex(@(v) v == currencyId) == null)
    res.append(currencyId)
  return res
}, []))

function saveSeenLootboxes(ids, eventName) {
  ids = ids.filter(@(id) id not in seenLootboxes.value?[eventName])
  if (ids.len() == 0)
    return
  seenLootboxes.mutate(function(v) {
    if (eventName not in v)
      v[eventName] <- {}
    foreach (id in ids)
      v[eventName][id] <- true
  })
  let sBlk = get_local_custom_settings_blk().addBlock(SEEN_LOOTBOXES)
  let blk = sBlk.addBlock(eventName)
  foreach (id, isSeen in seenLootboxes.value?[eventName] ?? {})
    if (isSeen)
      blk[id] = true
  eventbus_send("saveProfile", {})
}

function loadSeenLootboxes() {
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

function loadLootboxesAvailability() {
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

function updateLootboxAvailability(lootboxes) {
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
  eventbus_send("saveProfile", {})
}

function updateUnseenLootboxesShowOnce(lootboxes) {
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

balance.subscribe(function(v) {
  let showOnce = {}
  let availability = {}
  foreach (lootbox in eventLootboxesRaw.value) {
    let canBuy = (v?[lootbox.currencyId] ?? 0) >= lootbox.price
    if (canBuy && lootboxesAvailability.value?[lootbox.name] == false)
      showOnce[lootbox.name] <- lootbox?.meta.event_id ?? MAIN_EVENT_ID
    availability[lootbox.name] <- canBuy
  }
  updateUnseenLootboxesShowOnce(showOnce)
  updateLootboxAvailability(availability)
})

function markCurLootboxSeen(id) {
  saveSeenLootboxes([id], curEventName.get())
  updateUnseenLootboxesShowOnce({ [id] = false })
}

function openEventWnd(eventName = MAIN_EVENT_ID) {
  eventName = specialEvents.get().findvalue(@(v) v.eventName == eventName)?.eventId ?? eventName
  if (isOfflineMenu) {
    openFMsgBox({ text = "Not supported in the offline mode" })
    return
  }
  openEventInfo({
    eventName
    counter = curEvent.get() == eventName ? eventWndOpenCounter.get() + 1 : 1
  })
}

let gamercardItemsBySpecialEvent = {
  christmas = [ "firework_kit" ]
}
let specialEventGamercardItems = Computed(function() {
  let specialEventsList = specialEvents.get().reduce(function(acc, e) {
    acc.append(e.eventName)
    return acc
  }, [])
  let res = []
  foreach (eventName, items in gamercardItemsBySpecialEvent)
    if (specialEventsList.indexof(eventName) != null)
      res.extend(items.map(@(itemId) { itemId, eventName }))
  return res
})

register_command(function() {
  seenLootboxes({})
  get_local_custom_settings_blk().removeBlock(SEEN_LOOTBOXES)
  eventbus_send("saveProfile", {})
}, "debug.reset_seen_lootboxes")

register_command(function() {
  lootboxesAvailability({})
  get_local_custom_settings_blk().removeBlock(LOOTBOXES_AVAILABILITY)
  eventbus_send("saveProfile", {})
}, "debug.reset_lootboxes_availability")

isEventActive.subscribe(@(v) v ? null : logE($"Primary game event finished!"))
isMiniEventActive.subscribe(@(v) v ? null : logE($"Mini game event finished!"))

return {
  curEvent
  curEventName
  curEventLoc
  getEventLoc
  curEventSeason
  curEventEndsAt
  isCurEventActive

  eventWndOpenCounter
  openEventWnd
  closeEventWnd = @() openEventInfo.set(null)
  markCurLootboxSeen
  eventEndsAt
  eventSeason
  isEventActive
  isMiniEventActive
  miniEventSeasonName
  miniEventEndsAt

  unseenLootboxes
  unseenLootboxesShowOnce

  bestCampLevel

  MAIN_EVENT_ID
  SEASON_EMPTY
  specialEvents
  getSpecialEventName
  curEventLootboxes
  curEventCurrencies
  specialEventGamercardItems

  eventBgFallback
  curEventBg
  getEventBg
}
