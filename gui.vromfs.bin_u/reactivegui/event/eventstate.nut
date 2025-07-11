from "%globalsDarg/darg_library.nut" import *
let logE = log_with_prefix("[EVENTS] ")
let { eventbus_send } = require("eventbus")
let { register_command } = require("console")
let { get_local_custom_settings_blk } = require("blkGetters")
let { isDataBlock, eachParam } = require("%sqstd/datablock.nut")
let { SAILBOAT } = require("%appGlobals/unitConst.nut")
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { campaignsLevelInfo, campaignsList } = require("%appGlobals/pServer/campaign.nut")
let { curSeasons } = require("%appGlobals/pServer/profileSeasons.nut")
let { eventLootboxesRaw, orderLootboxesBySlot } = require("eventLootboxes.nut")
let { userstatStats } = require("%rGui/unlocks/userstat.nut")
let { balance } = require("%appGlobals/currenciesState.nut")
let { doesLocTextExist } = require("dagor.localize")
let { unlockTables, activeUnlocks } = require("%rGui/unlocks/unlocks.nut")
let { closeEventWndLootbox } = require("%rGui/shop/lootboxPreviewState.nut")
let { getEventPresentation } = require("%appGlobals/config/eventSeasonPresentation.nut")
let { isSettingsAvailable } = require("%appGlobals/loginState.nut")


let SEEN_LOOTBOXES = "seenLootboxes"
let LOOTBOXES_AVAILABILITY = "lootboxesAvailability"
let MAIN_EVENT_ID = "main"
let getSeasonPrefix = @(n) $"season_{n}"
let getSpecialEventName = @(n) $"special_event_{n}"

let openEventInfo = mkWatched(persist, "openEventInfo")
let curEvent = Computed(@() openEventInfo.get()?.eventName)
let eventWndOpenCounter = Computed(@() openEventInfo.get()?.counter ?? 0)

eventWndOpenCounter.subscribe(function(v) {
  if (v == 0)
    closeEventWndLootbox()
})

let eventEndsAt = Computed(@() userstatStats.value?.stats.season["$endsAt"] ?? 0)
let eventSeasonIdx = Computed(@() userstatStats.get()?.stats.season["$index"] ?? 0)
let eventSeason = Computed(@() getSeasonPrefix(eventSeasonIdx.get()))
let isEventActive = Computed(@() unlockTables.value?.season == true)

let seenLootboxes = mkWatched(persist, SEEN_LOOTBOXES, {})
let lootboxesAvailability = mkWatched(persist, LOOTBOXES_AVAILABILITY, {})
let unseenLootboxes = Computed(function() {
  let res = {}
  foreach (lootbox in eventLootboxesRaw.get()) {
    let eventId = lootbox?.meta.event_id ?? MAIN_EVENT_ID
    if (lootbox.name in seenLootboxes.value?[eventId])
      continue
    if (eventId not in res)
      res[eventId] <- {}
    res[eventId].rawset(lootbox.name, true)
  }
  return res
})
let unseenLootboxesShowOnce = mkWatched(persist, "unseenLootboxesShowOnce", {})

let bestCampLevel = Computed(@() campaignsLevelInfo.get()?.reduce(@(res, li) max(res, li?.level ?? 0), 0) ?? 1)

let eventsLists = Computed(function() {
  let events = {}
  let eventsWithTree = {}
  foreach (unlock in activeUnlocks.get()) {
    let { event_id = null, tree_travel = false, tree_gift = false, tree_quest = false, quest_cluster = false } = unlock?.meta
    let isTreeEvent = tree_travel || tree_gift || tree_quest || quest_cluster
    if (event_id == null || event_id == MAIN_EVENT_ID || event_id in events || event_id in eventsWithTree)
      continue
    let tableId = unlock.table
    if (!unlockTables.get()?[tableId])
      continue
    let endsAt = userstatStats.get()?.stats[tableId]["$endsAt"] ?? 0
    let season = userstatStats.get()?.stats[tableId]["$index"] ?? 1

    let eventData = {
      eventName = event_id
      endsAt
      season
    }
    if (isTreeEvent)
      eventsWithTree[event_id] <- eventData
    else
      events[event_id] <- eventData
  }

  return { events, eventsWithTree }
})

let events = Computed(@() eventsLists.get().events)

function orderEvents(data) {
  let res = data.values().sort(@(a, b) a.endsAt <=> b.endsAt)
  res.each(@(v, idx) v.__update({ idx, eventId = getSpecialEventName(idx + 1) }))
  return res
}

