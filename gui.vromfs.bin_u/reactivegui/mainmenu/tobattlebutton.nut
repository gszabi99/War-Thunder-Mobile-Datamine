from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { get_meta_mission_info_by_name } = require("guiMission")
let { chooseRandom } = require("%sqstd/rand.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { isInSquad, isSquadLeader, isReady } = require("%appGlobals/squadState.nut")
let { curUnit, curUnits } = require("%appGlobals/pServer/profile.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { newbieGameModesConfig } = require("%appGlobals/gameModes/newbieGameModesConfig.nut")
let { hasAddons, unitSizes } = require("%appGlobals/updater/addonsState.nut")
let { getCampaignPkgsForNewbieSingle } = require("%appGlobals/updater/campaignAddons.nut")
let { getMissionUnitsAndAddons, addSupportUnits } = require("%appGlobals/updater/missionUnits.nut")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let { textButtonBattle, textButtonCommon, textButtonPrimary } = require("%rGui/components/textButton.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { hangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { openLvlUpWndIfCan } = require("%rGui/levelUp/levelUpState.nut")
let { firstBattleTutor, needFirstBattleTutor, startTutor } = require("%rGui/tutorial/tutorialMissions.nut")
let { randomBattleMode, shouldStartNewbieSingleOnline, isGameModesReceived, allGameModes
} = require("%rGui/gameModes/gameModeState.nut")
let { startTestFlight, startNewbieOfflineBattle } = require("%rGui/gameModes/startOfflineMode.nut")
let { newbieOfflineMissions, startCurNewbieMission } = require("%rGui/gameModes/newbieOfflineMissions.nut")
let setReady = require("%rGui/squad/setReady.nut")
let { needReadyCheckButton, initiateReadyCheck, isReadyCheckSuspended } = require("%rGui/squad/readyCheck.nut")
let showNoPremMessageIfNeed = require("%rGui/shop/missingPremiumAccWnd.nut")
let offerMissingUnitItemsMessage = require("%rGui/shop/offerMissingUnitItemsMessage.nut")
let tryOpenQueuePenaltyWnd = require("%rGui/queue/queuePenaltyWnd.nut")
let { battleBtnCampaign, penaltyTimerIcon } = require("%rGui/queue/penaltyComps.nut")
let { isNeedAddonsForRandomBattle } = require("%rGui/updater/randomBattleModeAddons.nut")


let randomBattleButtonDownloading = Watched({})

let queueCurRandomBattleMode = @() eventbus_send("queueToGameMode", { modeId = randomBattleMode.get()?.gameModeId })

let hotkeyX = ["^J:X | Enter"]
let commonOvr = {
  key = "toBattleButton"
  animations = [{ prop = AnimProp.scale, from = [1.0, 1.0], to = [1.2, 1.2], duration = 0.4, easing = CosineFull, play = true, delay = 2 }]
}
let battleBtnOvr = {
  ovr = commonOvr
  hotkeys = hotkeyX
}
let battleBtnPenaltyOvr = @(campaign, ovr) {
  ovr = commonOvr.__merge({ children = penaltyTimerIcon(campaign) })
  hotkeys = hotkeyX
}.__update(ovr)
let toBattleText = utf8ToUpper(loc("mainmenu/toBattle/short"))

function mkDownloadingOvr(key, isDownloading) {
  function update(isDl) {
    if (isDl != (key in randomBattleButtonDownloading.get()))
      randomBattleButtonDownloading.mutate(@(v) isDl ? v.$rawset(key, true) : v.$rawdelete(key))
  }
  return {
    key
    function onAttach() {
      update(isDownloading.get())
      isDownloading.subscribe(update)
    }
    function onDetach() {
      update(false)
      isDownloading.unsubscribe(update)
    }
  }
}

let isNeedDownloadForOfflineNewbieBattle = Computed(function() {
  if (newbieOfflineMissions.get() == null)
    return false
  if (null != getCampaignPkgsForNewbieSingle(curCampaign.get()).findvalue(@(a) !(hasAddons.get()?[a] ?? true)))
    return true
  let units = {}
  let addons = {}
  if (curUnit.get() != null)
    units[getTagsUnitName(curUnit.get().name)] <- true
  foreach (missionName in newbieOfflineMissions.get()) {
    let { misUnits, misAddons } = getMissionUnitsAndAddons(missionName)
    units.__update(misUnits)
    addons.__update(misAddons)
  }
  return null != addSupportUnits(units).findindex(@(_, u) (unitSizes.get()?[u] ?? -1) != 0)
    && null != addons.findvalue(@(a) !(hasAddons.get()?[a] ?? true))
})

function mkRandomBattlesButton(toBattleFunc) {
  let ovr = mkDownloadingOvr("randomBattle", isNeedAddonsForRandomBattle)
  return @() {
    watch = [isNeedAddonsForRandomBattle, curCampaign]
    children = (isNeedAddonsForRandomBattle.get() ? textButtonCommon : textButtonBattle)(
      toBattleText,
      toBattleFunc,
      battleBtnPenaltyOvr(curCampaign.get(), ovr))
  }.__update(ovr)
}

function mkToBattleButtonNoAddons(toBattleFunc, battleMode, ovr = {}) {
  let missionName = Computed(@() battleMode.get()?.mission_decl.missions_list.findindex(@(_) true) ?? "")
  let isGtFfa = Computed(@() get_meta_mission_info_by_name(missionName.get())?.gt_ffa ?? false)
  return @() {
    watch = [battleMode, isGtFfa]
    children = battleMode.get() == null ? null
      : textButtonBattle(
          toBattleText,
          toBattleFunc,
          !isGtFfa.get() ? battleBtnPenaltyOvr(battleMode.get()?.campaign, ovr) : battleBtnOvr.__update(ovr))
  }
}

function toRandomBattle() {
  if (curUnit.get() != null)
    showNoPremMessageIfNeed(@() offerMissingUnitItemsMessage(curUnits.get(), queueCurRandomBattleMode))
  else if (!openLvlUpWndIfCan())
    logerr($"Unable to start battle because no units (unit in hangar = {hangarUnit.get()?.name})")
}

let cbRandomBattleId = "onResetPenaltyToRandomBattle"
let cbReadyId = "onResetPenaltyReady"
registerHandler(cbRandomBattleId, @(res) res?.error == null ? toRandomBattle() : null)
registerHandler(cbReadyId, @(res, context) res?.error == null
  ? showNoPremMessageIfNeed(@() offerMissingUnitItemsMessage(curUnits.get(), @() setReady(true, context?.mGMode)))
  : null)

let toBattleButton_RandomBattles = mkRandomBattlesButton(function() {
  sendNewbieBqEvent("pressToBattleButton", { status = "online_battle", params = randomBattleMode.get()?.name ?? "" })
  if (tryOpenQueuePenaltyWnd(battleBtnCampaign.get(), randomBattleMode.get(), cbRandomBattleId))
    return
  toRandomBattle()
})
let toSquadBattleButton_RandomBattles = toBattleButton_RandomBattles

function startCurUnitOfflineBattle() {
  if (curUnit.get() == null) {
    sendNewbieBqEvent("pressToBattleButton", { status = "offline_battle", params = "no unit!!!" })
    return
  }
  let { name, campaign } = curUnit.get()
  let missions = newbieGameModesConfig?[campaign]
    .reduce(@(res, cfg) res.extend(cfg?.offlineMissions ?? []), [])
    ?? []
  if (missions.len() == 0) {
    log($"OflineStartBattle: test flight, because no mission for campaign {campaign} ({name})")
    sendNewbieBqEvent("pressToBattleButton", { status = "offline_battle", params = "testflight" })
    startTestFlight(curUnit.get())
  }
  else {
    let mission = chooseRandom(missions)
    log($"OflineStartBattle: start mission {mission} for {name}")
    sendNewbieBqEvent("pressToBattleButton", { status = "offline_battle", params = mission })
    startNewbieOfflineBattle(curUnit.get(), mission)
  }
}

let startTutorButton = textButtonBattle(toBattleText,
  function() {
    sendNewbieBqEvent("pressToBattleButton", { status = "tutorial" })
    startTutor(firstBattleTutor.get())
  },
  battleBtnOvr)

let startOfflineBattleButton = textButtonBattle(toBattleText, startCurUnitOfflineBattle, battleBtnOvr)

let offlineNewbieOvr = mkDownloadingOvr("offlineBattle", isNeedDownloadForOfflineNewbieBattle)
let startOfflineMissionButton = @() {
  watch = isNeedDownloadForOfflineNewbieBattle
  children = (isNeedDownloadForOfflineNewbieBattle.get() ? textButtonCommon : textButtonBattle)(
    toBattleText,
    function() {
      sendNewbieBqEvent("pressToBattleButton", { status = "offline_battle", params = ", ".join(newbieOfflineMissions.get()) })
      showNoPremMessageIfNeed(@() offerMissingUnitItemsMessage(curUnits.get(), startCurNewbieMission))
    },
    battleBtnOvr)
}.__update(offlineNewbieOvr)

let readyOvr = mkDownloadingOvr("squadReady", isNeedAddonsForRandomBattle)
let readyButtonRandomBattles = @() {
  watch = isNeedAddonsForRandomBattle
  children = (isNeedAddonsForRandomBattle.get() ? textButtonCommon : textButtonBattle)(
    utf8ToUpper(loc("mainmenu/btnReady")),
    function() {
      if (tryOpenQueuePenaltyWnd(battleBtnCampaign.get(), randomBattleMode.get(), cbReadyId))
        return
      showNoPremMessageIfNeed(@() offerMissingUnitItemsMessage(curUnits.get(), @() setReady(true)))
    },
    { hotkeys = hotkeyX, ovr = { children = penaltyTimerIcon() } })
}.__update(readyOvr)

let readyButtonNoAddons = @(battleMode) function() {
  let mGMode = battleMode.get()
  return {
    watch = battleMode
    children = battleMode.get() == null ? null
      : textButtonBattle(
          utf8ToUpper(loc("mainmenu/btnReady")),
          function() {
            if (tryOpenQueuePenaltyWnd(battleBtnCampaign.get(), mGMode, cbReadyId))
              return
            showNoPremMessageIfNeed(@() setReady(true, mGMode))
          },
          { hotkeys = hotkeyX, ovr = { children = penaltyTimerIcon() } })
  }.__update(readyOvr)
}

let notReadyButton = textButtonCommon(utf8ToUpper(loc("multiplayer/state/player_not_ready")),
  @() setReady(false),
  { hotkeys = hotkeyX })
let readyCheckText = utf8ToUpper(loc("squad/readyCheckBtn"))
let readyCheckButton = textButtonPrimary(readyCheckText, initiateReadyCheck, { hotkeys = hotkeyX })
let readyCheckButtonInactive = textButtonCommon(readyCheckText, initiateReadyCheck, { hotkeys = hotkeyX })

let toBattleButtonForRandomBattles = @() {
  watch = [ needReadyCheckButton, isReadyCheckSuspended, isSquadLeader, isInSquad, isReady,
    needFirstBattleTutor, newbieOfflineMissions, shouldStartNewbieSingleOnline, isGameModesReceived
  ]
  children = needReadyCheckButton.get() && isReadyCheckSuspended.get() ? readyCheckButtonInactive
    : needReadyCheckButton.get() ? readyCheckButton
    : isSquadLeader.get() ? toSquadBattleButton_RandomBattles
    : isInSquad.get() && !isReady.get() ? readyButtonRandomBattles
    : isInSquad.get() && isReady.get() ? notReadyButton
    : isOfflineMenu ? startOfflineBattleButton
    : needFirstBattleTutor.get() ? startTutorButton
    : newbieOfflineMissions.get() != null && !shouldStartNewbieSingleOnline.get() ? startOfflineMissionButton
    : isGameModesReceived.get() ? toBattleButton_RandomBattles
    : textButtonCommon(toBattleText, @() openMsgBox({ text = loc("msg/noGameModes") }), { hotkeys = hotkeyX })
}

function mkToBattleButtonWithSquadManagement(toBattleFunc, bModeOrId = null) {
  let battleMode = bModeOrId == null ? randomBattleMode
    : bModeOrId instanceof Watched ? bModeOrId
    : type(bModeOrId) == "table" ? Watched(bModeOrId)
    : Computed(@() allGameModes.get()?[bModeOrId])
  let toBattleButton = mkToBattleButtonNoAddons(toBattleFunc, battleMode)
  return @() {
    watch = [ needReadyCheckButton, isReadyCheckSuspended, isSquadLeader, isInSquad, isReady ]
    children = needReadyCheckButton.get() && isReadyCheckSuspended.get() ? readyCheckButtonInactive
      : needReadyCheckButton.get() ? readyCheckButton
      : isSquadLeader.get() ? toBattleButton
      : isInSquad.get() && !isReady.get() ? readyButtonNoAddons(battleMode)
      : isInSquad.get() && isReady.get() ? notReadyButton
      : toBattleButton
  }
}

return {
  randomBattleButtonDownloading
  mkToBattleButtonNoAddons
  toBattleButtonForRandomBattles
  mkToBattleButtonWithSquadManagement
}
