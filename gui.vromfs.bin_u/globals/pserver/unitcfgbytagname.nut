function getUnitCfgByTagName(tagName, serverConfigsV, campaign) {
  let unitOrig = serverConfigsV?.allUnits[tagName]
  if (unitOrig != null && unitOrig.campaign == campaign)
    return unitOrig
  let unitNew = serverConfigsV?.allUnits[$"{tagName}_nc"]
  return unitNew ?? unitOrig
}

return {
  getUnitCfgByTagName
}