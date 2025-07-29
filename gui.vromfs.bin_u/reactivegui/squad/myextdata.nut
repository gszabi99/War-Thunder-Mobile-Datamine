from "%globalsDarg/darg_library.nut" import *
let { isEqual } = require("%sqstd/underscore.nut")
let { bindSquadROVar } = require("squadManager.nut")
let { myQueueToken } = require("%appGlobals/queueState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { curSlots } = require("%appGlobals/pServer/slots.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { myClustersRTT, queueDataCheckTime } = require("%appGlobals/squadState.nut")
let { readyCheckTime } = require("readyCheck.nut")
let { mRankCheckTime } = require("mRankCheck.nut")
let { hasAddons } = require("%appGlobals/updater/addonsState.nut")
let { activeBattleMods } = require("%appGlobals/pServer/battleMods.nut")
let { chosenDecoratorsHash } = require("%rGui/decorators/decoratorState.nut")

let curUnits = keepref(Computed(function() {
  let { allUnits = null, campaignCfg = {} } = serverConfigs.get()
  let { units = null } = servProfile.value
  if (units == null || allUnits == null)
    return null
  let res = {}
  foreach(u in units) {
    if (!u?.isCurrent)
      continue
    let campaign = allUnits?[u.name].campaign
    if (campaign != null && campaign not in res)
      res[campaign] <- [u.name]
  }
  foreach(campaign, cfg in campaignCfg)
    if (cfg.totalSlots > 0)
      res[campaign] <- curSlots.get()
        .filter(@(s) s.name != "")
        .map(@(s) s.name)
        ?? []
  return res
}))

let missingAddons = keepref(Computed(function(prev) {
  let res = hasAddons.get().filter(@(v) !v)
    .keys()
    .sort()
  return isEqual(prev, res) ? prev : res
}))

let myBattleMods = keepref(Computed(function(prev) {
  let res = activeBattleMods.get().filter(@(v) v)
    .keys()
    .sort()
  return isEqual(prev, res) ? prev : res
}))

bindSquadROVar("campaign", curCampaign)
bindSquadROVar("units", curUnits)
bindSquadROVar("missingAddons", missingAddons)
bindSquadROVar("queueToken", myQueueToken)
bindSquadROVar("inBattle", isInBattle)
bindSquadROVar("readyCheckTime", readyCheckTime)
bindSquadROVar("mRankCheckTime", mRankCheckTime)
bindSquadROVar("queueDataCheckTime", queueDataCheckTime)
bindSquadROVar("clustersRTT", myClustersRTT)
bindSquadROVar("battleMods", myBattleMods)
bindSquadROVar("chosenDecoratorsHash", chosenDecoratorsHash)