let specialEventsOrdered = Computed(@() orderEvents(events.get()))
let specialEvents = Computed(@() specialEventsOrdered.get().reduce(@(res, v) res.$rawset(v.eventId, v), {}))
let specialEventsWithTree = Computed(@() eventsLists.get().eventsWithTree)
let allSpecialEvents = Computed(@() {}.__merge(specialEvents.get(), specialEventsWithTree.get()))

let specialEventsLootboxesState = Computed(function() {
  let lootboxesEventIds = {}
  foreach(l in eventLootboxesRaw.get()) {
    let { event_id = null } = l?.meta
    if (event_id != null)
      lootboxesEventIds[event_id] <- true
  }
  let res = { withLootboxes = {}, withoutLootboxes = {} }

  foreach (se in specialEvents.get()) {
    let { eventName } = se
    if (eventName in lootboxesEventIds)
      res.withLootboxes[eventName] <- se
    else
      res.withoutLootboxes[eventName] <- se
  }
  return res
})

let getEventPresentationId = @(eventId, eSeason, sEvents) eventId == MAIN_EVENT_ID ? eSeason : sEvents?[eventId].eventName
let curEventBg = Computed(@() getEventPresentation(getEventPresentationId(curEvent.get(), eventSeason.get(), allSpecialEvents.get())).bg)

function getEventLoc(eventId, eSeason, sEvents) {
  local locId = eventId == MAIN_EVENT_ID
      ? $"events/name/{eSeason}"
    : "".concat("events/name/", sEvents?[eventId].eventName)
  if (!doesLocTextExist(locId))
    locId = "events/name/default"
  return loc(locId)
}
let curEventLoc = Computed(@() getEventLoc(curEvent.get(), eventSeason.get(), allSpecialEvents.get()))

let curEventSeason = Computed(@() curEvent.value == MAIN_EVENT_ID
    ? (userstatStats.value?.stats.season["$index"] ?? 0)
  : specialEvents.value?[curEvent.value].season)

let curEventEndsAt = Computed(@() curEvent.value == MAIN_EVENT_ID
    ? eventEndsAt.value
  : (specialEvents.value?[curEvent.value].endsAt ?? 0))

let curEventName = Computed(@() curEvent.get() == MAIN_EVENT_ID
    ? curEvent.get()
  : specialEvents.get()?[curEvent.get()].eventName ?? curEvent.get())

let isCurEventActive = Computed(@() curEvent.get() == MAIN_EVENT_ID ? isEventActive.get()
  : curEvent.get() in specialEvents.get())

let curEventLootboxes = Computed(@()
  orderLootboxesBySlot(eventLootboxesRaw.value.filter(@(v) (v?.meta.event_id ?? MAIN_EVENT_ID) == curEventName.value)))

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
  if (!isSettingsAvailable.get())
    return seenLootboxes.set({})
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
  if (!isSettingsAvailable.get())
    return lootboxesAvailability.set({})
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

isSettingsAvailable.subscribe(function(_) {
  loadSeenLootboxes()
  loadLootboxesAvailability()
})

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
  event_new_year = [ "firework_kit" ]
  event_lunar_ny_season = [ "firework_kit" ]
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

let eventUnitTypes = {
  event_april_2025 = SAILBOAT
}
let unitTypesByEvent = Computed(function() {
  let res = []
  foreach (eventName, unitType in eventUnitTypes)
    if (allSpecialEvents.get().findvalue(@(e) e.eventName == eventName) != null)
      res.append(unitType)
  return res
})

let isFitSeasonRewardsRequirements = Computed(function() {
  let { unlocks = [] } = curSeasons.get()?["season"]
  if (unlocks.len() == 0)
    return true

  foreach (r in unlocks) {
    if (r.campaignLevel == 0 && r.unitMRank == 0)
      return true

    if (r.campaignLevel > 0)
      foreach (camp in campaignsList.get())
        if ((campaignsLevelInfo.get()?[camp].level ?? 0) >= r.campaignLevel)
          return true

    if (r.unitMRank > 0) {
      foreach (k, _ in servProfile.get()?.units ?? {})
        if ((serverConfigs.get()?.allUnits[k]?.mRank ?? 0) >= r.unitMRank)
          return true
    }

  }
  return false
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
  eventSeasonIdx
  eventSeason
  isEventActive
  unitTypesByEvent

  unseenLootboxes
  unseenLootboxesShowOnce

  bestCampLevel

  MAIN_EVENT_ID
  specialEvents
  specialEventsWithTree
  allSpecialEvents
  specialEventsOrdered
  specialEventsLootboxesState
  getSpecialEventName
  curEventLootboxes
  curEventCurrencies
  specialEventGamercardItems
  isFitSeasonRewardsRequirements

  curEventBg
  getEventPresentationId
}
