from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { getCampaignPkgsForOnlineBattle } = require("%appGlobals/updater/campaignAddons.nut")
let { allGameModes } = require("%appGlobals/gameModes/gameModes.nut")
let { newbieGameModesConfig, prepareStatsForNewbieConfig, isNewbieMode, isNewbieModeSingle
} = require("%appGlobals/gameModes/newbieGameModesConfig.nut")
let { curCampaign, sharedStatsByCampaign } = require("%appGlobals/pServer/campaign.nut")
let { mkHasAllPackages } = require("%appGlobals/updater/hasPackage.nut")

let forceNewbieModeIdx = mkWatched(persist, "forceNewbieModeIdx", -1)
let curCampaignNewbiePkgList = Computed(@() getCampaignPkgsForOnlineBattle(curCampaign.value, 1))
let hasCurCampaignNewbiePkg = mkHasAllPackages(curCampaignNewbiePkgList, true)

let curNewbieMode = Computed(function() {
  let list = newbieGameModesConfig?[curCampaign.value]
  if (list == null)
    return null

  let stats = prepareStatsForNewbieConfig(sharedStatsByCampaign.value)
    .__update({ hasPkg = hasCurCampaignNewbiePkg.value })
  local res = null
  if (forceNewbieModeIdx.value >= 0) {
    let gmName = list?[forceNewbieModeIdx.value].gmName
    res = gmName == null ? null : allGameModes.value.findvalue(@(gm) gm?.name == gmName)
  }
  else
    foreach (cfg in list)
      if (cfg.isFit(stats)) {
        res = allGameModes.value.findvalue(@(gm) gm?.name == cfg.gmName)
        if (res != null)
          break
      }
  return res
})

let randomBattleMode = Computed(function() {
  if (curNewbieMode.value != null)
    return curNewbieMode.value
  if (allGameModes.value.len() == 0)
    return null

  local modes = allGameModes.value.filter(@(m) m?.displayType == "random_battle")
  if (modes.len() == 0) //in case of disappear all random_battles modes
    modes = allGameModes.value
  let campaign = curCampaign.value
  return modes.findvalue(@(m) m?.campaign == campaign)
    ?? modes.findvalue(@(_) true)
})

let benchmarkGameModes = Computed(@() allGameModes.value.filter(@(m) m?.displayType != "random_battle"
  && m.name.indexof("benchmark") != null))

let debugModes = Computed(@() allGameModes.value.filter(@(m, id) m?.displayType != "random_battle"
  && id not in benchmarkGameModes.value))

register_command(
  @() log("curRandomBattleModeName = ", randomBattleMode.value?.name)
  "debug.getCurRandomBattleModeName")
register_command(
  function(idx) {
    forceNewbieModeIdx(idx)
    log("curRandomBattleModeName = ", randomBattleMode.value?.name)
  }
  "debug.forceNewbieModeIdx")

return {
  allGameModes
  randomBattleMode
  isRandomBattleNewbie = Computed(@() isNewbieMode(randomBattleMode.value?.name))
  isRandomBattleNewbieSingle = Computed(@() isNewbieModeSingle(randomBattleMode.value?.name))
  debugModes
  benchmarkGameModes
  forceNewbieModeIdx
}
