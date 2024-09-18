let chooseBestUnit = @(list, allUnits)
  list.reduce(@(res, name) (allUnits?[res].mRank ?? 0) >= (allUnits?[name].mRank ?? 0) ? res : name)

function getBestUnitByGoods(goods, sConfigs) {
  if (goods?.meta.previewUnit)
    return sConfigs?.allUnits[goods?.meta.previewUnit]
  if (goods == null)
    return null
  let { allUnits = null } = sConfigs
  local unit = sConfigs?.allUnits[chooseBestUnit(goods.unitUpgrades, allUnits)]
  if (unit != null)
    return unit.__merge({ isUpgraded = true }, sConfigs?.gameProfile.upgradeUnitBonus ?? {})
  unit = sConfigs?.allUnits[chooseBestUnit(goods.units, allUnits)]
  if (unit != null)
    return unit

  let unitName = goods.blueprints
    .reduce(@(res, _, name) (allUnits?[res].mRank ?? 0) >= (allUnits?[name].mRank ?? 0) ? res : name, null)
  return sConfigs?.allUnits[unitName]
}

return {
  getBestUnitByGoods
}