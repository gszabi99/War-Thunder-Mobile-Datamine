let { max } = require("math")
let { loc } = require("dagor.localize")

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
  lunarbond = 1.4
  aprilbond = 1.4
  anniversarybond = 1.4
  halloweenbond = 1.4
  blackfridaybond = 1.4
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
  slotExp = "ui/gameuiskin#experience_icon.svg"
  playerExp = "ui/gameuiskin#experience_icon.svg"
  warbond = "ui/gameuiskin#warbond_icon.avif"
  eventKey = "ui/gameuiskin#key_icon.avif"
  nybond = "ui/gameuiskin#warbond_christmas_icon.avif"
  lunarbond = "ui/gameuiskin#warbond_icon_lunar_ny.avif"
  aprilbond = "ui/gameuiskin#warbond_icon_april.avif"
  anniversarybond = "ui/gameuiskin#warbond_icon_anniversarybond.avif"
  halloweenbond = "ui/gameuiskin#warbond_icon_halloween_2024.avif"
  blackfridaybond = "ui/gameuiskin#warbond_icon_black_friday_2024.avif"
  // Consumables
  ship_tool_kit = "ui/gameuiskin#shop_consumables_repair_gamercard.avif"
  ship_smoke_screen_system_mod = "ui/gameuiskin#shop_consumables_smoke_gamercard.avif"
  tank_tool_kit_expendable = "ui/gameuiskin#shop_consumables_tank_repair_gamercard.avif"
  tank_extinguisher = "ui/gameuiskin#shop_consumables_tank_extinguisher_gamercard.avif"
  spare = "ui/gameuiskin#shop_consumables_tank_cards_gamercard.avif"
  firework_kit = "ui/gameuiskin#icon_fireworks.avif"
  ircm_kit = "ui/gameuiskin#icon_ircm.avif"
}

let bigIcons = {
  gold = "ui/gameuiskin#shop_eagles_02.avif"
  wp = "ui/gameuiskin#shop_lions_02.avif"
  nybond = "ui/gameuiskin#warbond_goods_christmas_01.avif"
  lunarbond = "ui/gameuiskin#lunarbond_goods_01.avif"
  aprilbond = "ui/gameuiskin#warbond_april_01.avif"
  halloweenbond = "ui/gameuiskin#halloweenbond_goods_01.avif"
  blackfridaybond = "ui/gameuiskin#blackfridaybond_goods_01.avif"
}

let placeholder = "ui/gameuiskin#icon_primary_attention.svg"

let seasonIcons = {
  warbond = @(season) $"ui/gameuiskin#warbond_icon_season_{season}.avif"
  eventKey = @(season) $"ui/gameuiskin#key_icon_season_{season}.avif"
}

let currencyIconsColor = {
  playerExp = 0xFFFFB70B
  unitExp = 0xFF7EE2FF
  slotExp = 0xFF009900
}

let currencyEventDescriptions = {
  blackfridaybond = "events/buyCurrency/desc/blackfridaybond"
}

let getCommonIcon = @(id) icons?[id] ?? placeholder
let getCurrencyImage = @(id, season = 0) season <= 0 || id not in seasonIcons
  ? getCommonIcon(id)
  : seasonIcons?[id](season)
let getCurrencyFallback = @(id, season = 0) season <= 0 || id not in seasonIcons
  ? placeholder
  : getCommonIcon(id)
let getCurrencyBigIcon = @(id) id in bigIcons
  ? bigIcons[id]
  : getCommonIcon(id)
let getCurrencyDescription = @(id) loc(currencyEventDescriptions?[id] ?? "events/buyCurrency/desc")

return {
  getIconSize
  currencyIconsColor
  getCurrencyImage
  getCurrencyFallback
  getCurrencyBigIcon
  maxIconsScale
  getCurrencyDescription
}