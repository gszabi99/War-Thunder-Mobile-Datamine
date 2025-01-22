from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { isEqual } = require("%sqstd/underscore.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { isServerTimeValid, getServerTime } = require("%appGlobals/userstats/serverTime.nut")
let { userstatStats } = require("%rGui/unlocks/userstat.nut")


let MAIN_EVENT_ID = "main"
let L_ACTIVE = 0
let L_NOT_STARTED = 1
let L_FINISHED = 2
let sortLootboxes = @(a, b) (a?.meta.event ?? "") <=> (b?.meta.event ?? "") || a.name <=> b.name
let inactiveLootboxes = Watched({})

function getState(timeRange, time) {
  if (timeRange == null)
    return L_ACTIVE
  let { start = 0, end = 0 } = timeRange
  return start > time ? L_NOT_STARTED
    : end > 0 && end <= time ? L_FINISHED
    : L_ACTIVE
}

function updateInactiveLootboxes() {
  if (!isServerTimeValid.get()) {
    inactiveLootboxes.set({})
    return
  }

  let time = getServerTime()
  let { lootboxesCfg = {} } = serverConfigs.get()
  let inactive = {}
  local timeToUpdate = 0
  foreach(id, l in lootboxesCfg) {
    let state = getState(l.timeRange, time)
    if (state == L_ACTIVE)
      continue
    inactive[id] <- state
    let { start = 0, end = 0 } = l.timeRange
    let nextTime = start - time > 0 ? start - time : end - time
    if (nextTime > 0)
      timeToUpdate = timeToUpdate == 0 ? nextTime : min(timeToUpdate, nextTime)
  }

  if (!isEqual(inactiveLootboxes.get(), inactive))
    inactiveLootboxes.set(inactive)
  if (timeToUpdate <= 0)
    clearTimer(updateInactiveLootboxes)
  else
    resetTimeout(timeToUpdate, updateInactiveLootboxes)
}

inactiveLootboxes.whiteListMutatorClosure(updateInactiveLootboxes)
serverConfigs.subscribe(@(_) updateInactiveLootboxes())
isServerTimeValid.subscribe(@(_) updateInactiveLootboxes())
updateInactiveLootboxes()

function orderLootboxesBySlot(lList) {
  let res = []
  let lootboxesBySlot = {}
  foreach (lootbox in lList) {
    let slot = lootbox?.meta.event_slot ?? ""
    if (slot == "") {
      res.append(lootbox)
      continue
    }
    if (slot not in lootboxesBySlot)
      lootboxesBySlot[slot] <- []
    lootboxesBySlot[slot].append(lootbox)
  }
  foreach (list in lootboxesBySlot) {
    list.sort(@(a, b) (b?.timeRange.start ?? 0) <=> (a?.timeRange.start ?? 0))
    res.append(list[0])
  }
  return res.sort(sortLootboxes)
}

function isFitCurSeason(timeRange, seasonName, userstatStatsV) {
  let { start = 0, end = 0 } = timeRange
  return start < (userstatStatsV?.stats[seasonName]["$endsAt"] ?? 0)
    && (end <= 0 || end > (userstatStatsV?.stats[seasonName]["$startedAt"] ?? 0))
}

let eventLootboxesRaw = Computed(@() serverConfigs.value?.lootboxesCfg
  .filter(function(v, id) {
    if (inactiveLootboxes.get()?[id] == L_FINISHED)
      return false
    let { event_id = MAIN_EVENT_ID, event_slot = null } = v?.meta
    return event_slot != null
      && (v?.meta.campaign == null || curCampaign.value == v?.meta.campaign)
      && (event_id != MAIN_EVENT_ID || isFitCurSeason(v?.timeRange, "season", userstatStats.get()))
  })
    ?? {})

let eventLootboxes = Computed(@() orderLootboxesBySlot(eventLootboxesRaw.value))

return {
  eventLootboxesRaw
  eventLootboxes
  orderLootboxesBySlot
}
