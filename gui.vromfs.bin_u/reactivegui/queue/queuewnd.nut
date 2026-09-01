from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "dagor.time" import get_time_msec
from "eventbus" import eventbus_send
from "%sqstd/string.nut" import utf8ToUpper
from "%sqstd/time.nut" import secondsToTimeSimpleString, millisecondsToSecondsInt
import "%darg/helpers/mkTextRow.nut" as mkTextRow
from "%appGlobals/clientState/clientState.nut" import isInBattle
from "%appGlobals/gameModes/gameModes.nut" import allGameModes
from "%appGlobals/pServer/bqClient.nut" import sendNewbieBqEvent
from "%appGlobals/pServer/campaign.nut" import curCampaign, sharedStatsByCampaign
from "%appGlobals/queueState.nut" import isInQueue, curQueueState, curQueue, queueInfo, QS_LEAVING, QS_ACTUALIZE,
  QS_ACTUALIZE_SQUAD, QS_CHECK_HOSTS, QS_NOT_IN_QUEUE, QS_JOINING, QS_IN_QUEUE, QS_CHECK_PENALTY, QS_REQUEST_STATS
from "%appGlobals/sessionLobbyState.nut" import isInJoiningGame
from "%appGlobals/squadState.nut" import isInSquad, isSquadLeader
from "%appGlobals/timeoutExt.nut" import resetExtTimeout, clearExtTimer
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%rGui/components/buttonStyles.nut" import defButtonHeight, defButtonMinWidth
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/components/spinner.nut" import mkSpinnerHideBlock
from "%rGui/components/textButton.nut" import textButtonCommon
from "%rGui/controlsMenu/gpActBtn.nut" import btnBEscUp
from "%rGui/guiFpsLimit.nut" import addFpsLimit, removeFpsLimit
import "%rGui/loading/complexScreens/helpAirAiming.nut" as helpAirAiming
import "%rGui/loading/complexScreens/helpEventBattleRoyale.nut" as helpEventBattleRoyale
import "%rGui/loading/complexScreens/helpEventChristmas2.nut" as helpEventChristmas2
import "%rGui/loading/complexScreens/helpEventHalloween.nut" as helpEventHalloween
import "%rGui/loading/complexScreens/helpEventPirates.nut" as helpEventPirates
import "%rGui/loading/complexScreens/helpEventWalkers.nut" as helpEventWalkers
import "%rGui/loading/complexScreens/helpShipParts.nut" as helpShipParts
import "%rGui/loading/complexScreens/helpTankCaptureZone.nut" as helpTankCaptureZone
import "%rGui/loading/complexScreens/helpTankControls.nut" as helpTankControls
import "%rGui/loading/complexScreens/helpTankParts.nut" as helpTankParts
from "%rGui/navState.nut" import registerScene
from "%rGui/squad/squadManager.nut" import leaveSquad
from "%rGui/state/matchingRank.nut" import curUnitMRankRange
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


const textColor = 0xFFF0F0F0
const timeToShowCancelJoining = 30
const spinnerSize = hdpxi(64)
const spinnerGap = hdpx(20)
const hintIconSize = hdpxi(50)
const hintIconTank = "hud_tank_binoculars.svg"
const hintIconShip = "hud_binoculars.svg"

let queueStateLocId = {
  [QS_NOT_IN_QUEUE] = "matching/SERVER_ERROR_NOT_IN_QUEUE",
  [QS_REQUEST_STATS] = "wait/actualizeProfile",
  [QS_ACTUALIZE] = "wait/actualizeProfile",
  [QS_CHECK_PENALTY] = "wait/actualizeProfile",
  [QS_ACTUALIZE_SQUAD] = "wait/actualizeSquadMembersProfile",
  [QS_CHECK_HOSTS] = "wait/checkingServers",
  [QS_JOINING] = "wait/joiningQueue",
  [QS_IN_QUEUE] = "yn1/waiting_time",
  [QS_LEAVING] = "wait/queueLeave",
}

let isDebugQueueWnd = mkWatched(persist, "isDebugQueueWnd", false)
register_command(@() isDebugQueueWnd.set(!isDebugQueueWnd.get()), "ui.debug.queueWnd")

let needShowQueueWindow = keepref(Computed(@() !isInBattle.get()
  && (isInQueue.get() || isInJoiningGame.get() || isDebugQueueWnd.get())))
