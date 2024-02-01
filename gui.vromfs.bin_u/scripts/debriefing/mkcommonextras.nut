from "%scripts/dagui_library.nut" import *
let { allUnitsCfg } = require("%appGlobals/pServer/profile.nut")

function mkCommonExtras(battleResult) {
  let res = {}
  if ((battleResult?.reward.playerExp.totalExp ?? 0) > 0) {
    let nextLevel = (battleResult?.player.level ?? 0) + 1
    let nextLevelUnits = allUnitsCfg.get().filter(@(u) u.rank == nextLevel && u.costWp > 0)
    res.__update({ nextLevelUnits })
  }
  return res
}

return mkCommonExtras
