from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { chooseRandom } = require("%sqstd/rand.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { isInSquad, isSquadLeader, isReady } = require("%appGlobals/squadState.nut")
let { curUnit } = require("%appGlobals/pServer/profile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { newbieGameModesConfig } = require("%appGlobals/gameModes/newbieGameModesConfig.nut")
let { getModeAddonsInfo, allBattleUnits } = require("%appGlobals/updater/gameModeAddons.nut")
let { hasAddons, addonsExistInGameFolder, addonsVersions } = require("%appGlobals/updater/addonsState.nut")
let { getCampaignPkgsForNewbieSingle } = require("%appGlobals/updater/campaignAddons.nut")
let { textButtonBattle, textButtonCommon, textButtonPrimary } = require("%rGui/components/textButton.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { hangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { openLvlUpWndIfCan } = require("%rGui/levelUp/levelUpState.nut")
let { firstBattleTutor, needFirstBattleTutor, startTutor } = require("%rGui/tutorial/tutorialMissions.nut")
let { randomBattleMode, shouldStartNewbieSingleOnline, isGameModesReceived
} = require("%rGui/gameModes/gameModeState.nut")
let { startTestFlight, startOfflineBattle } = require("%rGui/gameModes/startOfflineMode.nut")
let { newbieOfflineMissions, startCurNewbieMission } = require("%rGui/gameModes/newbieOfflineMissions.nut")
let setReady = require("%rGui/squad/setReady.nut")
let { needReadyCheckButton, initiateReadyCheck, isReadyCheckSuspended } = require("%rGui/squad/readyCheck.nut")
let showNoPremMessageIfNeed = require("%rGui/shop/missingPremiumAccWnd.nut")
let offerMissingUnitItemsMessage = require("%rGui/shop/offerMissingUnitItemsMessage.nut")
let tryOpenQueuePenaltyWnd = require("%rGui/queue/queuePenaltyWnd.nut")
let { battleBtnCampaign, penaltyTimerIcon } = require("%rGui/queue/penaltyComps.nut")


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
let battleBtnPenaltyOvr = @(campaign, missionName, ovr) {
  ovr = commonOvr.__merge({ children = penaltyTimerIcon(campaign, missionName) })
  hotkeys = hotkeyX
}.__update(ovr)
let toBattleText = utf8ToUpper(loc("mainmenu/toBattle/short"))

let mkNeedToDownloadAddonsForBattle = @(battleMode) Computed(@() battleMode.get() != null
  && getModeAddonsInfo(
      battleMode.get(),
      allBattleUnits.get(),
      serverConfigs.get(),
      hasAddons.get(),
      addonsExistInGameFolder.get(),
      addonsVersions.get()
    ).addonsToDownload.len() > 0
)

let isNeedToDownloadAddonsForBattle = mkNeedToDownloadAddonsForBattle(randomBattleMode)
let isNeedToDownloadAddonsForOfflineBattle = Computed(@()
  !curUnit.get()?.name || !curUnit.get()?.mRank ? false
    : getCampaignPkgsForNewbieSingle(curCampaign.get(), curUnit.get()?.mRank, [curUnit.get()?.name]).filter(@(v) !hasAddons.get()?[v]).len() > 0)

function mkToBattleButton(toBattleFunc, campaign = null, battleMode = null, ovr = {}) {
  let needToDownloadAddons = battleMode == null ? isNeedToDownloadAddonsForBattle
    : mkNeedToDownloadAddonsForBattle(battleMode)
  let missionName = battleMode == null ? Watched("")
    : Computed(@() battleMode.get()?.mission_decl.missions_list.findindex(@(_) true) ?? battleMode.get()?.name ?? "")
  return @() {
    watch = [needToDownloadAddons, missionName]
    children = (needToDownloadAddons.get() ? textButtonCommon : textButtonBattle)(
      toBattleText,
      toBattleFunc,
      battleBtnPenaltyOvr(campaign, missionName.get(), ovr))
  }
}

function toRandomBattle() {
  if (curUnit.get() != null)
    showNoPremMessageIfNeed(@() offerMissingUnitItemsMessage(curUnit.get(), queueCurRandomBattleMode))
  else if (!openLvlUpWndIfCan())
    logerr($"Unable to start battle because no units (unit in hangar = {hangarUnit.get()?.name})")
}

let cbRandomBattleId = "onResetPenaltyToRandomBattle"
let cbReadyId = "onResetPenaltyReady"
registerHandler(cbRandomBattleId, @(res) res?.error == null ? toRandomBattle() : null)
registerHandler(cbReadyId, @(res) res?.error == null
  ? showNoPremMessageIfNeed(@() offerMissingUnitItemsMessage(curUnit.get(), @() setReady(true)))
  : null)

let toBattleButton_RandomBattles = mkToBattleButton(function() {
  sendNewbieBqEvent("pressToBattleButton", { status = "online_battle", params = randomBattleMode.get()?.name ?? "" })
  if (tryOpenQueuePenaltyWnd(battleBtnCampaign.get(), cbRandomBattleId))
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
    startOfflineBattle(curUnit.get(), mission)
  }
}

let startTutorButton = textButtonBattle(toBattleText,
  function() {
    sendNewbieBqEvent("pressToBattleButton", { status = "tutorial" })
    startTutor(firstBattleTutor.get())
  },
  battleBtnOvr)
let startOfflineBattleButton = @() {
  watch = isNeedToDownloadAddonsForOfflineBattle
  children = (isNeedToDownloadAddonsForOfflineBattle.get() ? textButtonCommon : textButtonBattle)(
    toBattleText,
    startCurUnitOfflineBattle,
    battleBtnOvr)}
let startOfflineMissionButton = @() {
  watch = isNeedToDownloadAddonsForOfflineBattle
  children = (isNeedToDownloadAddonsForOfflineBattle.get() ? textButtonCommon : textButtonBattle)(
    toBattleText,
    function() {
      sendNewbieBqEvent("pressToBattleButton", { status = "offline_battle", params = ", ".join(newbieOfflineMissions.get()) })
      showNoPremMessageIfNeed(@() offerMissingUnitItemsMessage(curUnit.get(), startCurNewbieMission))
    },
    battleBtnOvr)}

let readyButton = @() {
  watch = isNeedToDownloadAddonsForBattle
  children = (isNeedToDownloadAddonsForBattle.get() ? textButtonCommon : textButtonBattle)(
    utf8ToUpper(loc("mainmenu/btnReady")),
    function() {
      if (tryOpenQueuePenaltyWnd(battleBtnCampaign.get(), cbReadyId))
        return
      showNoPremMessageIfNeed(@() offerMissingUnitItemsMessage(curUnit.get(), @() setReady(true)))
    },
    { hotkeys = hotkeyX, ovr = { children = penaltyTimerIcon() } })
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
    : isInSquad.get() && !isReady.get() ? readyButton
    : isInSquad.get() && isReady.get() ? notReadyButton
    : isOfflineMenu ? startOfflineBattleButton
    : needFirstBattleTutor.get() ? startTutorButton
    : newbieOfflineMissions.get() != null && !shouldStartNewbieSingleOnline.get() ? startOfflineMissionButton
    : isGameModesReceived.get() ? toBattleButton_RandomBattles
    : textButtonCommon(toBattleText, @() openMsgBox({ text = loc("msg/noGameModes") }), { hotkeys = hotkeyX })
}

function mkToBattleButtonWithSquadManagement(toBattleFunc, battleMode = null) {
  let toBattleButton = mkToBattleButton(toBattleFunc, null, battleMode)
  return @() {
    watch = [ needReadyCheckButton, isReadyCheckSuspended, isSquadLeader, isInSquad, isReady ]
    children = needReadyCheckButton.get() && isReadyCheckSuspended.get() ? readyCheckButtonInactive
      : needReadyCheckButton.get() ? readyCheckButton
      : isSquadLeader.get() ? toBattleButton
      : isInSquad.get() && !isReady.get() ? readyButton
      : isInSquad.get() && isReady.get() ? notReadyButton
      : toBattleButton
  }
}

return {
  mkToBattleButton
  toBattleButtonForRandomBattles
  mkToBattleButtonWithSquadManagement
}
