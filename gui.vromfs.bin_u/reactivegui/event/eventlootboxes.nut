from "%globalsDarg/darg_library.nut" import *
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { userstatStats } = require("%rGui/unlocks/userstat.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")

let MAIN_EVENT_ID = "main"
let sortLootboxes = @(a, b) (a?.meta.event ?? "") <=> (b?.meta.event ?? "") || a.name <=> b.name

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
  .filter(function(v) {
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
