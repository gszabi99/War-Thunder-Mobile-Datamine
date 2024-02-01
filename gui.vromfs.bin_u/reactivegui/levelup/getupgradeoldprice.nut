from "%globalsDarg/darg_library.nut" import *
let { round_by_value } = require("%sqstd/math.nut")

function getUpgradeOldPrice(unitRank, allUnits) {
  let avgUpgradePrice = {}

  foreach (unit in allUnits) {
    if (!(unit.rank in avgUpgradePrice))
      avgUpgradePrice[unit.rank] <- []
    if (unit.costWp)
      avgUpgradePrice[unit.rank].append(unit.costWp)
  }

  foreach (rank, values in avgUpgradePrice) {
    if (values.len() > 0)
      avgUpgradePrice[rank] = values.reduce(@(p, c) p + c) / values.len()
    else
      avgUpgradePrice[rank] = null
  }

  if (!(unitRank in avgUpgradePrice))
    return null

  local avgPrice = avgUpgradePrice[unitRank] +
    (avgUpgradePrice?[unitRank + 1] ?? avgUpgradePrice[unitRank]) * 0.5 +
    (avgUpgradePrice?[unitRank + 2] ?? avgUpgradePrice[unitRank]) * 0.5

  return round_by_value(((avgPrice / 24000 + 3) * 120), 10)
}

return getUpgradeOldPrice