from "%globalsDarg/darg_library.nut" import *
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")

let lootboxesPriority = [
  "event_small"
  "event_medium"
  "event_big"
].reduce(@(res, v, idx) res.__update({ [v] = idx + 1 }), {})

let sortLootboxes = @(a, b) (lootboxesPriority?[a.name] ?? 0) <=> (lootboxesPriority?[b.name] ?? 0)
  || a.name <=> b.name

let lootboxesCfg = {
  event_small = {
    adRewardId = "advert_event"
    sizeMul = 0.6
  }
  event_medium = {
    sizeMul = 0.8
  }
  event_big = {
    sizeMul = 0.9
  }
}

let eventLootboxesRaw = Computed(@() serverConfigs.value?.lootboxesCfg
  .filter(@(v) v?.meta.event)
  .map(@(v, key) v.__merge({ name = key }, lootboxesCfg?[key] ?? {}))
  ?? {})

let eventLootboxes = Computed(@() eventLootboxesRaw.value?.values().sort(sortLootboxes))

return {
  eventLootboxesRaw
  eventLootboxes
  lootboxesCfg
}
