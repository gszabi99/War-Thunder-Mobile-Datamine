from "%globalsDarg/darg_library.nut" import *
let { orderByCurrency } = require("%appGlobals/currenciesState.nut")
let { orderByItems } = require("%appGlobals/itemsState.nut")

let rTypesPriority = [
  "unknown"
  "unitUpgrade"
  "unit"
  "currency"
  "premium"
  "decorator"
  "item"
  "lootbox"
].reduce(@(res, v, idx) res.__update({ [v] = idx + 1 }), {})

let sortRewardsViewInfo = @(a, b) (rTypesPriority?[a.rType] ?? 0) <=> (rTypesPriority?[b.rType] ?? 0)
  || (a.rType != "currency" ? 0 : ((orderByCurrency?[a.id] ?? 0) <=> (orderByCurrency?[b.id] ?? 0)))
  || (a.rType != "item" ? 0 : ((orderByItems?[a.id] ?? 0) <=> (orderByItems?[b.id] ?? 0)))
  || b.count <=> a.count
  || a.id <=> b.id

let function getRewardsViewInfo(data, multiply = 1) {
  let res = []
  if (!data)
    return res
  let { gold = 0, wp = 0, premiumDays = 0, items = {}, lootboxes = {},
    decorators = [], unitUpgrades = [], units = [] } = data
  if (unitUpgrades.len() != 0)
    foreach (id in unitUpgrades)
      res.append({ id, rType = "unitUpgrade", slots = 2, count = 0 })
  if (units.len() != 0)
    foreach (id in units)
      if (!unitUpgrades.contains(id))
        res.append({ id, rType = "unit", slots = 2, count = 0 })
  if (gold > 0)
    res.append({ id = "gold", rType = "currency", slots = 1, count = gold * multiply })
  if (wp > 0)
    res.append({ id = "wp", rType = "currency", slots = 1, count = wp * multiply })
  if (premiumDays > 0)
    res.append({ id = "premium", rType = "premium", slots = 1, count = premiumDays * multiply })
  if (decorators.len() != 0)
    foreach (id in decorators)
      res.append({ id, rType = "decorator", slots = 1, count = 0 })
  if (items.len() != 0)
    foreach (id, count in items)
      res.append({ id, rType = "item", slots = 1, count = count * multiply })
  if (lootboxes.len() != 0)
    foreach (id, count in lootboxes)
      res.append({ id, rType = "lootbox", slots = 1, count = count * multiply })
  return res
}

return {
  getRewardsViewInfo
  sortRewardsViewInfo
}
