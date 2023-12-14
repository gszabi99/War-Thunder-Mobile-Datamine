let { abs } = require("%sqstd/math.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")

function genBotCommonStats(name, unitName, unitCfg, defLevel) {
  let hashVal = name.hash() + unitName.hash()
  let avatars = serverConfigs.value?.allDecorators.filter(@(dec) dec.dType == "avatar")
  return {
    level = unitCfg?.rank ?? defLevel
    unit = {
      level = abs((hashVal) % 25) + 1
      unitClass = unitCfg?.unitClass ?? ""
      mRank = unitCfg?.mRank
    }
    decorators = {
      avatar = avatars?.keys()[(hashVal) % (avatars?.len() ?? 1)]
    }
  }
}

return {
  genBotCommonStats
}
