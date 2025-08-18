from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, deferOnce } = require("dagor.workcycle")
let { receivedMissionRewards, curCampaign, isProfileReceived, isAnyCampaignSelected, abTests,
  isCampaignWithUnitsResearch, sharedStatsByCampaign, getCampaignStatsId
} = require("%appGlobals/pServer/campaign.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { campMyUnits, playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let { apply_client_mission_reward } = require("%appGlobals/pServer/pServerApi.nut")
let { register_command } = require("console")
let { eventbus_send } = require("eventbus")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { isInMenu } = require("%appGlobals/clientState/clientState.nut")
let { isInSquad } = require("%appGlobals/squadState.nut")
let { mkResearchingUnitForBattleData } = require("%appGlobals/data/battleDataExtras.nut")
let { currentResearch } = require("%rGui/unitsTree/unitsTreeNodesState.nut")
let { hangarUnit } = require("%rGui/unit/hangarUnit.nut")

let getFirstBattleTutor = @(campaign) !campaign.endswith("_new") ? $"tutorial_{campaign}_1"
  : $"tutorial_{campaign.slice(0, -4)}_1_nc"
let firstBattleTutor = Computed(@() getFirstBattleTutor(curCampaign.get()))

let forceTutorTankMissionV2 = mkWatched(persist, "forceTutorTankMissionV2", null)
let tutorialMissions = Computed(@() {
  tutorial_ships_1 = "tutorial_ship_basic"
  tutorial_ships_1_nc = "tutorial_ship_basic"
  tutorial_tanks_1 = (forceTutorTankMissionV2.get() ?? abTests.get()?.tutorialTankMissionV2) == "true" ? "tutorial_tank_basic_v2" : "tutorial_tank_basic"
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
    && (!isCampaignWithUnitsResearch.get() || currentResearch.get() != null)
  )
  != isDebugMode.get())

let setSkippedTutor = @(campaign) isSkippedTutor.mutate(@(v) v[getFirstBattleTutor(campaign)] <- true)

function needFirstBattleTutorForCampaign(campaign) {
  if (getFirstBattleTutor(campaign) not in missionsWithRewards.get())
    return false
  let sUnits = serverConfigs.get()?.allUnits ?? {}
  let ownCampUnit = (servProfile.value?.units ?? {}).findvalue(@(_, name) sUnits?[name].campaign == campaign)
  return ownCampUnit == null || needFirstBattleTutorByStats(servProfile.value?.sharedStatsByCampaign[getCampaignStatsId(campaign)])
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
    apply_client_mission_reward(curCampaign.get(), id)
    eventbus_send("lastSingleMissionRewardData", {
      battleData = mkRewardBattleData(missionsWithRewards.get()[id])
      needAddUnit = true
    })
  }
  if (!isSkippedTutor.get()?[id])
    eventbus_send("startSingleMission", {
      id = tutorialMissions.get()[id],
      unitName = (!isCampaignWithUnitsResearch.get() || currentUnitName == "")
          ? null
        : currentUnitName
          ? currentUnitName
        : isDebugMode.get() && hangarUnit.get()?.name
          ? hangarUnit.get().name
        : campMyUnits.get().findindex(@(u) u.name in (serverConfigs.get()?.unitResearchExp ?? {}))
          ?? currentResearch.get()?.name
    })
  resetTimeout(0.1, @() isDebugMode.set(false))
}

function rewardTutorialMission(campaign) {
  let id = getFirstBattleTutor(campaign)
  if (id in missionsWithRewards.get())
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