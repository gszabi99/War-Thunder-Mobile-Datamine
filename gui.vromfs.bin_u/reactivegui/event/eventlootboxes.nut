from "%globalsDarg/darg_library.nut" import *
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { userstatStats } = require("%rGui/unlocks/userstat.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")


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

let eventLootboxesRaw = Computed(@() serverConfigs.value?.lootboxesCfg
  .filter(function(v) {
    let { start = 0, end = 0 } = v?.timeRange
    return v?.meta.event_slot
      && start < (userstatStats.get()?.stats.season["$endsAt"] ?? 0)
      && (end <= 0 || end > (userstatStats.get()?.stats.season["$startedAt"] ?? 0))
      && (v?.meta.campaign == null || curCampaign.value == v?.meta.campaign)
  })
    ?? {})

let eventLootboxes = Computed(@() orderLootboxesBySlot(eventLootboxesRaw.value))

return {
  eventLootboxesRaw
  eventLootboxes
  orderLootboxesBySlot
}
