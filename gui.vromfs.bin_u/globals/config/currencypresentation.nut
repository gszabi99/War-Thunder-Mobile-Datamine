from "%globalScripts/logs.nut" import *
let { max } = require("math")
let { loc } = require("dagor.localize")
let { memoize } = require("%sqstd/functools.nut")
let { isStringInteger } = require("%sqstd/string.nut")

let iconsScale = {
  ship_tool_kit = 1.6
  ship_smoke_screen_system_mod = 1.5
  tank_tool_kit_expendable = 1.5
  tank_medical_kit = 1.5
  tank_extinguisher = 1.6
  spare = 1.8
  firework_kit = 1.4
  warbond = 1.4
  eventKey = 1.2
  nybond = 1.4
  valentinebond = 1.4
  candybond = 1.0
  lollipopbond = 1.0
  chocolatebond = 1.0
  lunarbond = 1.4
  aprilbond = 1.4
  aprilintel = 1.3
  anniversarybond = 1.4
  halloweenbond = 1.4
  blackfridaybond = 1.4
  hotmaybond = 1.4
  independencebond = 1.4
  ircm_kit = 1.4
  platinum = 1.2
}
let maxIconsScale = iconsScale.reduce(@(a, b) max(a, b))

let icons = {
  
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
  aprilbond = "ui/gameuiskin#warbond_icon_aprilbond_2026.avif"
  aprilintel = "ui/gameuiskin#warbond_icon_aprilintel_2026.avif"
  aprilMapPiece = "ui/gameuiskin#warbond_icon_aprilmappiece.svg"
  aprilDoublon = "ui/gameuiskin#warbond_icon_aprildoublon.svg"
  anniversarybond = "ui/gameuiskin#warbond_icon_anniversarybond_2025.avif"
  halloweenbond = "ui/gameuiskin#warbond_icon_halloweenbond_2025.avif"
  valentinebond = "ui/gameuiskin#warbond_icon_valentinebond_2026.avif"
  candybond = "ui/gameuiskin#warbond_icon_candybond_2026.avif"
  lollipopbond = "ui/gameuiskin#warbond_icon_lollipopbond_2026.avif"
  chocolatebond = "ui/gameuiskin#warbond_icon_chocolatebond_2026.avif"
  blackfridaybond = "ui/gameuiskin#warbond_icon_black_friday_2024.avif"
  hotmaybond = "ui/gameuiskin#warbond_icon_hotmaybond.avif"
  independencebond = "ui/gameuiskin#warbond_icon_independencebond.avif"
  
  ship_tool_kit = "ui/gameuiskin#shop_consumables_repair_gamercard.avif"
  ship_smoke_screen_system_mod = "ui/gameuiskin#shop_consumables_smoke_gamercard.avif"
  tank_tool_kit_expendable = "ui/gameuiskin#shop_consumables_tank_repair_gamercard.avif"
  tank_medical_kit = "ui/gameuiskin#shop_consumables_tank_medical_kit_gamercard.avif"
  tank_extinguisher = "ui/gameuiskin#shop_consumables_tank_extinguisher_gamercard.avif"
  spare = "ui/gameuiskin#shop_consumables_tank_cards_gamercard.avif"
  firework_kit = "ui/gameuiskin#shop_fireworks_gamercard.avif"
  ircm_kit = "ui/gameuiskin#icon_ircm.avif"
}

let bigIcons = {
  gold = "ui/gameuiskin#shop_eagles_02.avif"
  wp = "ui/gameuiskin#shop_lions_02.avif"
  nybond = "ui/gameuiskin#warbond_goods_christmas_01.avif"
  lunarbond = "ui/gameuiskin#lunarbond_goods_01.avif"
  aprilbond = "ui/gameuiskin#aprilbond_goods_2026_01.avif"
  aprilintel = "ui/gameuiskin#aprilintel_goods_2026_01.avif"
  aprilMapPiece = "ui/gameuiskin#aprilmappiece_goods_01.avif"
  aprilDoublon = "ui/gameuiskin#aprildoublon_goods_01.avif"
  blackfridaybond = "ui/gameuiskin#blackfridaybond_goods_01.avif"
  hotmaybond = "ui/gameuiskin#hotmaybond_goods_01.avif"
  independencebond = "ui/gameuiskin#independencebond_goods_01.avif"
  anniversarybond = "ui/gameuiskin#anniversarybond_goods_2025_01.avif"
  halloweenbond = "ui/gameuiskin#halloweenbond_goods_2025_01.avif"
  valentinebond = "ui/gameuiskin#valentinebond_goods_2026_01.avif"
  candybond = "ui/gameuiskin#candybond_goods_2026_01.avif"
  lollipopbond = "ui/gameuiskin#lollipopbond_goods_2026_01.avif"
  chocolatebond = "ui/gameuiskin#chocolatebond_goods_2026_01.avif"
}

let placeholder = "ui/gameuiskin#icon_primary_attention.svg"

let seasonIcons = {
  warbond = @(season) $"ui/gameuiskin#warbond_icon_season_{season}.avif"
  eventKey = @(season) $"ui/gameuiskin#key_icon_season_{season}.avif"
}

let currencyIconsColor = {
  playerExp = 0xFFFFB70B
  researchUnitExp = 0xFFFFB70B
  unitExp = 0xFF7FAEFF
  slotExp = 0xFF65BC82
}

let currencyConvertInfo = {
  [""] = "events/buyCurrency/desc/convertsToTrophies",
  gold = "events/buyCurrency/desc/convertsToGold",
}

let getBaseCurrency = memoize(function getBaseCurrencyImpl(fullId) {
  let list = fullId.split("_")
  if (list.len() < 2)
    return fullId
  return !isStringInteger(list.top()) ? fullId
    : "-".join(list.slice(0, list.len() - 1))
})

let getSeasonStr = memoize(function getSeasonStrImpl(fullId) {
  let list = fullId.split("_")
  if (list.len() < 2)
    return ""
  return list.top()
})

let getIconSize = @(currencyId, size) (size * (iconsScale?[getBaseCurrency(currencyId)] ?? 1) + 0.5).tointeger()

function getCurrencyImage(id) {
  if (id in icons)
    return icons[id]
  let baseId = getBaseCurrency(id)
  return baseId in seasonIcons ? seasonIcons[baseId](getSeasonStr(id))
    : (icons?[baseId] ?? placeholder)
}
let getCurrencyFallback = @(id) icons?[getBaseCurrency(id)] ?? placeholder

let getCurrencyBigIcon = @(id) id in bigIcons ? bigIcons[id]
  : getBaseCurrency(id) in bigIcons ? bigIcons[getBaseCurrency(id)]
  : getCurrencyImage(id)
let getCurrencyConvertInfo = @(targetCurrency) loc(currencyConvertInfo?[targetCurrency] ?? currencyConvertInfo?[""])

return {
  getIconSize
  currencyIconsColor
  getCurrencyImage
  getCurrencyFallback
  getCurrencyBigIcon
  maxIconsScale
  getCurrencyConvertInfo
  getBaseCurrency
  getSeasonStr
}