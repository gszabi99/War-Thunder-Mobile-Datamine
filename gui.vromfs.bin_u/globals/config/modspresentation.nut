let catIcons = {
  shipMaintanance = "hud_consumable_repair.svg"
  shipProtection = "unit_ship.svg"
  shipWeapons = "hud_ship_weapons.svg"
  shipTorpedoes = "hud_torpedo.svg"
  art_support = "hud_artillery_fire.svg"
  belts = "hud_aircraft_machine_gun.svg"
  smoke = "hud_smoke_grenade_tank.svg"
}

let catIconDefault = "modify.svg"

let getCatIcon = @(cat) $"ui/gameuiskin#{cat in catIcons ? catIcons?[cat] : catIconDefault}:O:P"

return getCatIcon
