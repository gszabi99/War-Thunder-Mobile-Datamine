from "%globalsDarg/darg_library.nut" import *
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { userstatStats } = require("%rGui/unlocks/userstat.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")


let sortLootboxes = @(a, b) (a?.meta.event ?? "") <=> (b?.meta.event ?? "") || a.name <=> b.name

let eventLootboxesRaw = Computed(@() serverConfigs.value?.lootboxesCfg.filter(@(v) v?.meta.event) ?? {})

let eventLootboxes = Computed(function() {
  let res = []
  let lootboxesBySlot = {}
  foreach (lootbox in eventLootboxesRaw.value) {
    let slot = lootbox?.meta.event ?? ""
    let campaign = lootbox?.meta.campaign
    if (slot == "" || slot == "true") { //event == "true" is compatibility with pServer config version at 2023.11.10
      res.append(lootbox)
      continue
    }
    let { start = 0, end = 0 } = lootbox?.timeRange
    if ((campaign != null && curCampaign.value != campaign)
        || start > (userstatStats.value?.stats.season["$endsAt"] ?? 0)
        || (end > 0 && end < (userstatStats.value?.stats.season["$startedAt"] ?? 0)))
      continue
    if (slot not in lootboxesBySlot)
      lootboxesBySlot[slot] <- []
    lootboxesBySlot[slot].append(lootbox)
  }
  foreach (list in lootboxesBySlot) {
    list.sort(@(a, b) (a?.timeRange.start ?? 0) <=> (b?.timeRange.start ?? 0))
    res.append(list[0])
  }
  return res.sort(sortLootboxes)
})

return {
  eventLootboxesRaw
  eventLootboxes
}
