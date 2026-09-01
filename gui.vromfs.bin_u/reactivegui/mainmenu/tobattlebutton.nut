from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_send
from "guiMission" import get_meta_mission_info_by_name
from "%sqstd/rand.nut" import chooseRandom
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/clientState/initialState.nut" import isOfflineMenu
from "%appGlobals/gameModes/newbieGameModesConfig.nut" import newbieGameModesConfig
from "%appGlobals/pServer/bqClient.nut" import sendNewbieBqEvent
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/pServer/pServerApi.nut" import registerHandler
from "%appGlobals/pServer/profile.nut" import curUnit, curUnits
from "%appGlobals/rentalState.nut" import rentals
from "%appGlobals/squadState.nut" import isInSquad, isSquadLeader, isReady
from "%appGlobals/timeToText.nut" import secondsToHoursLoc
from "%appGlobals/updater/addonsState.nut" import hasAddons, unitSizes
from "%appGlobals/updater/campaignAddons.nut" import getCampaignPkgsForNewbieSingle
from "%appGlobals/updater/missionUnits.nut" import getMissionUnitsAndAddons, addSupportUnits
from "%appGlobals/userstats/serverTime.nut" import serverTime
import "%rGui/components/buttonStyles.nut" as buttonStyles
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/components/textButton.nut" import textButtonBattle, textButtonCommon, textButtonPrimary, mkCustomButton,
  mergeStyles
from "%rGui/gameModes/gameModeState.nut" import randomBattleMode, shouldStartNewbieSingleOnline, isGameModesReceived,
  allGameModes
from "%rGui/gameModes/newbieOfflineMissions.nut" import newbieOfflineMissions, startCurNewbieMission, newbieLocalMP,
  isNextBattleNewbieOffline
from "%rGui/gameModes/startOfflineMode.nut" import startTestFlight, startNewbieOfflineBattle
from "%rGui/queue/penaltyComps.nut" import battleBtnCampaign, penaltyTimerIcon
import "%rGui/queue/queuePenaltyWnd.nut" as tryOpenQueuePenaltyWnd
import "%rGui/shop/missingPremiumAccWnd.nut" as showNoPremMessageIfNeed
import "%rGui/shop/offerMissingUnitItemsMessage.nut" as offerMissingUnitItemsMessage
from "%rGui/squad/readyCheck.nut" import needReadyCheckButton, initiateReadyCheck, isReadyCheckSuspended
import "%rGui/squad/setReady.nut" as setReady
from "%rGui/state/matchingRank.nut" import mkMRankRange
from "%rGui/tutorial/tutorialMissions.nut" import firstBattleTutor, needFirstBattleTutor, startTutor
from "%rGui/unit/hangarUnit.nut" import hangarUnit
from "%rGui/updater/randomBattleModeAddons.nut" import isNeedAddonsForRandomBattle
from "types" import Table


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
let battleBtnPenaltyOvr = @(campaign, penaltyId = "") {
  ovr = commonOvr.__merge({ children = penaltyTimerIcon(campaign, penaltyId) })
  hotkeys = hotkeyX
}
let toBattleText = utf8ToUpper(loc("mainmenu/toBattle/short"))
let toBattleContent = {
  pos = const [0, hdpx(10)]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_TEXT
      text = toBattleText
    }.__update(fontSmallShaded)
    mkMRankRange
  ]
}

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
  if (isNextBattleNewbieOffline.get() == null)
    return false
  if (null != getCampaignPkgsForNewbieSingle(curCampaign.get()).findvalue(@(a) !(hasAddons.get()?[a] ?? true)))
    return true
  let units = {}
  let addons = {}
  if (curUnit.get() != null)
    units[curUnit.get().name] <- true
  if (newbieOfflineMissions.get())
    foreach (missionName in newbieOfflineMissions.get()) {
      let { misUnits, misAddons } = getMissionUnitsAndAddons(missionName)
      units.__update(misUnits)
      addons.__update(misAddons)
    }
  else if (newbieLocalMP.get() != null)
    foreach (missionName, _ in newbieLocalMP.get()?.mission_decl.missions_list ?? {}) {
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
    children = mkCustomButton(
      toBattleContent,
      toBattleFunc,
      mergeStyles(mergeStyles(battleBtnPenaltyOvr(curCampaign.get()), ovr),
        isNeedAddonsForRandomBattle.get() ? buttonStyles.COMMON : buttonStyles.BATTLE))
  }.__update(ovr)
}

