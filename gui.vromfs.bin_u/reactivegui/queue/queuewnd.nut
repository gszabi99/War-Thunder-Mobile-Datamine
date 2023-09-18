from "%globalsDarg/darg_library.nut" import *
let { send } = require("eventbus")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
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
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { curUnit, allUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { mkGradRank } = require("%rGui/components/gradTexts.nut")
let { curUnitMRankRange } = require("%rGui/state/matchingRank.nut")
let { unitType } = require("%rGui/hudState.nut")
let { TANK } = require("%appGlobals/unitConst.nut")
let { isInSquad, isSquadLeader } = require("%appGlobals/squadState.nut")
let { leaveSquad } = require("%rGui/squad/squadManager.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { addFpsLimit, removeFpsLimit } = require("%rGui/guiFpsLimit.nut")

let textColor = 0xFFF0F0F0
let timeToShowCancelJoining = 30
let spinnerSize = hdpxi(64)
let spinnerGap = hdpx(20)
let hintIconSize = hdpxi(50)
let hintIconTank = "hud_tank_binoculars.svg"
let hintIconShip = "hud_binoculars.svg"

let needShowQueueWindow = keepref(Computed(@() !isInBattle.value
  && (isInQueue.value || isInJoiningGame.value)))
let canCancelJoining = Watched(false)
isInJoiningGame.subscribe(@(_) canCancelJoining(false))

let playersCountInQueue = Computed(function() {
  if (curQueue.value == null || queueInfo.value == null)
    return null
  let { rank = null } = allUnitsCfg.value?[curQueue.value?.unitName] ?? curUnit.value //why rank here instead of matching rank?
  if (rank == null)
    return null
  let rankStr = rank.tostring()
  local res = 0
  foreach (clusterStats in queueInfo.value)
    foreach (qStats in clusterStats)
      res += qStats?[rankStr] ?? 0
  return max(1, res) //never show zero, because im in queue
})

let textParams = {
  rendObj = ROBJ_TEXT
  fontFx = FFT_GLOW
  fontFxFactor = 64
  fontFxColor = Color(0, 0, 0)
  color = Color(205, 205, 205)
}.__update(fontSmall)

let playersCount = @() textParams.__merge({
  watch = playersCountInQueue
  text = playersCountInQueue.value == null ? ""
    : $"{loc("multiplayer/playersInQueue")}{loc("ui/colon")}{playersCountInQueue.value}"
})

let waitCircle = {
  size = [SIZE_TO_CONTENT, flex()]
  valign = ALIGN_CENTER
  children = {
    size = [spinnerSize, spinnerSize]
    rendObj = ROBJ_IMAGE
    image = Picture("!ui/gameuiskin#progress_bar_circle.svg")
    transform = {}
    animations = [{ prop = AnimProp.rotate, from = 0, to = 360, duration = 3, play = true, loop = true }]
  }
}

let function waitTime() {
  let now = get_time_msec()
  let msec = now - (curQueue.value?.activateTime ?? now)
  return textParams.__merge({
    watch = [serverTime, curQueue]
    color = textColor
    text = msec < 0 ? "" : secondsToTimeSimpleString(millisecondsToSecondsInt(msec))
  }, fontMedium)
}

let waitingBlock = @() {
  watch = curQueueState
  hplace = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = spinnerGap
  children = [
    textParams.__merge({
      text = curQueueState.value == QS_ACTUALIZE ? loc("wait/actualizeProfile")
        : curQueueState.value == QS_ACTUALIZE_SQUAD ? loc("wait/actualizeSquadMembersProfile")
        : loc("yn1/waiting_time")
      color = textColor
    }, fontMedium)
    curQueueState.value != QS_ACTUALIZE && curQueueState.value != QS_ACTUALIZE_SQUAD ? waitTime : null
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

let leaveQueueImpl = @() send("leaveQueue", {})
let cancelOvr = { hotkeys = [[btnBEscUp, loc("mainmenu/btnCancel")]] }

let function leaveQueue() {
  if (!isInSquad.value || isSquadLeader.value) {
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

let mkMRankRange = @() {
  watch = curUnitMRankRange
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(12)
  children = curUnitMRankRange.value == null ? null
    : [
        { rendObj = ROBJ_TEXT, text = loc("mainmenu/battleTiers") }.__update(fontSmall)
        mkGradRank(curUnitMRankRange.value.minMRank)
        { rendObj = ROBJ_TEXT, text = "-" }.__update(fontSmall)
        mkGradRank(curUnitMRankRange.value.maxMRank)
      ]
}
let isCancelInProgress = Computed(@() curQueueState.value == QS_LEAVING)
let cancelQueueButton = {
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  halign = ALIGN_RIGHT
  gap = hdpx(12)
  children = [
    mkMRankRange
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

let allowCancelJoining = @() canCancelJoining(true)
let cancelJoiningButton = @() {
  watch = canCancelJoining
  key = canCancelJoining
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  onAttach = @() resetTimeout(timeToShowCancelJoining, allowCancelJoining)
  onDetach = @() clearTimer(allowCancelJoining)
  children = !canCancelJoining.value
    ? null
    : {
        flow = FLOW_VERTICAL
        halign = ALIGN_RIGHT
        gap = hdpx(12)
        children = [
          mkMRankRange
          textButtonCommon(utf8ToUpper(loc("mainmenu/btnCancel")), @() send("cancelJoiningSession", {}), cancelOvr)
        ]
      }
}

let mkText = @(text) {
  text
}.__update(textParams)

let hintIcon = @() {
  watch = unitType
  size = [hintIconSize, hintIconSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#{unitType.value == TANK ? hintIconTank : hintIconShip}:{hintIconSize}:{hintIconSize}:P")
}

let aimingHint = {
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  children = [{
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children = mkTextRow(loc("hints/wtm_ship_mission_aiming"), mkText, { ["{button}"] = hintIcon }) //warning disable: -forgot-subst
    }
    textParams.__merge({
      size = [flex(), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      text = loc("hints/wtm_ship_mission_aiming_more_damage")
    })
  ]
}

let mkBgImagesByCampaign = {
  ships = @() helpShipParts
  tanks = @() helpTankControls
}

let bgImage = @() {
  watch = curCampaign
  size = flex()
  children = mkBgImagesByCampaign?[curCampaign.value]()
}

let key = {}
let queueWindow = @() {
  watch = isInJoiningGame
  key
  onAttach = function() {
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
      children = isInJoiningGame.value
        ? [
            aimingHint
            joiningHeader
            cancelJoiningButton
          ]
        : [
            aimingHint
            playersCount
            waitingBlock
            cancelQueueButton
          ]
    }
  ]
  animations = wndSwitchAnim
}

registerScene("queueWindow", queueWindow, null, needShowQueueWindow)
