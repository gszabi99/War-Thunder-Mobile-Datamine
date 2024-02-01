from "%globalsDarg/darg_library.nut" import *
let { WP, GOLD } = require("%appGlobals/currenciesState.nut")

let hasPrice = @(unit) unit.costWp > 0 || unit.costGold > 0
let applyDiscount = @(price, discount = 0.0) (price * (1.0 - discount) + 0.5).tointeger()

function getUnitAnyPrice(unit, isForLevelUp, unitDiscounts) {
  if (!hasPrice(unit))
    return null
  let currencyId = unit.costWp > 0 ? WP : GOLD
  let fullPrice = unit.costWp > 0 ? unit.costWp : unit.costGold
  let discount = isForLevelUp ? unit.levelUpDiscount : unitDiscounts?[unit.name].discount ?? 0.0
  let price = applyDiscount(fullPrice, discount)
  return { currencyId, price, fullPrice, discount }
}

let isUnitGloballyUnavailable = @(u) u.costGold <= 0 && u.costWp <= 0 && !u.isHidden

let sortUnits = @(a, b)
     a.rank <=> b.rank
  || a.mRank <=> b.mRank
  || isUnitGloballyUnavailable(a) <=> isUnitGloballyUnavailable(b)
  || a.unitType <=> b.unitType
  || a.unitClass <=> b.unitClass
  || a.isPremium <=> b.isPremium
  || a.name <=> b.name

let sortUnitsByPrice = @(a, b)
     a.costGold <=> b.costGold
  || a.costWp <=> b.costWp
  || sortUnits(a, b)

return {
  applyDiscount
  getUnitAnyPrice
  sortUnits
  sortUnitsByPrice
}
