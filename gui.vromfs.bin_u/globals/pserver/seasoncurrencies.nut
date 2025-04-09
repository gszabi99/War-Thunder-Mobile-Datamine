let { Computed } = require("frp")
let { isEqual } = require("%sqstd/underscore.nut")
let { serverConfigs } = require("servConfigs.nut")
let { curSeasons } = require("profileSeasons.nut")
let { balance, orderByCurrency } = require("%appGlobals/currenciesState.nut")
let { getBaseCurrency } = require("%appGlobals/config/currencyPresentation.nut")

let currencySeasons = Computed(@() serverConfigs.get()?.currencySeasons ?? {})

let currencyToFullId = Computed(@() currencySeasons.get()
  .map(function(cs, cId) {
    let seasonIdx = curSeasons.get()?[cs.season].idx ?? 0
    return $"{cId}_{seasonIdx}"
  }))

let prevIfEqual = @(prev, cur) isEqual(cur, prev) ? prev : cur

let seasonBalance = Computed(function(prev) {
  let res = {}
  let cSeasons = currencySeasons.get()
  foreach(fullId, v in balance.get()) {
    let baseId = getBaseCurrency(fullId)
    if (baseId not in cSeasons && baseId == fullId)
      res[fullId] <- v
  }

  foreach(fullId in currencyToFullId.get())
    res[fullId] <- balance.get()?[fullId] ?? 0

  return prevIfEqual(prev, res)
})

let sortByCurrencyId = @(a, b)
  (orderByCurrency?[getBaseCurrency(a)] ?? -1) <=> (orderByCurrency?[getBaseCurrency(b)] ?? -1)

let mkCurrencyFullId = @(id) Computed(@() currencyToFullId.get()?[id] ?? id)

return {
  currencyToFullId
  mkCurrencyFullId
  seasonBalance

  getBaseCurrency
  sortByCurrencyId
}