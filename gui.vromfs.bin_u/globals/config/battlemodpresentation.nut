let { getUnitTagsCfg } = require("%appGlobals/unitTags.nut")

let mkUnitData = @(id) {
  name = id
  unitType = getUnitTagsCfg(id).unitType
  isPremium = false
  isHidden = true
}

let april2024Mods = ["pony_fighter", "pony_minigun_fighter", "pony_rocket_fighter", "pony_jet_fighter", "pony_assault", "pony_bomber"]
  .reduce(@(res, id) res.$rawset(id, {
    id,
    viewType = "eventUnit"
    eventId = "event_april_2024"
    unitCtor = @() mkUnitData(id)
  }),
{})

return { getBattleModPresentation = @(id) april2024Mods?[id] ?? {}}