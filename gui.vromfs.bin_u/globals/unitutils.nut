//checked for explicitness
#no-root-fallback
#explicit-this

let { WP, GOLD } = require("%appGlobals/currenciesState.nut")

let hasPrice = @(unit) unit.costWp > 0 || unit.costGold > 0
let applyDiscount = @(price, discount = 0.0) (price * (1.0 - discount) + 0.5).tointeger()

let function getUnitAnyPrice(unit, isForLevelUp) {
  if (!hasPrice(unit))
    return null
  let currencyId = unit.costWp > 0 ? WP : GOLD
  let fullPrice = unit.costWp > 0 ? unit.costWp : unit.costGold
  let discount = isForLevelUp ? unit.levelUpDiscount : 0.0
  let price = applyDiscount(fullPrice, discount)
  return { currencyId, price, fullPrice, discount }
}

let sortUnits = @(a, b)
     a.rank <=> b.rank
  || a.mRank <=> b.mRank
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
