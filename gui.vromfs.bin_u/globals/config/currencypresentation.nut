let { max } = require("math")

let iconsScale = {
  ship_tool_kit = 1.6
  ship_smoke_screen_system_mod = 1.5
  tank_tool_kit_expendable = 1.5
  tank_extinguisher = 1.6
  spare = 1.8
  firework_kit = 1.4
  warbond = 1.4
  eventKey = 1.2
  nybond = 1.4
  aprilbond = 1.4
  anniversarybond = 1.4
  ircm_kit = 1.4
}
let maxIconsScale = iconsScale.reduce(@(a, b) max(a, b))

let getIconSize = @(currencyId, size) (size * (iconsScale?[currencyId] ?? 1) + 0.5).tointeger()

let icons = {
  // Currencies
  wp   = "ui/gameuiskin#currency_lions.svg"
  gold = "ui/gameuiskin#currency_eagles.svg"
  platinum = "ui/gameuiskin#currency_wolves.svg"
  unitExp = "ui/gameuiskin#experience_icon.svg"
  playerExp = "ui/gameuiskin#experience_icon.svg"
  warbond = "ui/gameuiskin#warbond_icon.avif"
  eventKey = "ui/gameuiskin#key_icon.avif"
  nybond = "ui/gameuiskin#warbond_christmas_icon.avif"
  aprilbond = "ui/gameuiskin#warbond_icon_april.avif"
  anniversarybond = "ui/gameuiskin#warbond_icon_anniversarybond.avif"
  // Consumables
  ship_tool_kit = "ui/gameuiskin#shop_consumables_repair_gamercard.avif"
  ship_smoke_screen_system_mod = "ui/gameuiskin#shop_consumables_smoke_gamercard.avif"
  tank_tool_kit_expendable = "ui/gameuiskin#shop_consumables_tank_repair_gamercard.avif"
  tank_extinguisher = "ui/gameuiskin#shop_consumables_tank_extinguisher_gamercard.avif"
  spare = "ui/gameuiskin#shop_consumables_tank_cards_gamercard.avif"
  firework_kit = "ui/gameuiskin#icon_fireworks.avif"
  ircm_kit = "ui/gameuiskin#icon_ircm.avif"
}

let placeholder = "ui/gameuiskin#icon_primary_attention.svg"

let seasonIcons = {
  warbond = @(season) $"ui/gameuiskin#warbond_icon_season_{season}.avif"
  eventKey = @(season) $"ui/gameuiskin#key_icon_season_{season}.avif"
}

let currencyIconsColor = {
  playerExp = 0xFFFFB70B
  unitExp = 0xFF7EE2FF
}

let getCommonIcon = @(id) icons?[id] ?? placeholder
let getCurrencyImage = @(id, season = 0) season <= 0 || id not in seasonIcons
  ? getCommonIcon(id)
  : seasonIcons?[id](season)
let getCurrencyFallback = @(id, season = 0) season <= 0 || id not in seasonIcons
  ? placeholder
  : getCommonIcon(id)

return {
  getIconSize
  currencyIconsColor
  getCurrencyImage
  getCurrencyFallback
  maxIconsScale
}