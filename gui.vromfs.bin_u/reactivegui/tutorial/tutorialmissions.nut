from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "dagor.workcycle" import resetTimeout, deferOnce
from "eventbus" import eventbus_send
from "%appGlobals/clientState/clientState.nut" import isInMenu
from "%appGlobals/data/battleDataExtras.nut" import mkResearchingUnitForBattleData
from "%appGlobals/loginState.nut" import isLoggedIn
from "%appGlobals/pServer/campaign.nut" import receivedMissionRewards, curCampaign, isProfileReceived,
  isAnyCampaignSelected, abTests, sharedStatsByCampaign
from "%appGlobals/pServer/pServerApi.nut" import apply_client_mission_reward, clientMissionRewardInProgress
from "%appGlobals/pServer/profile.nut" import campMyUnits, playerLevelInfo
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/squadState.nut" import isInSquad
from "%rGui/account/resetProfileDetector.nut" import subscribeResetProfile
from "%rGui/unit/hangarUnit.nut" import hangarUnit
from "%rGui/unitsTree/unitsTreeNodesState.nut" import currentResearch
from "%rGui/weaponry/bulletsCalc.nut" import getDefaultBulletsForSpawn


function getFirstBattleTutor(campaign, sConfigs) {
  if (campaign.endswith("_new")) {  
    let baseCamp = campaign.slice(0, -4)
    local res = $"tutorial_{baseCamp}_1_nc"
    if (res in sConfigs?.clientMissionRewards)
      return res
    res = $"tutorial_{baseCamp}_1"
    if (res in sConfigs?.clientMissionRewards)
      return res
  }
  return $"tutorial_{campaign}_1"
}
let firstBattleTutor = Computed(@() getFirstBattleTutor(curCampaign.get(), serverConfigs.get()))

let forceTutorTankMissionV2 = mkWatched(persist, "forceTutorTankMissionV2", null)
let tutorialMissions = Computed(@() {
  tutorial_ships_1 = "tutorial_ship_basic"
  tutorial_ships_1_nc = "tutorial_ship_basic"
  tutorial_tanks_1 = (forceTutorTankMissionV2.get() ?? abTests.get()?.tutorialTankMissionV2) == "true" ? "tutorial_tank_basic_v2" : "tutorial_tank_basic"
  tutorial_tanks_1_nc = "tutorial_tank_basic"
  tutorial_air_1   = "tutorial_plane_basic"
})
let isSkippedTutor = mkWatched(persist, "isSkippedFirstBattleTutor", {})
let started = mkWatched(persist, "started", null)
let isDebugMode = mkWatched(persist, "isDebugMode", false)

let allMissions = Computed(@() (serverConfigs.get()?.clientMissionRewards ?? {})
  .filter(@(_, id) id in tutorialMissions.get()))
let missionsWithRewards = Computed(@() allMissions.get()
  .filter(@(_, id) id not in started.get() && (receivedMissionRewards.get()?[id] ?? 0) == 0))

let needFirstBattleTutorByStats = @(stats) (stats?.battles ?? 0) == 0

let needFirstBattleTutor = Computed(@()
  (firstBattleTutor.get() in missionsWithRewards.get()
    && isProfileReceived.get()
    && (campMyUnits.get().len() == 0 || needFirstBattleTutorByStats(sharedStatsByCampaign.get()))
    && currentResearch.get() != null)
  != isDebugMode.get())

let setSkippedTutor = @(campaign) isSkippedTutor.mutate(@(v) v[getFirstBattleTutor(campaign, serverConfigs.get())] <- true)

function needFirstBattleTutorForCampaign(campaign) {
  if (getFirstBattleTutor(campaign, serverConfigs.get()) not in missionsWithRewards.get())
    return false
  let sUnits = serverConfigs.get()?.allUnits ?? {}
  let ownCampUnit = (servProfile.get()?.units ?? {}).findvalue(@(_, name) sUnits?[name].campaign == campaign)
  return ownCampUnit == null || needFirstBattleTutorByStats(servProfile.get()?.sharedStatsByCampaign[campaign])
}

function mkRewardBattleData(rewards) {
  let { level, exp, nextLevelExp } = playerLevelInfo.get()
  let { playerExp = 0 } = rewards
  return {
    campaign = curCampaign.get()
    player = { exp, level, nextLevelExp }
    reward = { playerExp = { baseExp = playerExp, totalExp = playerExp }}
    researchingUnit = mkResearchingUnitForBattleData()
  }
}

let needForceStartTutorial = keepref(Computed(@()
  needFirstBattleTutor.get()
  && !isInSquad.get()
  && isAnyCampaignSelected.get()
  && isProfileReceived.get()
  && isLoggedIn.get()
  && isInMenu.get()))

function startTutor(id, currentUnitName = null) {
  if (id not in tutorialMissions.get())
    return
  if (id in missionsWithRewards.get()) {
    if (id != clientMissionRewardInProgress.get())
      apply_client_mission_reward(curCampaign.get(), id)
    eventbus_send("lastSingleMissionRewardData", {
      battleData = mkRewardBattleData(missionsWithRewards.get()[id])
      needAddUnit = true
    })
  }
  if (!isSkippedTutor.get()?[id]) {
    let unitName = currentUnitName == "" ? null
      : currentUnitName ? currentUnitName
      : isDebugMode.get() && hangarUnit.get()?.name
        ? hangarUnit.get().name
      : campMyUnits.get().findindex(@(u) u.name in (serverConfigs.get()?.unitResearchExp ?? {}))
        ?? currentResearch.get()?.name
    eventbus_send("startSingleMission", {
      id = tutorialMissions.get()[id],
      unitName
      bullets = unitName != null && unitName != ""
        ? getDefaultBulletsForSpawn(unitName, 1000, campMyUnits.get()?[unitName].mods)
        : null
    })
  }
  resetTimeout(0.1, @() isDebugMode.set(false))
}

function rewardTutorialMission(campaign) {
  let id = getFirstBattleTutor(campaign, serverConfigs.get())
  if (id in missionsWithRewards.get() && id != clientMissionRewardInProgress.get())
    apply_client_mission_reward(campaign, id)
}

function autoStartTutorial() {
  if (needForceStartTutorial.get())
    startTutor(firstBattleTutor.get())
}

needForceStartTutorial.subscribe(@(v) v ? deferOnce(autoStartTutorial) : null)

register_command(@() isDebugMode.set(!isDebugMode.get()), "debug.first_battle_tutorial")
register_command(function() {
  forceTutorTankMissionV2.set(forceTutorTankMissionV2.get() != null
    ? null
    : (abTests.get()?.tutorialTankMissionV2 == "true" ? "false" : "true")
  )
  dlog("tutorialMissions", tutorialMissions.get()) 
}, "debug.abTests.tutorialTankMission")

subscribeResetProfile(@() isSkippedTutor.set({}))

return {
  firstBattleTutor
  needFirstBattleTutor
  needFirstBattleTutorForCampaign
  startTutor
  isTutorialMissionsDebug = isDebugMode
  tutorialMissions
  rewardTutorialMission
  setSkippedTutor
}