from "%globalsDarg/darg_library.nut" import *
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")

let lootboxesPriority = [
  "event_small"
  "event_medium"
  "event_big"
].reduce(@(res, v, idx) res.__update({ [v] = idx + 1 }), {})

let sortLootboxes = @(a, b) (lootboxesPriority?[a.name] ?? 0) <=> (lootboxesPriority?[b.name] ?? 0)
  || a.name <=> b.name

// TODO: add real progress
let lootboxesCfg = {
  event_small = {
    name = "event_small"
    size = hdpxi(200)
    adRewardId = "advert_event"
  }
  event_medium = {
    name = "event_medium"
    hasGuaranteed = true
    stepsFinished = 1
    stepsTotal = 2
  }
  event_big = {
    name = "event_big"
    hasGuaranteed = true
    stepsFinished = 2
    stepsTotal = 3
  }
}

let eventLootboxesRaw = Computed(@() serverConfigs.value?.lootboxesCfg
  .filter(@(v) v?.meta.event)
  .map(@(v, key) v.__update(lootboxesCfg[key])))

let eventLootboxes = Computed(@() eventLootboxesRaw.value?.values().sort(sortLootboxes))

return {
  eventLootboxesRaw
  eventLootboxes
}
