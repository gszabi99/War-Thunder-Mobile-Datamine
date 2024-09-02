let { abs } = require("%sqstd/math.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")

function genBotCommonStats(name, unitName, unitCfg, defLevel) {
  let playerHash = name.hash()
  let unitHash = unitName.hash()
  let avatars = serverConfigs.value?.allDecorators.filter(@(dec) dec.dType == "avatar")
  return {
    level = unitCfg?.rank ?? defLevel
    mainUnitName = unitName
    units = {
      [unitName] = {
        level = abs((playerHash + unitHash) % 25) + 1
        unitClass = unitCfg?.unitClass ?? ""
        country = unitCfg?.country ?? ""
        mRank = unitCfg?.mRank
        isCollectible = unitCfg?.isCollectible ?? false
        isPremium = unitCfg?.isPremium ?? false
      }
    }
    decorators = {
      avatar = avatars?.keys()[(playerHash) % (avatars?.len() ?? 1)]
    }
  }
}

return {
  genBotCommonStats
}