function mkRentBattlesButton(rentalCd, campaign, toBattleFunc) {
  let ovr = mkDownloadingOvr("randomBattle", isNeedAddonsForRandomBattle)
  let leftTime = Computed(@()
    max(0, (rentals.get()?[campaign].entryTime ?? 0) + rentalCd - serverTime.get()))
  let defToBattleText = utf8ToUpper(loc("mainmenu/toBattle/try"))
  return function() {
    let hasCooldown = leftTime.get() > 0
    let leftTimeText = secondsToHoursLoc(leftTime.get())
    return {
      watch = [isNeedAddonsForRandomBattle, leftTime]
      children = (isNeedAddonsForRandomBattle.get() || hasCooldown ? textButtonCommon : textButtonPrimary)(
        !hasCooldown ? defToBattleText
          : "\n".join([defToBattleText, $"{loc("icon/timer")}{leftTimeText}"])
        @() hasCooldown ? openMsgBox({ text = loc("mainmenu/toBattle/restrict/cooldown", { time = leftTimeText }) }) : toBattleFunc(),
        mergeStyles(hasCooldown ? battleBtnOvr : battleBtnPenaltyOvr(campaign), ovr))
    }.__update(ovr)
  }
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
          mergeStyles(isGtFfa.get()
              ? battleBtnOvr
              : battleBtnPenaltyOvr(battleMode.get()?.campaign, battleMode.get()?.mission_decl.penaltyId ?? ""),
            ovr))
  }
}

function toRandomBattle() {
  if (curUnit.get() != null)
    showNoPremMessageIfNeed(@() offerMissingUnitItemsMessage(curUnits.get(), queueCurRandomBattleMode))
  else
    logerr($"Unable to start battle because no units (unit in hangar = {hangarUnit.get()?.name})")
}

const cbRandomBattleId = "onResetPenaltyToRandomBattle"
const cbReadyId = "onResetPenaltyReady"
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
      sendNewbieBqEvent("pressToBattleButton",
        { status = "offline_battle",
          params = ", ".join(newbieOfflineMissions.get() != null ? newbieOfflineMissions.get()
            : newbieLocalMP.get()?.mission_decl.missions_list.keys() ?? [])
        })
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
    needFirstBattleTutor, isNextBattleNewbieOffline, shouldStartNewbieSingleOnline, isGameModesReceived
  ]
  children = needReadyCheckButton.get() && isReadyCheckSuspended.get() ? readyCheckButtonInactive
    : needReadyCheckButton.get() ? readyCheckButton
    : isSquadLeader.get() ? toSquadBattleButton_RandomBattles
    : isInSquad.get() && !isReady.get() ? readyButtonRandomBattles
    : isInSquad.get() && isReady.get() ? notReadyButton
    : isOfflineMenu ? startOfflineBattleButton
    : needFirstBattleTutor.get() ? startTutorButton
    : isNextBattleNewbieOffline.get() && !shouldStartNewbieSingleOnline.get() ? startOfflineMissionButton
    : isGameModesReceived.get() ? toBattleButton_RandomBattles
    : textButtonCommon(toBattleText, @() openMsgBox({ text = loc("msg/noGameModes") }), { hotkeys = hotkeyX })
}

function mkToBattleButtonWithSquadManagement(toBattleFunc, bModeOrId = null, ovr = {}) {
  let battleMode = bModeOrId == null ? randomBattleMode
    : bModeOrId instanceof Watched ? bModeOrId
    : bModeOrId instanceof Table ? Watched(bModeOrId)
    : Computed(@() allGameModes.get()?[bModeOrId])
  let toBattleButton = mkToBattleButtonNoAddons(toBattleFunc, battleMode, ovr)
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
  queueCurRandomBattleMode
  randomBattleButtonDownloading
  mkRentBattlesButton
  mkToBattleButtonNoAddons
  toBattleButtonForRandomBattles
  mkToBattleButtonWithSquadManagement
}
