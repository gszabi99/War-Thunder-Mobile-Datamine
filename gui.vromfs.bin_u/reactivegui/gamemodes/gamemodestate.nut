from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { register_command } = require("console")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { allGameModes } = require("%appGlobals/gameModes/gameModes.nut")
let { newbieGameModesConfig, isNewbieMode, isNewbieModeSingle
} = require("%appGlobals/gameModes/newbieGameModesConfig.nut")
let { curCampaign, abTests } = require("%appGlobals/pServer/campaign.nut")
let { battleUnitsMaxMRank } = require("%appGlobals/pServer/profile.nut")
let { registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { isInSquad } = require("%appGlobals/squadState.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let newbieModeStats = require("%rGui/gameModes/newbieModeStats.nut")


function findFitGameMode(list, gameModes, stats, maxMRank, abTestsV) {
  foreach (cfg in list)
    if (cfg.isFit(stats, maxMRank, abTestsV)) {
      let gameMode = gameModes.findvalue(@(gm) gm?.name == cfg.gmName)
      if (gameMode != null)
        return { gameMode, cfg }
    }
  return null
}

let isDebugABTest = hardPersistWatched("tutorialTankOnline.isDebugMode", false)
let curABTestOnlineTutorialMode = Computed(function() {
  let abTestStatus = abTests.get()?.tutorialTankOnline ?? "false"
  if (!((abTestStatus == "true") != isDebugABTest.get()))
    return null
  let { gameMode = null, cfg = null } = findFitGameMode(newbieGameModesConfig?[curCampaign.get()], allGameModes.get(),
    newbieModeStats.get(), battleUnitsMaxMRank.get(), abTests.get())
  return cfg?.abTest ? gameMode : null
})

let forceNewbieModeIdx = mkWatched(persist, "forceNewbieModeIdx", -1)

let curNewbieMode = Computed(function() {
  let gameModes = allGameModes.get()
  let forceIdx = forceNewbieModeIdx.get()
  let list = newbieGameModesConfig?[curCampaign.get()]
  return list == null ? null
    : forceIdx < 0 ? findFitGameMode(list, gameModes, newbieModeStats.get(), battleUnitsMaxMRank.get(), abTests.get())?.gameMode
    : list?[forceIdx].gmName == null ? null
    : gameModes.findvalue(@(gm) gm?.name == list[forceIdx].gmName)
})

let randomBattleModeCore = Computed(function() {
  if (allGameModes.get().len() == 0)
    return null

  local modes = allGameModes.get().filter(@(m) m?.displayType == "random_battle")
  if (modes.len() == 0) 
    modes = allGameModes.get()
  let campaign = curCampaign.get()
  let campaign2 = getCampaignPresentation(campaign).campaign
  return modes.findvalue(@(m) m?.campaign == campaign)
    ?? modes.findvalue(@(m) m?.campaign == campaign2)
    ?? modes.findvalue(@(_) true)
})

let randomBattleMode = Computed(function() {
  if (!isInSquad.get()) {
    if (curABTestOnlineTutorialMode.get() != null)
      return curABTestOnlineTutorialMode.get()
    if (curNewbieMode.get() != null)
      return curNewbieMode.get()
  }
  return randomBattleModeCore.get()
})

let benchmarkGameModes = Computed(@() allGameModes.get().filter(@(m) m?.displayType != "random_battle"
  && m.name.indexof("benchmark") != null))

let debugModes = Computed(@() allGameModes.get().filter(@(m, id) m?.displayType != "random_battle"
  && m?.displayType != "separate_event"
  && id not in benchmarkGameModes.get()))

let maxSquadSize = Computed(@() allGameModes.get().reduce(@(res, m) max(res, m?.maxSquadSize ?? m?.minSquadSize ?? 1), 1))

register_command(
  @() log("curRandomBattleModeName = ", randomBattleMode.get()?.name)
  "debug.getCurRandomBattleModeName")
register_command(
  function(idx) {
    forceNewbieModeIdx.set(idx)
    log("curRandomBattleModeName = ", randomBattleMode.get()?.name)
  }
  "debug.forceNewbieModeIdx")
register_command(
  function() {
    isDebugABTest.set(!isDebugABTest.get())
    console_print("nextNewbieSingle = ", curABTestOnlineTutorialMode.get()?.name ?? "offline") 
  },
  "debug.toggleAbTest.tutorialTankOnline")

let separateEventModes = Computed(function() {
  let res = {}
  foreach(gm in allGameModes.get()) {
    let { displayType = "", eventId = null } = gm
    if (displayType != "separate_event" || eventId == null)
      continue
    if (eventId not in res)
      res[eventId] <- []
    res[eventId].append(gm)
  }
  return res
})

let ovrUnitsGameModes = Computed(@() allGameModes.get()
  .filter(@(m) (m?.only_override_units ?? false) || m?.mission_decl.customRules.customBots != null))

registerHandler("queueToGameMode",
  @(res, context) res?.error == null ? eventbus_send("queueToGameMode", { modeId = context.modeId }) : null)

return {
  allGameModes
  randomBattleMode
  randomBattleModeCore
  ovrUnitsGameModes
  shouldStartNewbieSingleOnline = Computed(@() curABTestOnlineTutorialMode.get() != null)
  isRandomBattleNewbie = Computed(@() isNewbieMode(randomBattleMode.get()?.name))
  isRandomBattleNewbieSingle = Computed(@() isNewbieModeSingle(randomBattleMode.get()?.name))
  debugModes
  benchmarkGameModes
  separateEventModes
  forceNewbieModeIdx
  maxSquadSize
  isGameModesReceived = Computed(@() allGameModes.get().len() != 0)
}
