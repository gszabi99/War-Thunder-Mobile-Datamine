from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { receivedMissionRewards, curCampaign, isProfileReceived, isAnyCampaignSelected, abTests,
  isCampaignWithUnitsResearch
} = require("%appGlobals/pServer/campaign.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { myUnits, playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let { apply_client_mission_reward } = require("%appGlobals/pServer/pServerApi.nut")
let { register_command } = require("console")
let { eventbus_send } = require("eventbus")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { isInMenu } = require("%appGlobals/clientState/clientState.nut")
let { isInSquad } = require("%appGlobals/squadState.nut")
let { mkResearchingUnitForBattleData } = require("%appGlobals/data/battleDataExtras.nut")
let { currentResearch } = require("%rGui/unitsTree/unitsTreeNodesState.nut")
let { hangarUnit } = require("%rGui/unit/hangarUnit.nut")

let getFirstBattleTutor = @(campaign) $"tutorial_{campaign}_1"
let firstBattleTutor = Computed(@() getFirstBattleTutor(curCampaign.value))

let forceTutorTankMissionV2 = mkWatched(persist, "forceTutorTankMissionV2", null)
let tutorialMissions = Computed(@() {
  tutorial_ships_1 = "tutorial_ship_basic"
  tutorial_tanks_1 = (forceTutorTankMissionV2.value ?? abTests.value?.tutorialTankMissionV2) == "true" ? "tutorial_tank_basic_v2" : "tutorial_tank_basic"
  tutorial_air_1   = "tutorial_plane_basic"
})
let isSkippedTutor = mkWatched(persist, "isSkippedFirstBattleTutor", {})
let started = mkWatched(persist, "started", null)
let isDebugMode = mkWatched(persist, "isDebugMode", false)

let allMissions = Computed(@() (serverConfigs.value?.clientMissionRewards ?? {})
  .filter(@(_, id) id in tutorialMissions.value))
let missionsWithRewards = Computed(@() allMissions.value
  .filter(@(_, id) id not in started.value && (receivedMissionRewards.value?[id] ?? 0) == 0))

let needFirstBattleTutorByStats = @(stats) (stats?.battles ?? 0) == 0

let needFirstBattleTutor = Computed(@()
  (firstBattleTutor.value in missionsWithRewards.value
    && isProfileReceived.value
    && (myUnits.value.len() == 0
      || needFirstBattleTutorByStats(servProfile.value?.sharedStatsByCampaign?[curCampaign.value]))
    && (!isCampaignWithUnitsResearch.get() || currentResearch.get() != null)
  )
  != isDebugMode.value)

let setSkippedTutor = @(campaign) isSkippedTutor.mutate(@(v) v[getFirstBattleTutor(campaign)] <- true)

function needFirstBattleTutorForCampaign(campaign) {
  if (getFirstBattleTutor(campaign) not in missionsWithRewards.value)
    return false
  let sUnits = serverConfigs.value?.allUnits ?? {}
  let ownCampUnit = (servProfile.value?.units ?? {}).findvalue(@(_, name) sUnits?[name].campaign == campaign)
  return ownCampUnit == null || needFirstBattleTutorByStats(servProfile.value?.sharedStatsByCampaign?[campaign])
}

function mkRewardBattleData(rewards) {
  let { level, exp, nextLevelExp } = playerLevelInfo.value
  let { playerExp = 0 } = rewards
  return {
    player = { exp, level, nextLevelExp }
    reward = { playerExp = { baseExp = playerExp, totalExp = playerExp }}
    researchingUnit = mkResearchingUnitForBattleData()
  }
}

let needForceStartTutorial = keepref(Computed(@()
  needFirstBattleTutor.value
  && !isInSquad.value
  && isAnyCampaignSelected.value
  && isProfileReceived.value
  && isLoggedIn.value
  && isInMenu.value))

function startTutor(id, currentUnitName = null) {
  if (id not in tutorialMissions.value)
    return
  if (id in missionsWithRewards.value) {
    apply_client_mission_reward(curCampaign.value, id)
    eventbus_send("lastSingleMissionRewardData", {
      battleData = mkRewardBattleData(missionsWithRewards.value[id])
      needAddUnit = true
    })
  }
  if (!isSkippedTutor.get()?[id])
    eventbus_send("startSingleMission", {
      id = tutorialMissions.value[id],
      unitName = !isCampaignWithUnitsResearch.get()
          ? null
        : currentUnitName
          ? currentUnitName
        : isDebugMode.get() && hangarUnit.get()?.name
          ? hangarUnit.get().name
        : myUnits.get().findindex(@(u) u.name in (serverConfigs.get()?.unitResearchExp ?? {}))
          ?? currentResearch.get()?.name
    })
  resetTimeout(0.1, @() isDebugMode(false))
}

function rewardTutorialMission(campaign) {
  let id = getFirstBattleTutor(campaign)
  if (id in missionsWithRewards.value)
    apply_client_mission_reward(campaign, id)
}

needForceStartTutorial.subscribe(@(v) v ? startTutor(firstBattleTutor.value) : null)

register_command(@() isDebugMode(!isDebugMode.value), "debug.first_battle_tutorial")
register_command(function() {
  forceTutorTankMissionV2.set(forceTutorTankMissionV2.get() != null
    ? null
    : (abTests.value?.tutorialTankMissionV2 == "true" ? "false" : "true")
  )
  dlog("tutorialMissions", tutorialMissions.value) // warning disable: -forbidden-function
}, "debug.abTests.tutorialTankMission")

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