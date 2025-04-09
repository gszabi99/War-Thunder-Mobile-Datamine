let { getUnitTagsCfg } = require("%appGlobals/unitTags.nut")

let mkUnitData = @(id) {
  name = id
  unitType = getUnitTagsCfg(id).unitType
  isPremium = false
  isHidden = true
}

let eventUnitMods = ["pony_fighter", "pony_minigun_fighter", "pony_rocket_fighter", "pony_jet_fighter", "pony_assault", "pony_bomber"]
  .reduce(@(res, id) res.$rawset(id, {
    id,
    viewType = "eventUnit"
    eventId = "event_april_2024"
    unitCtor = @() mkUnitData(id)
  }),
{})


let mkCommonMod = @(id, locId, icon = null) { id, viewType = "common", locId, icon }

let commonMods = {
  air_cbt_access = { locId = "event_cbt/access", icon = "ui/gameuiskin#unit_air.svg" }
}.map(@(cfg, id) mkCommonMod(id, cfg.locId, cfg?.icon))

let allMods = eventUnitMods.__merge(
  commonMods
)

return { getBattleModPresentation = @(id) allMods?[id] ?? mkCommonMod(id, id) } //-param-pos