let canCancelJoining = Watched(false)
isInJoiningGame.subscribe(@(_) canCancelJoining.set(false))

let lastQueueMode = mkWatched(persist, "lastQueueMode", "")
curQueue.subscribe(function(v) {
  let { mode = null, game_modes_list = [] } = v?.params
  if (mode != null)
    lastQueueMode.set(mode)
  if (game_modes_list.len() > 0)
    lastQueueMode.set(allGameModes.get()?[game_modes_list[0]].name)
})

let campaignByMode = Computed(@() allGameModes.get().findvalue(@(gm) gm?.name == lastQueueMode.get())?.campaign)

let eventsWithoutAimingHint = ["event_1_april_pirates"]
let hasAimingHint = Computed(@() !eventsWithoutAimingHint.contains(lastQueueMode.get()))
let airEventPrefixes = [ "air_event", "event_plane", "plane_" ]
let missionCampaign = Computed(@() airEventPrefixes.findindex(@(v) lastQueueMode.get().startswith(v)) != null
  ? "air"
  : campaignByMode.get() ?? curCampaign.get())

let curQueueGMName = Computed(@() curQueue.get()?.params.mode)
let isQueueAnyRank = Computed(@() curQueueGMName.get() == null ? false
  : allGameModes.get().findvalue(@(m) m.name == curQueueGMName.get())?.balancerMode == "team_size")

let playersCountInQueue = Computed(function() {
  if (curQueue.get() == null || queueInfo.get() == null)
    return null
  local res = 1 

  if (isQueueAnyRank.get()) {
    foreach (clusterStats in queueInfo.get())
      foreach (qStats in clusterStats)
        res = max(res, qStats.reduce(@(r, v) r + v, 0))
    return res
  }

  let { minMRank, maxMRank } = curUnitMRankRange.get()
  let pairs = minMRank >= maxMRank ? [[minMRank.tostring()]]
    : array(maxMRank - minMRank).map(@(_, i) [(minMRank + i).tostring(), (minMRank + i + 1).tostring()])
  foreach (clusterStats in queueInfo.get())
    foreach (qStats in clusterStats)
      foreach (p in pairs)
        res = max(res, p.reduce(@(r, id) r + (qStats?[id] ?? 0), 0))
  return res
})

let textParams = {
  rendObj = ROBJ_TEXT
  fontFx = FFT_GLOW
  fontFxFactor = 32 
  fontFxColor = Color(0, 0, 0)
  color = Color(205, 205, 205)
}.__update(fontSmall)

let playersCount = @() textParams.__merge({
  watch = playersCountInQueue
  text = playersCountInQueue.get() == null ? ""
    : $"{loc("multiplayer/playersInQueue")}{loc("ui/colon")}{playersCountInQueue.get()}"
})

let waitCircle = {
  size = FLEX_V
  valign = ALIGN_CENTER
  children = {
    size = const [spinnerSize, spinnerSize]
    rendObj = ROBJ_IMAGE
    image = Picture("!ui/gameuiskin#progress_bar_circle.svg")
    transform = {}
    animations = [{ prop = AnimProp.rotate, from = 0, to = 360, duration = 3, play = true, loop = true }]
  }
}

function waitTime() {
  let now = get_time_msec()
  let msec = now - (curQueue.get()?.activateTime ?? now)
  return textParams.__merge({
    watch = [serverTime, curQueue]
    color = textColor
    text = msec < 0 ? "" : secondsToTimeSimpleString(millisecondsToSecondsInt(msec))
  }, fontMonoMedium)
}

let waitingBlock = @() {
  watch = curQueueState
  hplace = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = spinnerGap
  children = [
    textParams.__merge({
      text = loc(queueStateLocId?[curQueueState.get()] ?? "Error")
      color = textColor
    }, fontMedium)
    curQueueState.get() == QS_IN_QUEUE ? waitTime : null
    waitCircle
  ]
}

let joiningHeader = {
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = spinnerGap
  children = [
    textParams.__merge({
      text = loc("wait/sessionJoin")
      color = textColor
    }, fontMedium)
    waitCircle
  ]
}

let leaveQueueImpl = @() eventbus_send("leaveQueue", {})
let cancelOvr = { hotkeys = [[btnBEscUp, loc("mainmenu/btnCancel")]] }

