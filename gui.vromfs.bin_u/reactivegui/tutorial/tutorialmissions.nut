from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { receivedMissionRewards, curCampaign, isProfileReceived, isAnyCampaignSelected
} = require("%appGlobals/pServer/campaign.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { myUnits, playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let { apply_client_mission_reward } = require("%appGlobals/pServer/pServerApi.nut")
let { register_command } = require("console")
let { send } = require("eventbus")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { isInMenu } = require("%appGlobals/clientState/clientState.nut")
let { isInSquad } = require("%appGlobals/squadState.nut")

let getFirstBattleTutor = @(campaign) $"tutorial_{campaign}_1"
let firstBattleTutor = Computed(@() getFirstBattleTutor(curCampaign.value))

let tutorialMissions = {
  tutorial_ships_1 = "tutorial_ship_basic"
  tutorial_tanks_1 = "tutorial_tank_basic"
}

let started = mkWatched(persist, "started", null)
let isDebugMode = mkWatched(persist, "isDebugMode", false)

let allMissions = Computed(@() (serverConfigs.value?.clientMissionRewards ?? {})
  .filter(@(_, id) id in tutorialMissions))
let missionsWithRewards = Computed(@() allMissions.value
  .filter(@(_, id) id not in started.value && (receivedMissionRewards.value?[id] ?? 0) == 0))

let needFirstBattleTutorByStats = @(stats) (stats?.battles ?? 0) == 0

let needFirstBattleTutor = Computed(@()
  (firstBattleTutor.value in missionsWithRewards.value
    && isProfileReceived.value
    && (myUnits.value.len() == 0
      || needFirstBattleTutorByStats(servProfile.value?.sharedStatsByCampaign?[curCampaign.value]))
  )
  != isDebugMode.value)

let function needFirstBattleTutorForCampaign(campaign) {
  if (getFirstBattleTutor(campaign) not in missionsWithRewards.value)
    return false
  let sUnits = serverConfigs.value?.allUnits ?? {}
  let ownCampUnit = (servProfile.value?.units ?? {}).findvalue(@(_, name) sUnits?[name].campaign == campaign)
  return ownCampUnit == null || needFirstBattleTutorByStats(servProfile.value?.sharedStatsByCampaign?[campaign])
}

let function mkRewardBattleData(rewards) {
  let { level, exp, nextLevelExp } = playerLevelInfo.value
  let { playerExp = 0 } = rewards
  return {
    player = { exp, level, nextLevelExp }
    reward = { playerExp = { totalExp = playerExp }}
  }
}

let needForceStartTutorial = keepref(Computed(@()
  needFirstBattleTutor.value
  && !isInSquad.value
  && isAnyCampaignSelected.value
  && isProfileReceived.value
  && isLoggedIn.value
  && isInMenu.value))

let function startTutor(id) {
  if (id not in tutorialMissions)
    return
  if (id in missionsWithRewards.value) {
    apply_client_mission_reward(curCampaign.value, id)
    send("lastSingleMissionRewardData", {
      battleData = mkRewardBattleData(missionsWithRewards.value[id])
      needAddUnit = true
    })
  }
  send("startSingleMission", { id = tutorialMissions[id] })
  resetTimeout(0.1, @() isDebugMode(false))
}

let function rewardTutorialMission(campaign) {
  let id = getFirstBattleTutor(campaign)
  if (id in missionsWithRewards.value)
    apply_client_mission_reward(campaign, id)
}

needForceStartTutorial.subscribe(@(v) v ? startTutor(firstBattleTutor.value) : null)

register_command(@() isDebugMode(!isDebugMode.value), "debug.first_battle_tutorial")

return {
  firstBattleTutor
  needFirstBattleTutor
  needFirstBattleTutorForCampaign
  startTutor
  isTutorialMissionsDebug = isDebugMode
  tutorialMissions
  rewardTutorialMission
}