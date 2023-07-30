//checked for explicitness
#no-root-fallback
#explicit-this

let { abs } = require("%sqstd/math.nut")

let genBotCommonStats = @(name, unitName, unitCfg, defLevel) {
  level = unitCfg?.rank ?? defLevel
  unit = { level = abs((name.hash() + unitName.hash()) % 25) + 1 }
}

return {
  genBotCommonStats
}