function leaveQueue() {
  if (isDebugQueueWnd.get())
    return isDebugQueueWnd.set(false)
  if (!isInSquad.get() || isSquadLeader.get()) {
    leaveQueueImpl()
    return
  }

  openMsgBox({
    text = loc("squad/only_leader_can_cancel")
    buttons = [
      { text = loc("squadAction/leave"),
        function cb() {
          leaveSquad()
          leaveQueueImpl()
        }
      }
      { id = "cancel", styleId = "PRIMARY", isCancel = true }
    ]
  })
}

let isCancelInProgress = Computed(@() curQueueState.get() == QS_LEAVING)
let cancelQueueButton = {
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  halign = ALIGN_RIGHT
  gap = hdpx(12)
  children = [
    mkSpinnerHideBlock(isCancelInProgress,
      textButtonCommon(utf8ToUpper(loc("mainmenu/btnCancel")), leaveQueue, cancelOvr),
      {
        size = [SIZE_TO_CONTENT, defButtonHeight]
        minWidth = defButtonMinWidth
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
      }
    )
  ]
}

let allowCancelJoining = @() canCancelJoining.set(true)
let cancelJoiningButton = @() {
  watch = canCancelJoining
  key = canCancelJoining
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  onAttach = @() resetExtTimeout(timeToShowCancelJoining, allowCancelJoining)
  onDetach = @() clearExtTimer(allowCancelJoining)
  children = !canCancelJoining.get()
    ? null
    : {
        flow = FLOW_VERTICAL
        halign = ALIGN_RIGHT
        gap = hdpx(12)
        children = textButtonCommon(utf8ToUpper(loc("mainmenu/btnCancel")), @() eventbus_send("cancelJoiningSession", {}), cancelOvr)
      }
}

let mkText = @(text) {
  text
}.__update(textParams)

let hintIcon = @() {
  watch = missionCampaign
  size = const [hintIconSize, hintIconSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#{missionCampaign.get() == "tanks" ? hintIconTank : hintIconShip}:{hintIconSize}:{hintIconSize}:P")
}

let aimingHint = {
  size = FLEX_H
  halign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  children = [{
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children = mkTextRow(loc("hints/wtm_ship_mission_aiming"), mkText, { ["{button}"] = hintIcon }) 
    }
    @() textParams.__merge({
      watch = missionCampaign
      size = FLEX_H
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      text = loc(missionCampaign.get() == "air"
        ? "hints/wtm_air_mission_aiming_forestall"
        : "hints/wtm_ship_mission_aiming_more_damage")
    })
  ]
}

let tanksScreensOrder = [ helpTankControls, helpTankParts, helpTankControls, helpTankCaptureZone ]
let tanksBg = @() tanksScreensOrder[(sharedStatsByCampaign.get()?.battles ?? 0) % tanksScreensOrder.len()]()

let mkBgImagesByCampaign = {
  air   = @() helpAirAiming
  ships = @() helpShipParts
  tanks = tanksBg
}

let mkBgImageByGameMode = {
  tank_event_ny_ctf_mode = @() helpEventChristmas2
  event_1_april_pirates = @() helpEventPirates
  tank_event_battle_royale = @() helpEventBattleRoyale
  plane_event_halloween_po2_race = @() helpEventHalloween
  event_1_april_mechas = @() helpEventWalkers
}

let bgImage = @() {
  watch = [missionCampaign, lastQueueMode]
  size = FLEX
  children = mkBgImageByGameMode?[lastQueueMode.get()]() ?? mkBgImagesByCampaign?[missionCampaign.get()]()
}

let key = {}
let queueWindow = @() {
  watch = [isInJoiningGame, hasAimingHint]
  key
  function onAttach() {
    sendNewbieBqEvent("openQueueWindow")
    addFpsLimit(key)
  }
  onDetach = @() removeFpsLimit(key)
  size = FLEX
  children = [
    bgImage
    {
      size = saSize
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      children = isInJoiningGame.get()
        ? [
            hasAimingHint.get() ? aimingHint : null
            joiningHeader
            cancelJoiningButton
          ]
        : [
            hasAimingHint.get() ? aimingHint : null
            playersCount
            waitingBlock
            cancelQueueButton
          ]
    }
  ]
  animations = wndSwitchAnim
}

registerScene("queueWindow", queueWindow, null, needShowQueueWindow)
