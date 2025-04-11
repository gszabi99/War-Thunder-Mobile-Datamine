from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { chooseRandom } = require("%sqstd/rand.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { isInSquad, isSquadLeader, isReady } = require("%appGlobals/squadState.nut")
let { curUnit } = require("%appGlobals/pServer/profile.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { newbieGameModesConfig } = require("%appGlobals/gameModes/newbieGameModesConfig.nut")
let { textButtonBattle, textButtonCommon, textButtonPrimary } = require("%rGui/components/textButton.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { hangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { openLvlUpWndIfCan } = require("%rGui/levelUp/levelUpState.nut")
let { firstBattleTutor, needFirstBattleTutor, startTutor } = require("%rGui/tutorial/tutorialMissions.nut")
let { randomBattleMode, isRandomBattleNewbieTutorial, isGameModesReceived
} = require("%rGui/gameModes/gameModeState.nut")
let { startTestFlight, startOfflineBattle } = require("%rGui/gameModes/startOfflineMode.nut")
let { newbieOfflineMissions, startCurNewbieMission } = require("%rGui/gameModes/newbieOfflineMissions.nut")
let setReady = require("%rGui/squad/setReady.nut")
let { needReadyCheckButton, initiateReadyCheck, isReadyCheckSuspended } = require("%rGui/squad/readyCheck.nut")
let showNoPremMessageIfNeed = require("%rGui/shop/missingPremiumAccWnd.nut")
let offerMissingUnitItemsMessage = require("%rGui/shop/offerMissingUnitItemsMessage.nut")
let tryOpenQueuePenaltyWnd = require("%rGui/queue/queuePenaltyWnd.nut")
let { hasPenaltyStatus } = require("%rGui/mainMenu/penaltyState.nut")


let queueCurRandomBattleMode = @() eventbus_send("queueToGameMode", { modeId = randomBattleMode.get()?.gameModeId })

let battleBtnCampaign = Computed(@() randomBattleMode.get()?.campaign ?? curCampaign.get())

let timerSize = hdpxi(40)
function penaltyTimerIcon() {
  let res = { watch = [hasPenaltyStatus, battleBtnCampaign] }
  let hasPenalty = hasPenaltyStatus.get()?[battleBtnCampaign.get()] ?? false
  return !hasPenalty ? res
    : res.__update({
        size = [timerSize, timerSize]
        margin = [hdpx(8), hdpx(16)]
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#timer_icon.svg:{timerSize}:{timerSize}:P")
        vplace = ALIGN_TOP
        hplace = ALIGN_RIGHT
        keepAspect = KEEP_ASPECT_FIT
      })
}

let hotkeyX = ["^J:X | Enter"]
let commonOvr = {
  key = "toBattleButton"
  animations = [{ prop = AnimProp.scale, from = [1.0, 1.0], to = [1.2, 1.2], duration = 0.4, easing = CosineFull, play = true, delay = 2 }]
}
let battleBtnOvr = {
  ovr = commonOvr
  hotkeys = hotkeyX
}
let battleBtnPenaltyOvr = {
  ovr = commonOvr.__merge({ children = penaltyTimerIcon })
  hotkeys = hotkeyX
}
let toBattleText = utf8ToUpper(loc("mainmenu/toBattle/short"))
let mkToBattleButton = @(toBattleFunc) textButtonBattle(toBattleText, toBattleFunc, battleBtnPenaltyOvr)

function toRandomBattle() {
  if (curUnit.get() != null)
    showNoPremMessageIfNeed(@() offerMissingUnitItemsMessage(curUnit.get(), queueCurRandomBattleMode))
  else if (!openLvlUpWndIfCan())
    logerr($"Unable to start battle because no units (unit in hangar = {hangarUnit.get()?.name})")
}

let cbId = "onResetPenaltyToRandomBattle"
registerHandler(cbId, @(res) res?.error == null ? toRandomBattle() : null)

let toBattleButton_RandomBattles = mkToBattleButton(function() {
  sendNewbieBqEvent("pressToBattleButton", { status = "online_battle", params = randomBattleMode.get()?.name ?? "" })
  if (tryOpenQueuePenaltyWnd(battleBtnCampaign.get(), cbId))
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
let startOfflineBattleButton = textButtonBattle(toBattleText,
  startCurUnitOfflineBattle,
  battleBtnOvr)
let startOfflineMissionButton = textButtonBattle(toBattleText,
  function() {
    sendNewbieBqEvent("pressToBattleButton", { status = "offline_battle", params = ", ".join(newbieOfflineMissions.get()) })
    showNoPremMessageIfNeed(@() offerMissingUnitItemsMessage(curUnit.get(), startCurNewbieMission))
  },
  battleBtnOvr)

let readyButton = textButtonBattle(utf8ToUpper(loc("mainmenu/btnReady")),
  @() showNoPremMessageIfNeed(@() offerMissingUnitItemsMessage(curUnit.get(), @() setReady(true))),
  { hotkeys = hotkeyX })
let notReadyButton = textButtonCommon(utf8ToUpper(loc("multiplayer/state/player_not_ready")),
  @() setReady(false),
  { hotkeys = hotkeyX })
let readyCheckText = utf8ToUpper(loc("squad/readyCheckBtn"))
let readyCheckButton = textButtonPrimary(readyCheckText, initiateReadyCheck, { hotkeys = hotkeyX })
let readyCheckButtonInactive = textButtonCommon(readyCheckText, initiateReadyCheck, { hotkeys = hotkeyX })

let toBattleButtonForRandomBattles = @() {
  watch = [ needReadyCheckButton, isReadyCheckSuspended, isSquadLeader, isInSquad, isReady,
    needFirstBattleTutor, newbieOfflineMissions, isRandomBattleNewbieTutorial, isGameModesReceived
  ]
  children = needReadyCheckButton.get() && isReadyCheckSuspended.get() ? readyCheckButtonInactive
    : needReadyCheckButton.get() ? readyCheckButton
    : isSquadLeader.get() ? toSquadBattleButton_RandomBattles
    : isInSquad.get() && !isReady.get() ? readyButton
    : isInSquad.get() && isReady.get() ? notReadyButton
    : isOfflineMenu ? startOfflineBattleButton
    : needFirstBattleTutor.get() ? startTutorButton
    : newbieOfflineMissions.get() != null && !isRandomBattleNewbieTutorial.get() ? startOfflineMissionButton
    : isGameModesReceived.get() ? toBattleButton_RandomBattles
    : textButtonCommon(toBattleText, @() openMsgBox({ text = loc("msg/noGameModes") }), { hotkeys = hotkeyX })
}

let function mkToBattleButtonWithSquadManagement(toBattleFunc, toSquadBattleFunc = null) {
  let toBattleButton = mkToBattleButton(toBattleFunc)
  let toSquadBattleButton = toSquadBattleFunc != null ? mkToBattleButton(toSquadBattleFunc) : toBattleButton
  return @() {
    watch = [ needReadyCheckButton, isReadyCheckSuspended, isSquadLeader, isInSquad, isReady ]
    children = needReadyCheckButton.get() && isReadyCheckSuspended.get() ? readyCheckButtonInactive
      : needReadyCheckButton.get() ? readyCheckButton
      : isSquadLeader.get() ? toSquadBattleButton
      : isInSquad.get() && !isReady.get() ? readyButton
      : isInSquad.get() && isReady.get() ? notReadyButton
      : toBattleButton
  }
}

return {
  toBattleButtonForRandomBattles
  mkToBattleButtonWithSquadManagement
}
