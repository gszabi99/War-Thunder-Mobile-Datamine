from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { register_command } = require("console")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { curCampaign, sharedStatsByCampaign } = require("%appGlobals/pServer/campaign.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { secondsToTimeSimpleString, millisecondsToSecondsInt } = require("%sqstd/time.nut")
let { textButtonCommon } = require("%rGui/components/textButton.nut")
let { defButtonHeight, defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let { isInQueue, curQueueState, curQueue, queueInfo, QS_LEAVING, QS_ACTUALIZE, QS_ACTUALIZE_SQUAD
} = require("%appGlobals/queueState.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")
let { get_time_msec } = require("dagor.time")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { registerScene } = require("%rGui/navState.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { isInJoiningGame } = require("%appGlobals/sessionLobbyState.nut")
let helpShipParts = require("%rGui/loading/complexScreens/helpShipParts.nut")
let helpTankControls = require("%rGui/loading/complexScreens/helpTankControls.nut")
let helpTankCaptureZone = require("%rGui/loading/complexScreens/helpTankCaptureZone.nut")
let helpTankParts = require("%rGui/loading/complexScreens/helpTankParts.nut")
let helpAirAiming = require("%rGui/loading/complexScreens/helpAirAiming.nut")
let helpEventBattleRoyale = require("%rGui/loading/complexScreens/helpEventBattleRoyale.nut")
let helpEventChristmas = require("%rGui/loading/complexScreens/helpEventChristmas.nut")
let helpEventPirates = require("%rGui/loading/complexScreens/helpEventPirates.nut")
let helpEventHalloween = require("%rGui/loading/complexScreens/helpEventHalloween.nut")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { mkMRankRange, curUnitMRankRange } = require("%rGui/state/matchingRank.nut")
let { isInSquad, isSquadLeader } = require("%appGlobals/squadState.nut")
let { leaveSquad } = require("%rGui/squad/squadManager.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { addFpsLimit, removeFpsLimit } = require("%rGui/guiFpsLimit.nut")
let { allGameModes } = require("%appGlobals/gameModes/gameModes.nut")

let textColor = 0xFFF0F0F0
let timeToShowCancelJoining = 30
let spinnerSize = hdpxi(64)
let spinnerGap = hdpx(20)
let hintIconSize = hdpxi(50)
let hintIconTank = "hud_tank_binoculars.svg"
let hintIconShip = "hud_binoculars.svg"

let isDebugQueueWnd = mkWatched(persist, "isDebugQueueWnd", false)
register_command(@() isDebugQueueWnd.set(!isDebugQueueWnd.get()), "ui.debug.queueWnd")

let needShowQueueWindow = keepref(Computed(@() !isInBattle.get()
  && (isInQueue.get() || isInJoiningGame.get() || isDebugQueueWnd.get())))
let canCancelJoining = Watched(false)
isInJoiningGame.subscribe(@(_) canCancelJoining.set(false))

let lastQueueMode = mkWatched(persist, "lastQueueMode", "")
curQueue.subscribe(@(v) (v?.params.mode ?? "") == "" ? null : lastQueueMode.set(v.params.mode))

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

let isOnlyOverrideUnits = Computed(@() allGameModes.get().findvalue(@(mode) mode.name == curQueue.get()?.params.mode)?.only_override_units ?? false)

let textParams = {
  rendObj = ROBJ_TEXT
  fontFx = FFT_GLOW
  fontFxFactor = 64
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
    size = [spinnerSize, spinnerSize]
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
      text = curQueueState.get() == QS_ACTUALIZE ? loc("wait/actualizeProfile")
        : curQueueState.get() == QS_ACTUALIZE_SQUAD ? loc("wait/actualizeSquadMembersProfile")
        : loc("yn1/waiting_time")
      color = textColor
    }, fontMedium)
    curQueueState.get() != QS_ACTUALIZE && curQueueState.get() != QS_ACTUALIZE_SQUAD ? waitTime : null
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
let cancelQueueButton = @(isOnlyOverride) {
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
  ].insert(0, !isOnlyOverride ? mkMRankRange : null)
}

let allowCancelJoining = @() canCancelJoining.set(true)
let cancelJoiningButton = @() {
  watch = canCancelJoining
  key = canCancelJoining
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  onAttach = @() resetTimeout(timeToShowCancelJoining, allowCancelJoining)
  onDetach = @() clearTimer(allowCancelJoining)
  children = !canCancelJoining.get()
    ? null
    : {
        flow = FLOW_VERTICAL
        halign = ALIGN_RIGHT
        gap = hdpx(12)
        children = [
          mkMRankRange
          textButtonCommon(utf8ToUpper(loc("mainmenu/btnCancel")), @() eventbus_send("cancelJoiningSession", {}), cancelOvr)
        ]
      }
}

let mkText = @(text) {
  text
}.__update(textParams)

let hintIcon = @() {
  watch = missionCampaign
  size = [hintIconSize, hintIconSize]
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
  ships_new = @() helpShipParts
  tanks = tanksBg
  tanks_new = tanksBg
}

let mkBgImageByGameMode = {
  tank_event_ny_ctf_mode = @() helpEventChristmas
  event_1_april_pirates = @() helpEventPirates
  tank_event_battle_royale = @() helpEventBattleRoyale
  plane_event_halloween_po2_race = @() helpEventHalloween
}

let bgImage = @() {
  watch = [missionCampaign, lastQueueMode]
  size = flex()
  children = mkBgImageByGameMode?[lastQueueMode.get()]() ?? mkBgImagesByCampaign?[missionCampaign.get()]()
}

let key = {}
let queueWindow = @() {
  watch = [isInJoiningGame, isOnlyOverrideUnits, hasAimingHint]
  key
  function onAttach() {
    sendNewbieBqEvent("openQueueWindow")
    addFpsLimit(key)
  }
  onDetach = @() removeFpsLimit(key)
  size = flex()
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
            cancelQueueButton(isOnlyOverrideUnits.get())
          ]
    }
  ]
  animations = wndSwitchAnim
}

registerScene("queueWindow", queueWindow, null, needShowQueueWindow)
