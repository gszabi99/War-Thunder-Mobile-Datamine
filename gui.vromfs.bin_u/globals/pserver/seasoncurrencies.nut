let { Computed } = require("frp")
let { serverConfigs } = require("servConfigs.nut")
let { curSeasons } = require("profileSeasons.nut")
let { orderByCurrency } = require("%appGlobals/currenciesState.nut")
let { getBaseCurrency } = require("%appGlobals/config/currencyPresentation.nut")

let currencySeasons = Computed(@() serverConfigs.get()?.currencySeasons ?? {})

let currencyToFullId = Computed(@() currencySeasons.get()
  .map(function(cs, cId) {
    let seasonIdx = curSeasons.get()?[cs.season].idx ?? 0
    return $"{cId}_{seasonIdx}"
  }))

let currencyToFullIdOnlyActive = Computed(@() currencySeasons.get()
  .map(function(cs, cId) {
    let { isActive = false, idx = 0 } = curSeasons.get()?[cs.season]
    return isActive ? $"{cId}_{idx}" : cId
  }))

let sortByCurrencyId = @(a, b)
  (orderByCurrency?[getBaseCurrency(a)] ?? -1) <=> (orderByCurrency?[getBaseCurrency(b)] ?? -1)

let mkCurrencyFullId = @(id) Computed(@() currencyToFullId.get()?[id] ?? id)

return {
  currencyToFullId
  currencyToFullIdOnlyActive
  mkCurrencyFullId

  getBaseCurrency
  sortByCurrencyId
  currencySeasons
}